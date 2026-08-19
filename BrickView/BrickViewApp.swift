//
//  BrickViewApp.swift
//  BrickView
//
//  Created by Kim Pedersen on 15/08/2026.
//

//
//  Purpose:
//  Application entry point for BrickView.
//
//  The app creates the main macOS window and hosts ContentView.
//  Application-specific state and window configuration are handled
//  by the appropriate views and services rather than by the App type.
//

import SwiftUI

@main
struct BrickViewApp: App {

    var body: some Scene {

        WindowGroup {

            ContentView()

        }
    }
}
