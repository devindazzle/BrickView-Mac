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
//  and model grid.
//
//  ContentView is responsible for composing the UI and coordinating
//  its visual layout. Individual UI components, model data handling,
//  file loading, thumbnail generation, and other application services
//  should be kept in dedicated components or services.
//

import SwiftUI

struct ContentView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 360, maximum: 360), spacing: 20)
    ]

    private let folderPickerService = FolderPickerService()
    private let folderBookmarkService = FolderBookmarkService()
    private let modelLoaderService = ModelLoaderService()
    private let modelSortingService = ModelSortingService()
    private let modelFilterService = ModelFilterService()

    @State private var selectedFolder: URL?
    @State private var models: [Model] = []
    @State private var loadingError: String?
    @State private var folderAccessSession: FolderAccessSession?
    @State private var sortOption: ModelSortOption = .modificationDate
    @State private var sortOrder: ModelSortOrder = .descending
    @State private var searchText: String = ""

    private var filteredModels: [Model] {
        modelFilterService.filter(
            models,
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
                Text("BrickView")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    selectedFolder.map { folder in
                        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
                        let abbreviatedPath = folder.path.replacingOccurrences(
                            of: homePath,
                            with: "~"
                        )

                        return "Folder: \(folder.lastPathComponent) · \(abbreviatedPath)"
                    } ?? "No folder selected"
                )
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(selectedFolder?.path ?? "")

                Spacer()

                Button("Select folder") {
                    if let folder = folderPickerService.selectFolder() {
                        guard let accessSession = FolderAccessSession(folder: folder) else {
                            selectedFolder = nil
                            models = []
                            loadingError = "The selected folder could not be accessed."
                            return
                        }

                        folderAccessSession = accessSession
                        selectedFolder = accessSession.folder

                        try? folderBookmarkService.saveBookmark(for: accessSession.folder)

                        loadModels(from: accessSession.folder)
                    }
                }

                Button("Refresh") {
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            HStack {
                TextField("Search models...", text: $searchText)
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
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)

                HStack(spacing: 0) {
                    Button {
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }

                    Button {
                    } label: {
                        Image(systemName: "square.grid.3x3")
                    }

                    Button {
                    } label: {
                        Image(systemName: "square.grid.4x3.fill")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text("\(sortedModels.count) models")
                        .font(.headline)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                if let loadingError {
                    Text(loadingError)
                        .foregroundColor(.red)
                        .padding()
                }

                ScrollView {
                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: 20
                    ) {
                        ForEach(sortedModels) { model in
                            ModelCardView(model: model)
                        }
                    }
                    .padding()
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .background {
            WindowConfigurator()
        }
        .task {
            if let restoredFolder = folderBookmarkService.restoreFolder(),
               let accessSession = FolderAccessSession(folder: restoredFolder) {
                folderAccessSession = accessSession
                selectedFolder = accessSession.folder
                loadModels(from: accessSession.folder)
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

    private func loadModels(from folder: URL) {
        Task {
            do {
                let loadedModels = try await modelLoaderService.loadModels(
                    from: folder
                )

                models = loadedModels
                loadingError = nil
            } catch {
                models = []
                loadingError = error.localizedDescription
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
