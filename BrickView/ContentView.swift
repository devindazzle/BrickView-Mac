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
    private let modelLoaderService = ModelLoaderService()

    @State private var selectedFolder: URL?
    @State private var models: [Model] = []
    @State private var loadingError: String?

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
                        selectedFolder = folder

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

                Button("Refresh") {
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            HStack {
                TextField("Search models...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Spacer()

                HStack(spacing: 4) {
                    Text("Aa")
                        .fontWeight(.semibold)

                    Text("Modified date")

                    Text("↓")
                        .foregroundColor(.accentColor)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
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
                    Text("\(models.count) models")
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
                        ForEach(models) { model in
                            ModelCardView(
                                filename: model.filename,
                                partCount: model.partCount ?? 0
                            )
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
