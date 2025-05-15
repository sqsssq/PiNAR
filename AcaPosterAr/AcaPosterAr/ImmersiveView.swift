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
    
    
    @State private var showPDF = false
    @State private var showVideo = false
    @State private var showTextField = true
    @State private var highlightEntities: [Entity] = []
    @State private var currentPage = 0
    @State private var pdfDocument: PDFDocument?
    
    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var progress: Double = 0.0
    @State private var videoDuration: Double = 1.0 // 防止除以0
    
    @State private var isDraggingSlider = false
    
    @State private var miniButtonGroupData: [String: [String: Any]] = [
        "mini1": [
            "position": SIMD3<Float>(-0.35, 0, -0.27),
            "page": 5
        ],
        "mini2": [
            "position": SIMD3<Float>(-0.35, 0, 0.083),
            "page": 5
        ],
        "mini3": [
            "position": SIMD3<Float>(0.07, 0, -0.27),
            "page": 5
        ],
        "mini4": [
            "position": SIMD3<Float>(0.07, 0, 0.164),
            "page": 5
        ],
        "mini5": [
            "position": SIMD3<Float>(0.07, 0, 0.485),
            "page": 5
        ],
    ]
    
    @State var posterEntity: Entity = {
        let wallAnchor = AnchorEntity(.plane(.vertical, classification: .any, minimumBounds: SIMD2<Float>(0.5, 0.5)));
        let planeMesh = MeshResource.generatePlane(width: 0.841, depth: 1.189, cornerRadius: 0);
//        let material = SimpleMaterial(color: .red, isMetallic: false);
        let material = ImmersiveView.loadImageMaterial(imageUrl: "poster_2")
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material]);
        planeEntity.name = "canvas";
        wallAnchor.addChild(planeEntity);
        return wallAnchor;
    }()
    
    @State var paperEntity: Entity = {
        let headAnchor = AnchorEntity(.head);
        headAnchor.position = [0, -0.35, -0.5];
        return headAnchor;
    }()
    
    @State private var pdfEntity: ModelEntity = {
        let material = SimpleMaterial(color: .white, isMetallic: false) // 使用简单的蓝色材质
        let mesh = MeshResource.generatePlane(width: 0.21, height: 0.297)
                
        let tmppdfEntity = ModelEntity(mesh: mesh, materials: [material])
        tmppdfEntity.position = SIMD3<Float>(0, 0.18, -0.3)
        return tmppdfEntity;
    }()
    
    @State private var demoEntity: Entity = {
//        let headAnchor = Entity();
//        headAnchor.position = [1, 0, -0.2];
//        headAnchor.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let headAnchor = AnchorEntity(.head)
        headAnchor.position = [0, 0, -1]
        return headAnchor;
    }()
    

    @State private var backUrl = "http://10.4.128.60:5025/highlight";
    
    // 添加自定义按钮样式
    struct CustomButtonStyle: ButtonStyle {
        @State private var isHovered = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .background(
                    Group {
                        if configuration.isPressed {
                            Color.blue.opacity(0.8)
                        } else if isHovered {
                            Color.blue.opacity(0.4)
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.05 : 1))
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
                .animation(.easeInOut(duration: 0.1), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
    
    var body: some View {
        RealityView { content, attachments  in
//            ImmersiveView.drawPart(entity: posterEntity)
            posterEntity.addChild(addKeywords(keywords: ["Coulomb's Law", "Electrostatic interactions", "dielectric spheres", "like-charge attraction", "Electrostatics", "opposite-charge repulsion"], startPosition: SIMD3<Float>(-0.9, 0.01, -0.65)))
            
            print("111")
            
            // 获取高亮区域数据
            fetchHighlights()
            
            content.add(posterEntity)
            
                        
//            pdfEntity.isEnabled = showPDF;
            paperEntity.addChild(pdfEntity)
//            self.paperEntity = paperEntity
            
            content.add(paperEntity)
            
            Task {
                await loadPDF()
            }
            
            // MARK: add video
            
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") else {
                print("❌ 视频文件未找到")
                return
            }

            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)

            // 视频平面
            let planeMesh = MeshResource.generatePlane(width: 1, height: 0.6)
            let material = VideoMaterial(avPlayer: player)
            let videoEntity = ModelEntity(mesh: planeMesh, materials: [material])
            videoEntity.position = [0, 0, 0]
            
            demoEntity.addChild(videoEntity)

            // 控制面板（按钮、滑块）
            if let controls = attachments.entity(for: "VideoControls") {
                controls.position = [0, -0.32, 0.001]
                
                videoEntity.addChild(controls)
            }

            // 自动重播
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
                isPlaying = true
            }

//            // 获取视频时长
//            playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
//                DispatchQueue.main.async {
//                    self.videoDuration = playerItem.asset.duration.seconds
//                }
//            }
//
            Task {
                do {
                    self.videoDuration = try await playerItem.asset.load(.duration).seconds

                    // 异步加载时长
//                    let _ = try await playerItem.asset.load(.duration)
                    
//                    // 获取时长并更新UI
//                    DispatchQueue.main.async {
//                        self.videoDuration = playerItem.asset.load(.duration).seconds
//                    }
                } catch {
                    // 错误处理
                    print("Failed to load video duration: \(error)")
                }
            }

            

            // 播放进度监听
            player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
                if !self.isDraggingSlider {
                    self.progress = time.seconds / self.videoDuration
                }
            }
            
            posterEntity.addChild(demoEntity)
            
            
            // attachment: Button Group
            guard let buttonGroupEntity = attachments.entity(for: "buttonGroup") else { return };
            buttonGroupEntity.position = SIMD3<Float>(-0.54, 0, -0.42);
            buttonGroupEntity.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
            posterEntity.addChild(buttonGroupEntity)
            
            // attachment: Change Page Button
            guard let changePageButtonEntity = attachments.entity(for: "changePage") else { return };
            changePageButtonEntity.position = SIMD3<Float>(0, -0.19, 0);
            pdfEntity.addChild(changePageButtonEntity);
            
            // attachment: Mini Button Group
            print(miniButtonGroupData)
            for (key, value) in miniButtonGroupData {
//                let index = i;
                print(key)
                guard let miniButtonGroup = attachments.entity(for: key) else { return };
                
                guard var position = value["position"] as? SIMD3<Float> else { return }
                position.y = 0.001
                miniButtonGroup.position = position;
                
                miniButtonGroup.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
                posterEntity.addChild(miniButtonGroup)
            }
        } update: { _, _ in
            pdfEntity.isEnabled = showPDF;
            demoEntity.isEnabled = showVideo;
        } attachments: {
            ForEach(0..<miniButtonGroupData.count, id: \.self) { index in
                Attachment(id: "mini\(index + 1)") {
                    HStack(spacing: 10) {
                        Button {
                            guard let targetPage = miniButtonGroupData["mini\(index + 1)"]?["page"] as? Int else { return };
                            
                            if showPDF == false {
                                showPDF.toggle();
                            }
                            if let document = pdfDocument, targetPage > 0, targetPage <= document.pageCount - 1  {
                                currentPage = 5;
                                Task {
                                    await updatePDFPage();
                                }
                            }
                        } label: {
                            Image("pdf")
                                .resizable()
                                .frame(width: 24, height: 24)
    //                        Text("3")
                        }
                        Button {
                            guard let targetPage = miniButtonGroupData["mini\(index + 1)"]?["page"] as? Int else { return };
                            if let document = pdfDocument, targetPage > 0, targetPage <= document.pageCount - 1  {
                                currentPage = 5;
                                Task {
                                    await updatePDFPage();
                                }
                            }
                        } label: {
                            Image("video")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            
            Attachment(id: "changePage") {
                HStack(spacing: 20) {
                    Button {
                        if let document = pdfDocument, currentPage > 0 {
                            currentPage -= 1;
                            Task {
                                await updatePDFPage();
                            }
                        }
                    } label: {
                        Image("left")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    Button {
                        if showPDF == true {
                            showPDF.toggle();
                        }
                    } label: {
                        Image("close")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    Button {
                        if let document = pdfDocument, currentPage < document.pageCount - 1 {
                            currentPage += 1;
                            Task {
                                await updatePDFPage();
                            }
                        }
                    } label: {
                        Image("right")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                }
            }
            Attachment(id: "buttonGroup") {
                VStack(spacing: 20) {
                    Button {
                        showPDF.toggle()
                    } label: {
                        HStack {
                            Image("pdf")
                                .resizable()
                                .frame(width: 32, height: 32)
                            Text("PDF")
                                .font(.system(size: 32, weight: .semibold))
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
//                    .buttonStyle(CustomButtonStyle())
                    
                    Button {
                        showVideo.toggle()
                    } label: {
                        HStack {
                            Image("video")
                                .resizable()
                                .frame(width: 32, height: 32)
                            Text("Video")
                                .font(.system(size: 32, weight: .semibold))
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
//                    .buttonStyle(CustomButtonStyle())
                    
                    Button {
                        // 按钮3的功能
                    } label: {
                        Text("按钮3")
                            .font(.system(size: 32, weight: .semibold))
                            .frame(width: 90)
                    }
//                    .buttonStyle(CustomButtonStyle())
                    
                    Button {
                        // 按钮4的功能
                    } label: {
                        Text("按钮4")
                            .font(.system(size: 32, weight: .semibold))
                            .frame(width: 90)
                    }
//                    .buttonStyle(CustomButtonStyle())
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
            Attachment(id: "VideoControls") {
                HStack(spacing: 20) {
                    // 播放/暂停按钮
                    Button {
                        if isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                        isPlaying.toggle()
                    } label: {
                        if (isPlaying) {
                            Image("pause")
                                .resizable()
                                .frame(width: 32, height: 32)
                        } else {
                            Image("play")
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                    }
//                    .buttonStyle(CustomButtonStyle())

                    // 进度条
                    Slider(value: Binding(
                        get: { self.progress },
                        set: { newValue in
                            self.progress = newValue
                            let seekTime = CMTime(seconds: newValue * videoDuration, preferredTimescale: 600)
                            player.seek(to: seekTime)
                        }),
                        in: 0...1
                    )
                    .frame(width: 700)
                    
                    
                        // 播放/暂停按钮
                        Button {
                            if showVideo == true {
                                showVideo.toggle();
                            }
                        } label: {
                            Image("close")
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                }
                .frame(width: 900, height: 100)
            }
        }
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
    
    
    private func loadPDF() async {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "pdf"),
              let document = PDFDocument(url: url) else { return }
        
        pdfDocument = document
        currentPage = 0
        await updatePDFPage()
    }
    
    private func updatePDFPage() async {
        guard let document = pdfDocument,
              let page = document.page(at: currentPage) else { return }
        
        let pdfEntity = pdfEntity
        let pageSize = page.bounds(for: .mediaBox)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        let renderer = UIGraphicsImageRenderer(size: pageSize.size, format: format)
        
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
            pdfEntity.model?.materials = [material]
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
    let parent = Entity()
    
    let spacing: Float = 0.03 // 每个词之间的水平间距
    let verticalSpacing: Float = 0.1 // 行间距
    let wordsPerLine = 2 // 每行显示的关键词数量
    
    // 计算需要多少行
    let totalLines = (keywords.count + wordsPerLine - 1) / wordsPerLine
    
    for lineIndex in 0..<totalLines {
        let startIndex = lineIndex * wordsPerLine
        let endIndex = min(startIndex + wordsPerLine, keywords.count)
        let lineKeywords = Array(keywords[startIndex..<endIndex])
        
        // 计算当前行的总宽度
        var lineWidth: Float = 0
        for keyword in lineKeywords {
            let keywordLength = Float(keyword.count)
            let bgWidth = keywordLength * 0.03
            lineWidth += bgWidth
        }
        lineWidth += spacing * Float(lineKeywords.count - 1) // 添加词间距
        
        // 计算当前行的起始x坐标（居中）
        var currentX: Float = -lineWidth / 2
        
        // 计算当前行的y坐标
        let currentY = startPosition.y - Float(lineIndex) * verticalSpacing
        
        // 创建当前行的关键词
        for keyword in lineKeywords {
            let keywordLength = Float(keyword.count)
            let bgWidth = keywordLength * 0.03
            let bgHeight: Float = 0.07
            
            let bgMesh = MeshResource.generatePlane(width: bgWidth, height: bgHeight, cornerRadius: 0.01)
            let bgMaterial: SimpleMaterial
            if keyword == "Electrostatics" {
                bgMaterial = SimpleMaterial(color: .orange.withAlphaComponent(CGFloat(0.8)), isMetallic: false)
            } else {
                bgMaterial = SimpleMaterial(color: backgroundColor.withAlphaComponent(CGFloat(0.8)), isMetallic: false)
            }
            let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])
            
            // 创建文字
            let textMesh = MeshResource.generateText(
                keyword,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.04),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            
            let textMaterial = UnlitMaterial(color: textColor)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            
            // 获取文字边界以进行居中
            let textBounds = textEntity.model?.mesh.bounds ?? .init()
            let textSize = textBounds.extents
            
            // 将文字移到背景中间
            textEntity.position = SIMD3<Float>(
                x: -textSize.x / 2,
                y: (-textSize.y / 2 - 0.01),
                z: 0.001
            )
            
            bgEntity.addChild(textEntity)
            
            // 设置背景位置
            bgEntity.position = SIMD3<Float>(
                x: currentX + bgWidth / 2,
                y: 0,
                z: startPosition.z + currentY
            )
            bgEntity.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
            
            currentX += bgWidth + spacing
            
            parent.addChild(bgEntity)
        }
    }
    
    return parent
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
