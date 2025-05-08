from flask import Flask

def create_app():
    app = Flask(__name__)

    # 配置应用程序的基本设置
    app.config['SECRET_KEY'] = 'your_secret_key'

    # 注册蓝图或路由
    from .routes import main
    app.register_blueprint(main)

    return app