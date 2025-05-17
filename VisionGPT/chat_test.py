'''
Description: 
Author: Qing Shi
Date: 2025-05-17 20:42:53
LastEditors: Qing Shi
LastEditTime: 2025-05-17 20:51:45
'''
import dashscope
from dashscope import MultiModalConversation

# 设置 DashScope API Key
dashscope.api_key = 'sk-48745ada7c404a7089bb1e4266b467c3'  # 替换为你的实际 API Key

# 图片路径（固定）
IMAGE_PATH = "poster.png"

def qwen_vl_query(image_path, user_input, history=None):
    if history is None:
        history = []

    # 构造消息历史
    messages = []
    for q, a in history:
        messages.append({"role": "user", "content": [{"text": q}]})
        messages.append({"role": "assistant", "content": [{"text": a}]})

    # 添加当前请求
    messages.append({
        "role": "user",
        "content": [
            {"image": f"file://{image_path}"},
            {"text": user_input}
        ]
    })

    try:
        response = MultiModalConversation.call(
            model="qwen-vl-max",  # 可选: qwen-vl-chat, qwen-vl-plus
            messages=messages
        )
        return response.output.text
    except Exception as e:
        return f"[Error] {str(e)}"

def main():
    print("✅ 已加载海报图片，请开始提问（输入 '退出' 结束对话）")
    history = []

    while True:
        user_input = input("你: ")
        if user_input.lower() in ['退出', 'exit', 'quit']:
            print("Qwen Bot: 再见！")
            break

        print("Qwen Bot 正在思考...")
        answer = qwen_vl_query(IMAGE_PATH, user_input, history)
        print(f"Qwen Bot: {answer}")

        # 保存历史
        history.append((user_input, answer))

if __name__ == "__main__":
    main()