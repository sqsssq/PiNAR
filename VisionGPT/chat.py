'''
Description: 
Author: Qing Shi
Date: 2025-05-16 21:07:11
LastEditors: Qing Shi
LastEditTime: 2025-05-17 21:09:42
'''
from openai import OpenAI
import os



api_key = "sk-48745ada7c404a7089bb1e4266b467c3"


import base64
from dashscope import MultiModalConversation
from http import HTTPStatus
import dashscope
# ======= 1. 配置API Key =======
# API_KEY = '你的API-Key'
dashscope.api_key = api_key
# MultiModalConversation.api_key = "sk-48745ada7c404a7089bb1e4266b467c3"

# ======= 2. 读取本地海报图片，转成base64 =======
def load_image_base64(image_path):
    with open(image_path, 'rb') as img_file:
        img_base64 = base64.b64encode(img_file.read()).decode('utf-8')
    return img_base64

# ======= 3. 初始化对话消息 =======
def initialize_messages(image_base64):
    messages = [
        {
            "role": "user",
            "content": [
                {"image": image_base64},
                {"text": "请你阅读这张海报，并简要介绍它的主要内容。"}
            ]
        }
    ]
    return messages

# ======= 4. 调用Qwen-VL进行问答 =======
def ask_qwen(messages):
    response = MultiModalConversation.call(
        model="qwen-vl-plus",  # 也可以用 "qwen-vl-chat"
        messages=messages
    )
    if response.status_code == HTTPStatus.OK:
        answer = response.output.choices[0].message.content
        print(f"🤖 AI回答：{answer}\n")
        return answer
    else:
        print(f"❌ 出错了: {response.code} {response.message}")
        return None

# ======= 5. 多轮对话主程序 =======
def chat_loop():
    # 输入你本地海报图片路径
    image_path = 'poster.png'  # 替换为你的图片路径 
    image_base64 = load_image_base64(image_path)
    print("✅ 已加载海报图片，请开始提问（输入 'exit' 结束对话）")
    # ⭐⭐ 关键在这里，加上 data URI 前缀 ⭐⭐
    img_data_uri = f"data:image/jpeg;base64,{image_base64}"
    # print(image_base64)
    # 初始化消息
    messages = initialize_messages(img_data_uri)

    # 第一次问：海报总结
    ask_qwen(messages)

    # # 进入多轮对话循环
    # while True:
    #     user_question = input("你想问海报什么问题？(输入 'exit' 退出)：\n")
    #     if user_question.lower() == 'exit':
    #         print("对话结束。")
    #         break
        
    #     # 用户提问追加到消息列表
    #     messages.append({
    #         "role": "user",
    #         "content": [{"text": user_question}]
    #     })

    #     # AI回答
    #     ai_answer = ask_qwen(messages)

    #     # AI的回复也要加到上下文中（多轮记忆）
    #     if ai_answer:
    #         messages.append({
    #             "role": "assistant",
    #             "content": [{"text": ai_answer}]
    #         })

# ======= 6. 运行程序 =======
if __name__ == '__main__':
    chat_loop()
