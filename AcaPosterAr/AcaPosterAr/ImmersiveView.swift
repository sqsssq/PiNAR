//
//  ImmersiveView.swift
//  PosterAR
//
//  Created by Brantqshi on 2025/4/23.
//

import SwiftUI
import RealityKit
import RealityKitContent
import PDFKit
import AVKit

struct ImmersiveView: View {
    @State var posterEntity: Entity = {
        let wallAnchor = AnchorEntity(.plane(.vertical, classification: .wall, minimumBounds: SIMD2<Float>(1, 1)));
        let planeMesh = MeshResource.generatePlane(width: 1.8, depth: 1, cornerRadius: 0);
//        let material = SimpleMaterial(color: .red, isMetallic: false);
        let material = ImmersiveView.loadImageMaterial(imageUrl: "poster")
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material]);
        planeEntity.name = "canvas";
        wallAnchor.addChild(planeEntity);
        return wallAnchor;
    }()
    
    @State private var showPDF = false
    @State private var showVideo = false
    @State private var pdfEntity: Entity?
    @State private var videoEntity: Entity?
    @State private var highlightEntities: [Entity] = []

    @State private var backUrl = "http://10.4.128.60:5025/highlight";
    
    var body: some View {
        RealityView { content in
//            ImmersiveView.drawPart(entity: posterEntity)
            posterEntity.addChild(addKeywords(keywords: ["Human Computer Interaction", "Data Visualization"], startPosition: SIMD3<Float>(-0.9, 0.01, -0.55)))
            
            print("111")
            
            // 获取高亮区域数据
            fetchHighlights()
            
            // 创建按钮并添加到海报右侧
//            let buttons = createButtons()
//            buttons.position = SIMD3<Float>(1.1, 0, -0.3) // 在海报右侧1米处
//            posterEntity.addChild(buttons)
            
            content.add(posterEntity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                VStack(spacing: 12) {
                    Button {
                        showPDF.toggle()
                    } label: {
                        Text(showPDF ? "关闭PDF" : "显示PDF")
                    }
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                    
                    Button {
                        showVideo.toggle()
                    } label: {
                        Text(showVideo ? "关闭视频" : "播放视频")
                    }
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                    
                    Button {
                        // 按钮3的功能
                    } label: {
                        Text("按钮3")
                    }
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                    
                    Button {
                        // 按钮4的功能
                    } label: {
                        Text("按钮4")
                    }
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: showPDF) { _, newValue in
            if newValue {
                loadPDF()
            } else {
                pdfEntity?.removeFromParent()
            }
        }
        .onChange(of: showVideo) { _, newValue in
            if newValue {
                loadVideo()
            } else {
                videoEntity?.removeFromParent()
            }
        }
    }
    
    private func createButtons() -> Entity {
        let parent = Entity()
        
        // 创建按钮背景板
        let backgroundMesh = MeshResource.generatePlane(width: 0.4, height: 0.4, cornerRadius: 0.05)
        let backgroundMaterial = SimpleMaterial(color: .black.withAlphaComponent(0.7), isMetallic: false)
        let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [backgroundMaterial])
        backgroundEntity.position = SIMD3<Float>(0, 0, -0.01) // 稍微靠后一点
//        parent.addChild(backgroundEntity)
        
        let buttonTitles = ["显示PDF", "播放视频", "按钮3", "按钮4"]
        let spacing: Float = 0.1
        var currentY: Float = 0.15 // 从上方开始
        
        for (index, title) in buttonTitles.enumerated() {
            let button = createButton(title: title)
            button.position = SIMD3<Float>(0, currentY, 0)
            button.name = "button_\(index)"
            parent.addChild(button)
            currentY -= spacing + 0.05 // 按钮高度加上间距
        }
        
        parent.position = SIMD3<Float>(1, 0, 0)
        
        
        parent.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        
        return parent
    }
    
    private func createButton(title: String) -> Entity {
        let button = Entity()
        
        // 创建按钮背景
        let bgMesh = MeshResource.generatePlane(width: 0.3, height: 0.05, cornerRadius: 0.01)
        let bgMaterial = SimpleMaterial(color: .blue.withAlphaComponent(0.8), isMetallic: false)
        let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])
        
        // 创建按钮文字
        let textMesh = MeshResource.generateText(
            title,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.02),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        let textMaterial = UnlitMaterial(color: .white)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // 设置文字位置
        let textBounds = textEntity.model?.mesh.bounds ?? .init()
        textEntity.position = SIMD3<Float>(-textBounds.extents.x / 2, -0.01, 0.001)
        
        bgEntity.addChild(textEntity)
        button.addChild(bgEntity)
        
        // 添加碰撞组件
        button.components.set(CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.3, 0.05, 0.01))]))
        button.components.set(InputTargetComponent())
        
        return button
    }
    
    static func rotateEntityAroundYAxis(entity: Entity, angle: Float) {
        var currentTransform = entity.transform;
        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        
        currentTransform.rotation = rotation * currentTransform.rotation;
        entity.transform = currentTransform;
    }
    
    static func loadImageMaterial(imageUrl: String) -> SimpleMaterial {
        do {
            let texture = try TextureResource.load(named: imageUrl);
            var material = SimpleMaterial();
            let color = SimpleMaterial.BaseColor(texture: MaterialParameters.Texture(texture));
            material.color = color;
            return material;
        } catch {
            fatalError(String(describing: error));
        }
    }
    
    
    static func drawPart(entity: Entity) {
        entity.addChild(createCustomRectangle(width: 0.5, height: 0.87, borderColor: .blue, fillColor: .red, opacity: 0.3, x: -0.9, y: -0.375))
        entity.addChild(createCustomRectangle(width: 0.56, height: 0.87, borderColor: .blue, fillColor: .blue, opacity: 0.3, x: 0.34, y: -0.375))
        entity.addChild(createCustomRectangle(width: 0.74, height: 0.87, borderColor: .blue, fillColor: .green, opacity: 0.3, x: -0.4, y: -0.375))
    }
    
    private func loadPDF() {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "pdf"),
              let document = PDFDocument(url: url) else { return }
        
        let pdfEntity = Entity()
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let mesh = MeshResource.generatePlane(width: 1, height: 1)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // 将PDF第一页渲染为图片
        if let page = document.page(at: 0) {
            let pageSize = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageSize.size)
            let image = renderer.image { context in
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            if let texture = try? TextureResource.generate(from: image.cgImage!, options: .init(semantic: .color)) {
                var material = SimpleMaterial()
                material.color = .init(tint: .white, texture: .init(texture))
                modelEntity.model?.materials = [material]
            }
        }
        
        pdfEntity.addChild(modelEntity)
        
        // 获取用户当前的位置和方向
        let userPosition = SIMD3<Float>(0, 0, 0)
        let userDirection = SIMD3<Float>(0, 0, -1)
        
        // 在用户前方2米处显示PDF
        let pdfPosition = userPosition + userDirection * 2.0
        pdfEntity.position = pdfPosition
        
        // 让PDF面向用户
        pdfEntity.look(at: userPosition, from: pdfPosition, relativeTo: nil)
        
        self.pdfEntity = pdfEntity
        posterEntity.addChild(pdfEntity)
    }
    
    private func loadVideo() {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else { return }
        let player = AVPlayer(url: url)
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        let videoEntity = Entity()
        let mesh = MeshResource.generatePlane(width: 1.6, height: 0.9)
        let modelEntity = ModelEntity(mesh: mesh, materials: [videoMaterial])
        
        videoEntity.addChild(modelEntity)
        
        // 获取用户当前的位置和方向
        let userPosition = SIMD3<Float>(0, 0, 0)
        let userDirection = SIMD3<Float>(0, 0, -1)
        
        // 在用户前方2米处显示视频
        let videoPosition = userPosition + userDirection * 2.0
        videoEntity.position = videoPosition
        
        // 让视频面向用户
        videoEntity.look(at: userPosition, from: videoPosition, relativeTo: nil)
        
        self.videoEntity = videoEntity
        posterEntity.addChild(videoEntity)
        
        player.play()
    }
    
    private func handleButtonTap(entity: Entity) {
        guard let name = entity.name as? String else { return }
        
        if name.hasPrefix("button_") {
            let index = name.replacingOccurrences(of: "button_", with: "")
            switch index {
            case "0":
                showPDF.toggle()
            case "1":
                showVideo.toggle()
            default:
                break
            }
        }
    }
    
    private func addHighlights(boxes: [[String: Float]]) {
        // 清除现有的高亮区域
        highlightEntities.forEach { $0.removeFromParent() }
        highlightEntities.removeAll()
        
        // 添加新的高亮区域
        for box in boxes {
            print(box)
            let x = box["x"] ?? 0
            let y = box["y"] ?? 0
            let width = box["width"] ?? 0.1
            let height = box["height"] ?? 0.1
            
            let highlightEntity = createCustomRectangle(
                width: width,
                height: height,
                borderColor: .yellow,
                fillColor: .yellow,
                opacity: 0.3,
                x: x - width/2, // 调整x坐标使中心点对齐
                y: y - height/2 // 调整y坐标使中心点对齐
            )
            
            highlightEntities.append(highlightEntity)
            posterEntity.addChild(highlightEntity)
        }
    }
    
    private func fetchHighlights() {
        guard let url = URL(string: backUrl) else {
            print("❌ Invalid URL: \(backUrl)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📡 Sending request to: \(backUrl)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received")
                return
            }
            
            print("📦 Received data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("✅ Successfully parsed JSON array with \(jsonArray.count) items")
                    
                    let boxes = jsonArray.compactMap { dict -> [String: Float]? in
                        guard let x = dict["x"] as? Double,
                              let y = dict["y"] as? Double,
                              let width = dict["width"] as? Double,
                              let height = dict["height"] as? Double else {
                            print("❌ Failed to parse box data: \(dict)")
                            return nil
                        }
                        return [
                            "x": Float(x),
                            "y": Float(y),
                            "width": Float(width),
                            "height": Float(height)
                        ]
                    }
                    
                    print("📊 Converted boxes: \(boxes)")
                    
                    DispatchQueue.main.async {
                        self.addHighlights(boxes: boxes)
                    }
                } else {
                    print("❌ Failed to parse JSON as array of dictionaries")
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
            }
        }.resume()
    }
}

func addKeywords(
    keywords: [String],
    startPosition: SIMD3<Float> = SIMD3<Float>(0, 0.001, 0),
    backgroundColor: UIColor = .systemBlue,
    textColor: UIColor = .white
) -> Entity {
    let parent = Entity();
    
    let spacing: Float = 0.03 // 每个词之间的间距
    var currentX: Float = 0
    for keyword in keywords {
        let keywordLength = Float(keyword.count)
//        let bgWidth = max(0.1, keywordLength * 0.05)
        let bgWidth = keywordLength * 0.035
//        let bgWidth = Float(0.5)
//        print(bgWidth)
        let bgHeight: Float = 0.07

        let bgMesh = MeshResource.generatePlane(width: bgWidth, height: bgHeight, cornerRadius: 0.01)
        let bgMaterial = SimpleMaterial(color: backgroundColor.withAlphaComponent(CGFloat(0.8)), isMetallic: false)
        let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])

        // 2. 正确生成文字 mesh
        let textMesh = MeshResource.generateText(
            keyword,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.05),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        

        let textMaterial = UnlitMaterial(color: textColor)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
//        textEntity.position = SIMD3<Float>(0, 0, 0.001) // 放在背景前面一点
        
        // 获取文字 bounding box 以进行居中
        let textBounds = textEntity.model?.mesh.bounds ?? .init()
        let textSize = textBounds.extents
        
        // 将文字移到背景中间（注意：原点在矩形中心）
        textEntity.position = SIMD3<Float>(
            x: -textSize.x / 2,
            y: (-textSize.y / 2 - 0.01),
            z: 0.001  // 稍微靠前以避免 z-fighting
        )

        // 3. 加入到背景中
        bgEntity.addChild(textEntity)

        // 4. 设置位置和绕 X 轴旋转
        bgEntity.position = startPosition + SIMD3<Float>(currentX + bgWidth / 2, 0, 0)
        bgEntity.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        currentX += bgWidth + spacing

        
        parent.addChild(bgEntity)
    }
    
    return parent;
}

func createCustomRectangle(
    width: Float = 0.2,
    height: Float = 0.1,
    borderColor: UIColor,
    fillColor: UIColor,
    opacity: Float,
    x: Float,
    y: Float
) -> Entity {
    let parent = Entity()
    
    // 但其实是绕 **X 轴** 旋转 -90°，从"地上"立起来！
    parent.position = [x + width / 2, 0, y + height / 2]
    parent.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]) // 沿 X 轴转 -90°

    // 填充部分
    let fillMaterial = SimpleMaterial(color: fillColor.withAlphaComponent(CGFloat(opacity)), isMetallic: false)
    let fillMesh = MeshResource.generatePlane(width: width, height: height)
    let fillEntity = ModelEntity(mesh: fillMesh, materials: [fillMaterial])
    fillEntity.position.z = 0.001;
    parent.addChild(fillEntity)

    // 边框部分
    let lineThickness: Float = 0.002
    let borderMaterial = SimpleMaterial(color: borderColor.withAlphaComponent(CGFloat(opacity)), isMetallic: false)
    
    func borderBox(w: Float, h: Float, x: Float, y: Float) -> ModelEntity {
        let box = MeshResource.generateBox(size: [w, h, lineThickness])
        let entity = ModelEntity(mesh: box, materials: [borderMaterial])
        entity.position = [x, y, 0]
        return entity
    }

    // 四边框
//    parent.addChild(borderBox(w: width, h: lineThickness, x: 0, y: height / 2))
//    parent.addChild(borderBox(w: width, h: lineThickness, x: 0, y: -height / 2))
//    parent.addChild(borderBox(w: lineThickness, h: height, x: -width / 2, y: 0))
//    parent.addChild(borderBox(w: lineThickness, h: height, x: width / 2, y: 0))

    return parent
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
