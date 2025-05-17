//
//  AcaPosterArApp.swift
//  AcaPosterAr
//
//  Created by Qing Shi on 2025/5/8.
//

import SwiftUI
//import AVFoundation

@main
struct AcaPosterArApp: App {

    @State private var viewModel = ViewModel()

    @State private var appModel = AppModel()

//    init() {
//        setupAudioSession()
//    }
//
//    private func setupAudioSession() {
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
//            try session.setActive(true)
//        } catch {
//            print("音频会话设置失败: \(error.localizedDescription)")
//        }
//    }    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace


    var body: some Scene {
        WindowGroup {
//            ContentView()
//                .environment(appModel)
            EmptyView()
                .environment(appModel)
                .onAppear {
                    Task {
                        await openImmersiveSpace(id: appModel.immersiveSpaceID)
                    }
                }
        }
        .windowStyle(.volumetric)
//        .windowStyle(.plain)

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
