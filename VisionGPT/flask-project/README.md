# Flask Project

## 项目简介
这是一个基础的Flask项目，旨在展示如何创建和配置Flask应用程序。该项目包含基本的路由和一个简单的HTML模板。

## 文件结构
```
flask-project
├── app
│   ├── __init__.py
│   ├── routes.py
│   └── templates
│       └── index.html
├── requirements.txt
└── README.md
```

## 功能
- **app/__init__.py**: 初始化Flask应用程序实例，并配置基本设置和扩展。
- **app/routes.py**: 定义应用程序的路由，处理不同URL请求的视图函数。
- **app/templates/index.html**: 应用程序的HTML模板，用于渲染主页内容。
- **requirements.txt**: 列出项目所需的Python依赖包。

## 使用方法
1. 克隆此项目到本地。
2. 在项目根目录下创建一个虚拟环境并激活它。
3. 安装依赖包：
   ```
   pip install -r requirements.txt
   ```
4. 运行Flask应用：
   ```
   flask run
   ```
5. 在浏览器中访问 `http://127.0.0.1:5000` 查看应用程序。