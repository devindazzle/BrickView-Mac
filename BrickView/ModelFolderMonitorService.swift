//
//  ModelFolderMonitorService.swift
//  BrickView
//
//  Created by Kim Pedersen on 17/08/2026.
//

//
//  Purpose:
//  Monitors a selected BrickView folder for file-system changes.
//
//  The service is UI-independent and reports relevant filesystem
//  changes through an AsyncStream. It does not load models, update
//  application state, or interact with SwiftUI.
//
//  FSEvents can report several flags for a single filesystem operation.
//  The service therefore exposes a stable application-level event model:
//
//      changed(URL)
//      removed(URL)
//
//  The coordinator is responsible for interpreting a changed path.
//  In particular, a changed .io path that no longer exists is treated
//  as a removal because some filesystem providers do not report
//  deletion through ItemRemoved.
//

import Foundation
import CoreServices

enum ModelFolderChange {
    case changed(URL)
    case removed(URL)
}

final class ModelFolderMonitorService {
    private var eventStream: FSEventStreamRef?
    private var continuation:
        AsyncStream<ModelFolderChange>.Continuation?

    /// Starts monitoring the supplied folder.
    ///
    /// The stream emits a change event for relevant file-system
    /// activity reported by FSEvents.
    func startMonitoring(
        folder: URL
    ) -> AsyncStream<ModelFolderChange> {
        stopMonitoring()

        let folderPath: String = folder.path

        let stream: AsyncStream<ModelFolderChange> =
            AsyncStream<ModelFolderChange>(
                bufferingPolicy: .bufferingNewest(100)
            ) { (
                continuation:
                    AsyncStream<ModelFolderChange>.Continuation
            ) in
                self.continuation = continuation

                let paths: NSArray = [folderPath]

                var context = FSEventStreamContext(
                    version: 0,
                    info: Unmanaged.passUnretained(self).toOpaque(),
                    retain: nil,
                    release: nil,
                    copyDescription: nil
                )

                let callback: FSEventStreamCallback = {
                    (
                        _,
                        clientCallBackInfo,
                        numEvents,
                        eventPaths,
                        eventFlags,
                        _
                    ) in
                    guard let clientCallBackInfo else {
                        return
                    }

                    let service: ModelFolderMonitorService =
                        Unmanaged<
                            ModelFolderMonitorService
                        >.fromOpaque(
                            clientCallBackInfo
                        ).takeUnretainedValue()

                    service.handleFileSystemEvents(
                        numEvents: numEvents,
                        eventPaths: eventPaths,
                        eventFlags: eventFlags
                    )
                }

                // FileEvents is required because BrickView needs
                // notifications for individual files rather than only
                // directory-level changes.
                let flags: FSEventStreamCreateFlags =
                    FSEventStreamCreateFlags(
                        kFSEventStreamCreateFlagFileEvents
                            | kFSEventStreamCreateFlagNoDefer
                    )

                guard let eventStream = FSEventStreamCreate(
                    nil,
                    callback,
                    &context,
                    paths,
                    FSEventStreamEventId(
                        kFSEventStreamEventIdSinceNow
                    ),
                    0.2,
                    flags
                ) else {
                    continuation.finish()
                    self.continuation = nil
                    return
                }

                self.eventStream = eventStream

                FSEventStreamSetDispatchQueue(
                    eventStream,
                    DispatchQueue.global(
                        qos: .utility
                    )
                )

                if !FSEventStreamStart(eventStream) {
                    FSEventStreamInvalidate(eventStream)
                    FSEventStreamRelease(eventStream)

                    self.eventStream = nil
                    continuation.finish()
                    self.continuation = nil
                }
            }

        return stream
    }

    /// Stops the current FSEvents stream.
    ///
    /// This operation is safe to call multiple times and is used when
    /// switching folders or cancelling folder monitoring.
    func stopMonitoring() {
        if let eventStream {
            FSEventStreamStop(eventStream)
            FSEventStreamInvalidate(eventStream)
            FSEventStreamRelease(eventStream)
            self.eventStream = nil
        }

        continuation?.finish()
        continuation = nil
    }

    /// Converts raw FSEvents callback data into stable application-level
    /// folder changes.
    ///
    /// Removal flags are preserved as explicit removed events.
    /// All other file events are reported as changed. The coordinator
    /// determines whether a changed path still exists and therefore
    /// represents a creation/modification or a deletion.
    private func handleFileSystemEvents(
        numEvents: Int,
        eventPaths: UnsafeRawPointer,
        eventFlags:
            UnsafePointer<FSEventStreamEventFlags>
    ) {
        let paths:
            UnsafePointer<UnsafePointer<CChar>?> =
            eventPaths.assumingMemoryBound(
                to: UnsafePointer<CChar>?.self
            )

        for index in 0..<numEvents {
            guard let pathPointer = paths[index] else {
                continue
            }

            let path: String = String(
                cString: pathPointer
            )

            let url: URL = URL(
                fileURLWithPath: path
            )

            let flags: FSEventStreamEventFlags =
                eventFlags[index]

            let isRemoved: Bool =
                flags & UInt32(
                    kFSEventStreamEventFlagItemRemoved
                ) != 0

            if isRemoved {
                continuation?.yield(
                    .removed(url)
                )
                continue
            }

            continuation?.yield(
                .changed(url)
            )
        }
    }

    deinit {
        stopMonitoring()
    }
}
