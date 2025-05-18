'''
Description: 
Author: error: git config user.name & please set dead value or install git
Date: 2025-05-06 13:55:40
LastEditors: Qing Shi
LastEditTime: 2025-05-18 00:42:16
'''
from flask import Flask, request, jsonify
from flask_cors import CORS
# import openai
from openai import OpenAI
import time
import os
import base64
from dashscope import MultiModalConversation
from http import HTTPStatus
import dashscope

api_key = "sk-48745ada7c404a7089bb1e4266b467c3"
dashscope.api_key = api_key


app = Flask(__name__)
CORS(app)

# ======= 2. 读取本地海报图片，转成base64 =======
def load_image_base64(image_path):
    with open(image_path, 'rb') as img_file:
        img_base64 = base64.b64encode(img_file.read()).decode('utf-8')
    
    img_data_uri = f"data:image/jpeg;base64,{img_base64}"
    return img_data_uri

def ask_qwen(messages):
    response = MultiModalConversation.call(
        model="qwen-vl-plus",  # 也可以用 "qwen-vl-chat"
        messages=messages
    )
    if response.status_code == HTTPStatus.OK:
        answer = response.output.choices[0].message.content
        print(f"🤖 AI回答：{answer}\n")
        return answer[0]["text"]
    else:
        print(f"❌ 出错了: {response.code} {response.message}")
        return None

def initialize_messages(image_base64, data):
    messages = [
        {
            "role": "system",
            "content": [{"text": "你是一个海报问答助手，仔细分析用户提供的海报，并准确回答相关问题。当回答使用了markdown格式的时候，请在换行使用两个\n进行换行。"}] 
        }
    ]
    img_f = 0
    for d in data:
        if img_f == 0 and d["role"] == "user":
            img_f = 1
            messages.append({
                "role": "user",
                "content": [
                    {"image": image_base64},
                    {"text": d["content"]}
                ]
            })
        else:
            messages.append({
                "role": d["role"],
                "content": [
                    {"text": d["content"]}
                ]
            })
    return messages

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
    print(user_message)

    # if not user_message:
    #     return jsonify({"error": "No message provided"}), 400
    image_path = 'poster.png'  # 替换为你的图片路径 
    image_base64 = load_image_base64(image_path)
    messages = initialize_messages(image_base64, user_message)
    print(messages)
    answer = ask_qwen(messages)
    print(answer)
    return jsonify({"reply": answer})


def summarize_chat_history_with_gpt(chat_history):
    """
    使用 GPT 对聊天历史记录进行整理和总结。

    Args:
        chat_history (list): 聊天历史记录，格式为 [(user_message, bot_reply), ...]。

    Returns:
        str: 整理和总结后的内容。
    """
    prompt = "以下是用户和AI的对话记录，请根据这些对话生成一段总结，提取关键信息并以清晰的方式呈现：\n\n"
    
    image_path = 'poster.png'  # 替换为你的图片路径 
    image_base64 = load_image_base64(image_path)
    messages = initialize_messages(image_base64, chat_history)
    
    messages.append({
        "role": "user",
        "content": [
            {"text": prompt }
        ]
    })

    response = MultiModalConversation.call(
        model="qwen-vl-plus",
        messages=messages
    )
    if response.status_code == HTTPStatus.OK:
        summary = response.output.choices[0].message.content
        return summary[0]["text"]
    else:
        print(f"❌ 出错了: {response.code} {response.message}")
        return "总结生成失败。"

def generate_md_note_with_summary(image_path, chat_history, output_path="note.md"):
    """
    生成 Markdown 格式的笔记，包含海报图片、聊天记录和 GPT 整理的总结。

    Args:
        image_path (str): 海报图片的路径。
        chat_history (list): 聊天历史记录，格式为 [(user_message, bot_reply), ...]。
        output_path (str): 输出的 Markdown 文件路径。
    """
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"图片路径不存在: {image_path}")
    print(111)
    # 将图片转换为 Markdown 格式
    image_md = f"![Poster Image]({image_path})\n\n"

    # 构造聊天记录的 Markdown 格式
    chat_md = "## 记录\n\n"

    image_path = 'poster.png'  # 替换为你的图片路径 
    image_base64 = load_image_base64(image_path)
    messages = initialize_messages(image_base64, chat_history)

    img_f = 0
    for message in messages:
        if message["role"] == "user":
            if img_f == 0:
                img_f = 1
                chat_md += f"**用户**: {message["content"][1]["text"]}\n\n"
            else:
                chat_md += f"**用户**: {message["content"][0]["text"]}\n\n"
        elif message["role"] == "assistant":
            chat_md += f"**AI**: {message["content"][0]["text"]}\n\n"

    # 使用 GPT 整理和总结聊天历史
    summary = summarize_chat_history_with_gpt(chat_history)
    print("summary", summary)
    summary_md = "## 总结\n\n**在此海报前观看讨论5分钟**\n\n" + summary + "\n\n"

    # 合并内容
    md_content = image_md + summary_md + chat_md

    # 写入到 Markdown 文件
    with open(output_path, "w", encoding="utf-8") as md_file:
        md_file.write(md_content)
    
    print(f"✅ Markdown 笔记已生成: {output_path}")

@app.route('/generate_note', methods=['POST'])
def generate_note():
    data = request.get_json()
    chat_history = data.get("message", [])
    image_path = data.get("image_path", "poster.png")
    # 获取当前时间戳作为 UID
    current_time = time.strftime("%Y%m%d%H%M%S", time.localtime())
    output_format_path = f"note_{current_time}.md"
    output_path = data.get("output_path", output_format_path)
    print(chat_history, image_path, output_path)

    try:
        generate_md_note_with_summary(image_path, chat_history, output_path)
        return jsonify({"message": "Markdown 笔记已生成", "output_path": output_path})
    except Exception as e:
        print(f"❌ 生成笔记时出错: {e}")
        return jsonify({"error": str(e)}), 500



if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5025, debug=True)
