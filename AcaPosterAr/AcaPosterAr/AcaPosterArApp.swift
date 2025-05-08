//
//  AcaPosterArApp.swift
//  AcaPosterAr
//
//  Created by Qing Shi on 2025/5/8.
//

import SwiftUI

@main
struct AcaPosterArApp: App {

    @State private var viewModel = ViewModel()

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
