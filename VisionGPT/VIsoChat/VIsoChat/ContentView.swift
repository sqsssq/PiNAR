import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var reply: String = ""
    @State private var isLoading = false
    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()

    var body: some View {
        VStack(spacing: 20) {
            Text("🎯 GPT Assistant")
                .font(.largeTitle)
                .bold()

            TextField("请输入问题", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    isLoading = true
                    callMyGPTAPI(prompt: prompt) { result in
                        DispatchQueue.main.async {
                            reply = result ?? "⚠️ 获取回答失败"
                            isLoading = false
                        }
                    }
                }) {
                    Text("Ask GPT")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLoading || prompt.isEmpty)

                Button(action: {
                    isRecording ? stopSpeechRecognition() : startSpeechRecognition()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.green)
                            .frame(width: 50, height: 50)

                        if isRecording {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "mic")
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            if isLoading {
                ProgressView()
            } else {
                Text(reply)
                    .font(.title3)
                    .padding()
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - 调用 GPT 接口
    func callMyGPTAPI(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "http://10.4.128.60:5025/chat") else {
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

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
