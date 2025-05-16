'''
Description: 
Author: Qing Shi
Date: 2025-05-16 21:07:11
LastEditors: Qing Shi
LastEditTime: 2025-05-16 21:09:07
'''
from openai import OpenAI
import os

api_key = "sk-48745ada7c404a7089bb1e4266b467c3"

client = OpenAI(
    api_key = api_key,
    base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1",
)

completion = client.chat.completions.create(
    # 模型列表：https://help.aliyun.com/zh/model-studio/getting-started/models
    model="qwen-plus",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "你是谁？"},
    ],
    # Qwen3模型通过enable_thinking参数控制思考过程（开源版默认True，商业版默认False）
    # 使用Qwen3开源版模型时，若未启用流式输出，请将下行取消注释，否则会报错
    # extra_body={"enable_thinking": False},
)
print(completion.model_dump_json())