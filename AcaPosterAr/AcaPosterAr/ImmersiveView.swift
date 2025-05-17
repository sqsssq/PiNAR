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
import Speech

struct ImmersiveView: View {
    
    // MARK: Parameter Group
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
    
    
    @State private var prompt: String = ""
    @State private var reply: String = ""
    @State private var isLoading = false
    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var chatHistory: [[String: String]] = [
        [
            "role": "user",
            "content": "这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题"
        ],
        [
            "role": "System",
            "content": "这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题"
        ],
        [
            "role": "user",
            "content": "这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题"
        ],
        [
            "role": "System",
            "content": "这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题这是一个很好很好的问题"
        ]
    ];
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()

    
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
    
    // MARK: Entity Group
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
        tmppdfEntity.position = SIMD3<Float>(0, 0.18, -0.2)
        return tmppdfEntity;
    }()
    
    @State private var demoEntity: Entity = {
//        let headAnchor = Entity();
//        headAnchor.position = [1, 0, -0.2];
//        headAnchor.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let headAnchor = AnchorEntity(.head)
        headAnchor.position = [0, 0, -0.8]
        return headAnchor;
    }()
    
    @State private var gptEntity: Entity = {
        let tmpEntity = Entity();
        tmpEntity.position = [-0.7, 0, -0.01];
        tmpEntity.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0));
        return tmpEntity;
    } ()
    
    @State private var controlButtonGroupEntity: Entity = {
        let headAnchor = AnchorEntity(.head)
        headAnchor.position = [0, 0, -0.5]
        return headAnchor;
    }()
    
    @State private var gptButtonEntity: Entity = {
        let tmpEntity = Entity();
        tmpEntity.position = [-0.7, 0, -0.01];
        tmpEntity.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0));
        return tmpEntity;
    } ()
    

    @State private var backUrl = "http://10.4.128.60:5025/highlight";
    
    
    // MARK: View Start
    var body: some View {
        RealityView { content, attachments  in
//            ImmersiveView.drawPart(entity: posterEntity)
            posterEntity.addChild(addKeywords(keywords: ["Coulomb's Law", "Electrostatic Interactions", "Dielectric Spheres", "Like-charge Attraction", "Electrostatics", "Opposite-charge Repulsion"], startPosition: SIMD3<Float>(-0.9, 0.01, -0.65)))
            
            
            // 获取高亮区域数据
            fetchHighlights()
            
            content.add(posterEntity)
            
                        
//            pdfEntity.isEnabled = showPDF;
            paperEntity.addChild(pdfEntity)
//            self.paperEntity = paperEntity
            
            content.add(paperEntity)
            
            
//            guard let changePageButtonEntity = attachments.entity(for: "changePage") else { return };
//            changePageButtonEntity.position = SIMD3<Float>(0, -0.2, 0);
//            pdfEntity.addChild(changePageButtonEntity);
            guard let gptSpace = attachments.entity(for: "gptSpace") else { return };
//            gptSpace.position = SIM
            gptEntity.addChild(gptSpace);
            posterEntity.addChild(gptEntity);
            
            
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
            let planeMesh = MeshResource.generatePlane(width: 0.5, height: 0.3)
            let material = VideoMaterial(avPlayer: player)
            let videoEntity = ModelEntity(mesh: planeMesh, materials: [material])
            videoEntity.position = [0, 0, 0]
            
            demoEntity.addChild(videoEntity)

            // 控制面板（按钮、滑块）
            if let controls = attachments.entity(for: "VideoControls") {
                controls.position = [0, -0.18, 0.001]
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
//            buttonGroupEntity.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
//            posterEntity.addChild(buttonGroupEntity)
            controlButtonGroupEntity.addChild(buttonGroupEntity)
            
            content.add(controlButtonGroupEntity)
            
            // attachment: Change Page Button
            guard let changePageButtonEntity = attachments.entity(for: "changePage") else { return };
            changePageButtonEntity.position = SIMD3<Float>(0, -0.2, 0);
            pdfEntity.addChild(changePageButtonEntity);
            
            // attachment: Mini Button Group
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
            // MARK: Attachment Space
            Attachment(id: "gptSpace") {
//                ZStack {
//                    Color(.systemGray6) // 淡灰色背景
//                        .ignoresSafeArea() // 全屏覆盖 Attachment 区域
//                        .opacity(0.4)
                    VStack(spacing: 20) {
                        Text("🎯 GPT Assistant")
                            .font(.largeTitle)
                            .bold()
                        
                        
//                        HStack(spacing: 20) {
//                            
//                            TextField("请输入问题", text: $prompt)
//                                .textFieldStyle(.roundedBorder)
//                                .padding(.horizontal)
//    //                            .background(Color.white.opacity(0.5))
//                                .clipShape(RoundedRectangle(cornerRadius: 10))
//                            Button(action: {
//                                isLoading = true
//                                callMyGPTAPI(prompt: prompt) { result in
//                                    DispatchQueue.main.async {
//                                        reply = result ?? "⚠️ 获取回答失败"
//                                        isLoading = false
//                                    }
//                                }
//                            }) {
//                                Text("Ask GPT")
//                                    .padding()
//                                    .background(Color.blue)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
//                            }
//                            .disabled(isLoading || prompt.isEmpty)
//                            
//                            Button(action: {
//                                isRecording ? stopSpeechRecognition() : startSpeechRecognition()
//                            }) {
//                                ZStack {
//                                    Circle()
//                                        .fill(isRecording ? Color.red : Color.green)
//                                        .frame(width: 50, height: 50)
//                                    
//                                    if isRecording {
//                                        ProgressView()
//                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                    } else {
//                                        Image(systemName: "mic")
//                                            .foregroundColor(.white)
//                                    }
//                                }
//                            }
//                        }
                        
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(reply)
                                .font(.title3)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                        
                        
                        // 聊天记录滚动卡片
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(chatHistory.indices, id: \.self) { i in
                                    ChatRow(chat: chatHistory[i])
                                        .id(i)
                                }
                            }
                            .padding()
                        }
//                        .onChange(of: chatHistory.count) { _ in
//                            if let lastID = chatHistory.last?.id {
//                                withAnimation {
//                                    proxy.scrollTo(lastID, anchor: .bottom)
//                                }
//                            }
//                        }
                        .frame(maxWidth: 600, maxHeight: 650)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

                        
                        Spacer()
                    }
                    .padding()
                .frame(width: 700, height: 800)  // 👉 固定 GPT 区域的宽高
                .background(Color(.systemGray5).opacity(0.5))
                .cornerRadius(20)
                .shadow(radius: 10)
            }
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
                    .frame(width: 600)
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
    
    
    // MARK: - 调用 GPT 接口
    func callMyGPTAPI(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "http://10.4.126.27:5025/chat") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["message": prompt]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode([String: String].self, from: data),
                  let reply = result["reply"] else {
                completion(nil)
                return
            }
            completion(reply)
        }.resume()
    }

    // MARK: - 启动语音识别
    func startSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                print("未授权语音识别")
                return
            }

            DispatchQueue.main.async {
                if self.audioEngine.isRunning {
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                }

                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = self.recognitionRequest else { return }

                recognitionRequest.shouldReportPartialResults = true

                self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                    DispatchQueue.main.async {
                        if let result = result {
                            self.prompt = result.bestTranscription.formattedString
                        }
                        if error != nil || (result?.isFinal ?? false) {
                            self.stopSpeechRecognition()
                        }
                    }
                }

                let inputNode = self.audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)

                inputNode.removeTap(onBus: 0)  // 防止多次 installTap
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }

                do {
                    self.audioEngine.prepare()
                    try self.audioEngine.start()
                    self.isRecording = true
                } catch {
                    print("无法启动 audioEngine: \(error.localizedDescription)")
                    self.isRecording = false
                }
            }
        }
    }

    // MARK: - 停止语音识别
    func stopSpeechRecognition() {
        DispatchQueue.main.async {
            if self.audioEngine.isRunning {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
            self.recognitionRequest?.endAudio()
            self.recognitionTask?.cancel()
            self.recognitionRequest = nil
            self.recognitionTask = nil
            self.isRecording = false
        }
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



//// ✅ 再建子视图 ChatRow
//struct ChatRow: View {
//    let chat: [String: String]
//
//    var body: some View {
//        HStack(spacing: 5) {
//            if chat["role"] == "user" {
//                Image(systemName: "mic")
//                    .foregroundColor(.white)
//                Text(chat["content"] ?? "Something Wrong")
//            } else {
//                Text(chat["content"] ?? "Something Wrong")
//                Image(systemName: "mic")
//                    .foregroundColor(.white)
//            }
//        }
//        .padding(8)
//        .background(Color.white.opacity(0.2))
//        .cornerRadius(8)
//        .onAppear {
//            print(chat["role"] ?? "qqqq")  // 调试用打印
//        }
//    }
//}
struct ChatRow: View {
    let chat: [String: String]

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            if chat["role"] == "user" {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                
                Text(chat["content"] ?? "Something went wrong")
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(Color.gray)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)

            } else {
                
                Text(chat["content"] ?? "Something went wrong")
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(Color.gray)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)

                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
    }
}


// ✅ 简单模型示例
struct Chat {
    let role: String  // "user" 或 "assistant"
    let content: String
}


#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
