//
//  ContentView.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Main SwiftUI view for the BrickView application.
//
//  The view defines the overall BrickView user interface structure,
//  including the application header, model controls, model count,
//  model grid, and shared context-menu state.
//
//  Model data loading, model collection state, selected folder state,
//  and security-scoped folder access are coordinated by
//  ModelBrowserCoordinator. ContentView is responsible for presenting
//  that state and coordinating UI-specific interactions.
//
//  The upper application controls use a Studio-inspired toolbar
//  background, while the model area uses the dedicated model-area
//  background color.
//

import SwiftUI

struct ContentView: View {

    private let folderPickerService = FolderPickerService()
    private let folderBookmarkService = FolderBookmarkService()
    private let modelSortingService = ModelSortingService()
    private let modelFilterService = ModelFilterService()

    private let gridSpacing: CGFloat = 20
    private let gridPadding: CGFloat = 16
    private let gridDensityDefaultsKey: String = "GridDensity"

    private let toolbarBackgroundColor: Color =
        Color(
            red: 42.0 / 255.0,
            green: 45.0 / 255.0,
            blue: 52.0 / 255.0
        )

    private let modelAreaBackgroundColor: Color =
        Color(
            red: 36.0 / 255.0,
            green: 37.0 / 255.0,
            blue: 46.0 / 255.0
        )

    @StateObject private var modelBrowserCoordinator =
        ModelBrowserCoordinator()

    @State private var sortOption: ModelSortOption = .modificationDate
    @State private var sortOrder: ModelSortOrder = .descending
    @State private var searchText: String = ""
    @State private var gridDensity: GridDensity = .medium
    @State private var contextMenuModelID: URL?

    private var appVersion: String {
        let shortVersion =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "0.0"

        let buildVersion =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "0"

        return "\(shortVersion).\(buildVersion)"
    }

    private var selectedFolderPath: String {
        guard let folder = modelBrowserCoordinator.selectedFolder else {
            return "No folder selected"
        }

        let homePath =
            FileManager.default.homeDirectoryForCurrentUser.path

        return folder.path.replacingOccurrences(
            of: homePath,
            with: "~"
        )
    }

    private var thumbnailSizeDefinition: ThumbnailSizeDefinition {
        switch gridDensity {
        case .small:
            return ThumbnailConfiguration.small

        case .medium:
            return ThumbnailConfiguration.medium

        case .large:
            return ThumbnailConfiguration.large
        }
    }

    private var filteredModels: [Model] {
        modelFilterService.filter(
            modelBrowserCoordinator.models,
            matching: searchText
        )
    }

    private var sortedModels: [Model] {
        modelSortingService.sort(
            filteredModels,
            by: sortOption,
            order: sortOrder
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text("BrickView")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("v\(appVersion)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Text(selectedFolderPath)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(
                        modelBrowserCoordinator.selectedFolder?.path
                            ?? ""
                    )

                Spacer()

                Button("Select folder") {
                    if let folder = folderPickerService.selectFolder() {
                        let didSelectFolder =
                            modelBrowserCoordinator.selectFolder(folder)

                        if didSelectFolder {
                            try? folderBookmarkService.saveBookmark(
                                for: folder
                            )
                        }
                    }
                }

                Button("Refresh") {
                    guard let selectedFolder =
                        modelBrowserCoordinator.selectedFolder else {
                        return
                    }

                    modelBrowserCoordinator.loadModels(
                        from: selectedFolder
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .frame(
                maxWidth: .infinity
            )
            .background(
                toolbarBackgroundColor
            )

            Divider()

            HStack {
                TextField(
                    "Search models...",
                    text: $searchText
                )
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)

                Spacer()

                Menu {
                    Section("Sort by") {
                        Button {
                            sortOption = .filename
                        } label: {
                            HStack {
                                Text("File name")

                                Spacer()

                                if sortOption == .filename {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Button {
                            sortOption = .creationDate
                        } label: {
                            HStack {
                                Text("Created date")

                                Spacer()

                                if sortOption == .creationDate {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Button {
                            sortOption = .modificationDate
                        } label: {
                            HStack {
                                Text("Modified date")

                                Spacer()

                                if sortOption == .modificationDate {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Section("Order") {
                        Button {
                            sortOrder = .ascending
                        } label: {
                            HStack {
                                Text("Ascending")

                                Spacer()

                                if sortOrder == .ascending {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Button {
                            sortOrder = .descending
                        } label: {
                            HStack {
                                Text("Descending")

                                Spacer()

                                if sortOrder == .descending {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOptionLabel)

                        Image(
                            systemName: sortOrder == .ascending
                                ? "arrow.up"
                                : "arrow.down"
                        )
                        .foregroundColor(.accentColor)

                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Color(nsColor: .controlBackgroundColor)
                )
                .cornerRadius(6)

                Picker(
                    "Grid density",
                    selection: $gridDensity
                ) {
                    Image(systemName: "square.grid.2x2")
                        .tag(GridDensity.small)

                    Image(systemName: "square.grid.3x3")
                        .tag(GridDensity.medium)

                    Image(systemName: "square.grid.4x3.fill")
                        .tag(GridDensity.large)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(
                maxWidth: .infinity
            )
            .background(
                toolbarBackgroundColor
            )
            .onChange(of: gridDensity) { newDensity in
                UserDefaults.standard.set(
                    newDensity.rawValue,
                    forKey: gridDensityDefaultsKey
                )
            }

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text("\(sortedModels.count) models")
                        .font(.headline)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                if let loadingError =
                    modelBrowserCoordinator.loadingError {
                    Text(loadingError)
                        .foregroundColor(.red)
                        .padding()
                }

                GeometryReader { geometry in
                    ScrollView {
                        LazyVGrid(
                            columns: gridColumns(
                                for: geometry.size.width
                            ),
                            alignment: .leading,
                            spacing: gridSpacing
                        ) {
                            ForEach(sortedModels) { model in
                                ModelCardView(
                                    model: model,
                                    sizeDefinition:
                                        thumbnailSizeDefinition,
                                    isContextMenuVisible:
                                        contextMenuModelID == model.id,
                                    onContextMenuRequested: {
                                        contextMenuModelID = model.id
                                    },
                                    onContextMenuDismissed: {
                                        if contextMenuModelID == model.id {
                                            contextMenuModelID = nil
                                        }
                                    }
                                )
                            }
                        }
                        .padding(gridPadding)
                    }
                    .onTapGesture {
                        contextMenuModelID = nil
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .background(
                modelAreaBackgroundColor
            )
        }
        .background(
            modelAreaBackgroundColor
        )
        .background {
            WindowConfigurator()
        }
        .task {
            if let savedDensityRawValue =
                UserDefaults.standard.string(
                    forKey: gridDensityDefaultsKey
                ),
                let savedDensity =
                    GridDensity(rawValue: savedDensityRawValue) {
                gridDensity = savedDensity
            }

            if let restoredFolder =
                folderBookmarkService.restoreFolder() {
                let didRestoreFolder =
                    modelBrowserCoordinator.selectFolder(
                        restoredFolder
                    )

                if !didRestoreFolder {
                    modelBrowserCoordinator.clearModels()
                }
            }
        }
    }

    private var sortOptionLabel: String {
        switch sortOption {
        case .filename:
            return "File name"

        case .creationDate:
            return "Created date"

        case .modificationDate:
            return "Modified date"
        }
    }

    private func gridColumns(
        for width: CGFloat
    ) -> [GridItem] {
        let itemWidth =
            thumbnailSizeDefinition.itemSize.width

        let availableWidth = max(
            0,
            width - (gridPadding * 2)
        )

        let columnCount = max(
            1,
            Int(
                floor(
                    (availableWidth + gridSpacing)
                        / (itemWidth + gridSpacing)
                )
            )
        )

        return Array(
            repeating: GridItem(
                .fixed(itemWidth),
                spacing: gridSpacing
            ),
            count: columnCount
        )
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }
}
