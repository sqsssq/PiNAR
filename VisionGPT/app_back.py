'''
Description: 
Author: Qing Shi
Date: 2025-05-17 20:37:17
LastEditors: Qing Shi
LastEditTime: 2025-05-17 20:37:18
'''
'''
Description: 
Author: error: git config user.name & please set dead value or install git
Date: 2025-05-06 13:55:40
LastEditors: Qing Shi
LastEditTime: 2025-05-17 18:13:54
'''
from flask import Flask, request, jsonify
from flask_cors import CORS
# import openai
from openai import OpenAI
import time
api_key = "27a56877-1b50-4750-989e-5564415f169f"
client = OpenAI(
    api_key = api_key,
    base_url = "https://ark.cn-beijing.volces.com/api/v3",
)

app = Flask(__name__)
CORS(app)


@app.route('/')
def index():
    return "Welcome to the visionOS ChatGPT API!"

@app.route('/highlight', methods=['POST'])
def highlight():
    boxes = [
        {"x": 0.5, "y": 0.5, "width": 1, "height": 1},
        {"x": 0.5, "y": 0.5, "width": 0.1, "height": 0.1}
    ]
    return jsonify(boxes)


@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_message = data.get("message", "")

    # if not user_message:
    #     return jsonify({"error": "No message provided"}), 400

    # try:
    #     # 使用 ChatGPT API (GPT-3.5 或 GPT-4)
    #     response = client.chat.completions.create(
    #         model = "deepseek-r1-250120",  # your model endpoint ID
    #         messages=[
    #             {"role": "system", "content": "你是一个帮助用户理解 visionOS 编程的专家。"},
    #             {"role": "user", "content": user_message}
    #         ],
    #         max_tokens=500
    #     )

    #     reply = response.choices[0].message.content
    #     print(reply)
    #     return jsonify({"reply": reply})

    # except Exception as e:
    #     print(f"Error: {e}")
    #     return jsonify({"error": str(e)}), 500
    time.sleep(5)
    return jsonify({"reply": "这张海报主要研究了在极化介质中两个带电介电球之间的静电相互作用机制，特别是通过有效偶极子分析揭示了在特定条件下（介质的介电常数大于两球的介电常数）可能出现的反向电荷排斥现象。"})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5025, debug=True)
