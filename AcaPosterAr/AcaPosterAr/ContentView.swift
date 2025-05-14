//
//  ContentView.swift
//  PosterAR
//
//  Created by Brantqshi on 2025/4/23.
//

import SwiftUI
import RealityKit
import RealityKitContent
import PDFKit
import AVFoundation

struct ContentView: View {

    @State private var enlarge = false
    @State private var showPDF = true
    @State private var showVideo = false
    @State private var pdfEntity: Entity?
    @State private var videoEntity: Entity?
    @State private var currentPage = 0
    @State private var pdfDocument: PDFDocument?
    @State private var isPDFMoving = false
    @State private var pdfPosition = SIMD3<Float>(0, 1.5, -2)
    
    @Environment(AppModel.self) private var appModel
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        RealityView { content in

            // 创建PDF实体并添加到content中
            let pdfEntity = Entity()
            let material = SimpleMaterial(color: .white, isMetallic: false) // 使用简单的蓝色材质
            let mesh = MeshResource.generatePlane(width: 0.21, height: 0.297)
                    
            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            
            pdfEntity.addChild(modelEntity)
            pdfEntity.position = SIMD3<Float>(0, -0.3, -0.2)
            
            pdfEntity.isEnabled = true // 设置为可见
            
        //    // 添加拖动手势
        //    modelEntity.components.set(InputTargetComponent())
        //    modelEntity.components.set(CollisionComponent(shapes: [.generateBox(width: 1, height: 1, depth: 0.01)]))
        //
            self.pdfEntity = pdfEntity
            content.add(pdfEntity)
            
        //     注释掉PDF加载
//            Task {
//                await loadPDF()
//            }
        } update: { content in
            // 更新PDF实体的可见性
            if let pdfEntity = pdfEntity {
                pdfEntity.isEnabled = showPDF
            }
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
            enlarge.toggle()
        })
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                HStack(spacing: 12) {
                    Button {
                        showPDF.toggle()
                    } label: {
                        Text(showPDF ? "关闭PDF" : "显示PDF")
                            .frame(width: 100)
                    }
                    .buttonStyle(.bordered)
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                    
                    if showPDF {
                        Button {
                            if let document = pdfDocument, currentPage > 0 {
                                currentPage -= 1
                                Task {
                                    await updatePDFPage()
                                }
                            }
                        } label: {
                            Text("上一页")
                                .frame(width: 100)
                        }
                        .buttonStyle(.bordered)
                        .animation(.none, value: 0)
                        .fontWeight(.semibold)
                        
                        Button {
                            if let document = pdfDocument, currentPage < document.pageCount - 1 {
                                currentPage += 1
                                Task {
                                    await updatePDFPage()
                                }
                            }
                        } label: {
                            Text("下一页")
                                .frame(width: 100)
                        }
                        .buttonStyle(.bordered)
                        .animation(.none, value: 0)
                        .fontWeight(.semibold)
                    }
                    
                    Button {
                        showVideo.toggle()
                        if showVideo {
                            Task {
                                await loadVideo()
                            }
                        } else {
                            videoEntity?.removeFromParent()
                        }
                    } label: {
                        Text(showVideo ? "关闭视频" : "播放视频")
                            .frame(width: 100)
                    }
                    .buttonStyle(.bordered)
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                    
                    Button {
                        // 按钮3的功能
                    } label: {
                        Text("按钮3")
                            .frame(width: 100)
                    }
                    .buttonStyle(.bordered)
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                    
                    Button {
                        // 按钮4的功能
                    } label: {
                        Text("按钮4")
                            .frame(width: 100)
                    }
                    .buttonStyle(.bordered)
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
        .onAppear(perform: {
            Task {
                await openImmersiveSpace(id: appModel.immersiveSpaceID)
            }
        })
    }
    
    private func loadPDF() async {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "pdf"),
              let document = PDFDocument(url: url) else { return }
        
        pdfDocument = document
        currentPage = 0
        await updatePDFPage()
    }
    
    private func updatePDFPage() async {
        guard let document = pdfDocument,
              let page = document.page(at: currentPage),
              let pdfEntity = pdfEntity,
              let modelEntity = pdfEntity.children.first as? ModelEntity else { return }
        
        // 渲染当前页面
        let pageSize = page.bounds(for: .mediaBox)
//        let renderer = UIGraphicsImageRenderer(size: pageSize.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        let renderer = UIGraphicsImageRenderer(size: pageSize.size, format: format)
//        let image = renderer.image { context in
////            page.draw(with: .mediaBox, to: context.cgContext)
//            UIColor.white.setFill()
//            context.fill(CGRect(origin: .zero, size: pageSize.size))
//            page.draw(with: .mediaBox, to: context.cgContext)
//        }
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // 翻转坐标系
            cgContext.translateBy(x: 0, y: pageSize.height)
            cgContext.scaleBy(x: 1, y: -1)

            // 白色背景
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: pageSize.size))

            // 绘制 PDF 页面
            page.draw(with: .mediaBox, to: cgContext)
        }

        
        if let texture = try? await TextureResource(image: image.cgImage!, options: .init(semantic: .color)) {
            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            modelEntity.model?.materials = [material]
        }
    }
    
    private func loadVideo() async {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else { return }
        let player = AVPlayer(url: url)
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        let videoEntity = Entity()
        let mesh = MeshResource.generatePlane(width: 1.6, height: 0.9)
        let modelEntity = ModelEntity(mesh: mesh, materials: [videoMaterial])
        
        videoEntity.addChild(modelEntity)
        videoEntity.position = SIMD3<Float>(0, 1.5, -2)
        self.videoEntity = videoEntity
        // 添加到场景中
        if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
            scene.addChild(videoEntity)
        }
        
        player.play()
    }
}

struct Balls: View {
    @State private var scale = false;
    var body: some View {
        RealityView { content in
            
            for _ in 1...5 {
                let model = ModelEntity(
                    mesh: .generateSphere(radius: 0.025),
                    materials: [SimpleMaterial(color: .red, isMetallic: true)]
                    )
                let x = Float.random(in: -0.2...0.2);
                let y = Float.random(in: -0.2...0.2);
                let z = Float.random(in: -0.2...0.2);
                model.position = SIMD3(x, y, z);
                model.components.set(InputTargetComponent());
                model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.025)]))
                content.add(model)
//                anchor.addChild(model)
            }
//            content.add(anchor)
        }
        update: { content in
            content.entities.forEach{ entity in
                entity.transform.scale = scale ? SIMD3<Float>(2, 2, 2) : SIMD3<Float>(1, 1, 1)
            }
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded{
            _ in scale.toggle()
        })
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
//    Balls()
//        .environment(AppModel())
}
