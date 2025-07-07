---
title: RE:从0开始阅读Flask源码 Ⅰ
toc: true
date: 2024-04-04 22:19:35
updated: 2024-04-04 22:19:35
categories: Tech Blog
---

简单解读 Flask 的源代码以了解 Flask 与类 Flask 框架中相关功能的具体实现，设计模式和代码组织方式

Flask 框架的源代码写的非常简洁，例如 Flask 最早发行的 0.1 版本只包含了核心脚本 `flask.py` , 不考虑空行代码量仅 400 余行，故比较容易阅读与理解。不过 Flask 各个模块联系紧密，线性的阅读方式可能比较难以达成理想的阅读效果，因此本博客系列决定从一些功能切入，自顶向下地解读 Flask 的核心源代码，了解具体的实现方法，再掌握 Flask 框架的整体结构，最后在理想的条件下融汇贯通完整理解 Flask 框架的设计，真是一次酣畅淋漓的源代码阅读之旅啊！

Flask，启动！
<!--more-->
## Flask 简介

Python Flask 是一个知名的轻量级的 Web 应用框架，由 Armin Ronacher 开发于2010年。它的设计理念是简洁而灵活，旨在帮助开发者快速构建 Web 应用程序。Flask 基于 Werkzeug WSGI 工具箱和 Jinja2 模板引擎，同时也受到了 Django 框架的启发

Flask 的核心功能包括路由分发、模板渲染、表单处理、会话管理等，同时还提供了丰富的扩展库，如 Flask-SQLAlchemy、Flask-RESTful、Flask-Login 等，使开发者能够根据需要灵活地扩展功能

其特色之一是简单易学，由于其简洁的设计和清晰的文档，使得新手可以迅速上手。此外，Flask 的扩展生态系统非常丰富，提供了大量的第三方扩展库，满足了各种不同需求，并以其简洁、灵活和易扩展的特点，成为了开发 Web 应用的理想选择，尤其适合小型和中型项目的开发

## 准备工作

使用 pip 或你的系统包管理器安装 Flask 以便进行调试，下以 Arch Linux 的 pacman 为例

```bash
pacman -Syu python-flask
```

使用 git 下载 Flask 的源代码

```bash
git clone https://github.com/pallets/flask.git
```

Flask 框架截止至 2024.4.1 ( V3.02 ) 的源代码的目录结构应该是

```plaintext
flask
├── app.py
├── blueprints.py
├── cli.py
├── config.py
├── ctx.py
├── debughelpers.py
├── globals.py
├── helpers.py
├── __init__.py
├── json
│   ├── __init__.py
│   ├── provider.py
│   └── tag.py
├── logging.py
├── __main__.py
├── py.typed
├── sansio
│   ├── app.py
│   ├── blueprints.py
│   ├── README.md
│   └── scaffold.py
├── sessions.py
├── signals.py
├── templating.py
├── testing.py
├── typing.py
├── views.py
└── wrappers.py
```

在你喜欢的 IDE 或文本编辑器中打开它，准备完毕

## Flask Demo

下面是 Flask 框架官方给出的 Demo

```Python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return "HelloWorld"

if __name__ == "__main__":
    app.run()
```

阅读这段代码，可以看出它首先从 `flask` 模块中引入了 `Flask` ，根据 Python 的命名规范可以判断它应该是一个对象。接着，该程序以 `__name__` 为参数构造了一个 `Flask` 对象实例并命名为 `app`。随后使用了 `app` 内的 `route` 装饰器，以 / 作为参数装饰了函数 `index`，这个函数会返回字符串字面值 HelloWorld 。然后，如果当前程序是被 Python 直接执行而非被导入的，就调用 `app` 实例的 `run` 方法。它的运行效果是在本机的 5000 端口创建了一个 WebServer 。访问 URL localhost:5000/ 我们会收到 "HelloWorld" 字符串作为返回

不难看出，这段代码工作的核心，也是理解 Flask 框架工作原理的核心，就在我们引入的 Flask 类上，让我们查看 Flask 类的源代码，看看这个类是如何被实现的

## Flask 框架原理初探

### WerkZeug WSGI 框架初探

在执行 Flask 使用实例代码时，实际启动这个项目的代码是 `app.run()`，也即是说，启动 WebServer 的代码一定在 Flask 类的 run 方法里。不过，在具体说明 Flask 类的工作方式之前，我们先需要通过一段代码了解一下 Flask 的依赖 WerkZeug 。

```Python
from werkzeug.serving import run_simple

def hello(environ, start_response):
    print("HelloWorld")

if __name__ == "__main__":
    run_simple("127.0.0.1", 5000, hello)
```

运行这段代码，会发现它也在本地 5000 端口启动了一个 WebServer ，当我们访问这个 WebServer 时会得到一个 500 Internal Server Error ，同时在服务端输出了 Hello ，也就是 hello 函数里 print 的内容。

### Flask 执行流程初探

在 WerkZeug 启动后，我们能发现它的控制台输出与 Flask 的输出非常类似。接着，查看 Flask 类的源码，在 Flask 类的 run 方法 ( 612 ) 行附近，你会看到这段代码

```Python
from werkzeug.serving import run_simple

try:
    run_simple(t.cast(str, host), port, self, **options)

```

也就是说，Flask 的 run 方法实际上就是通过调用 Werkzeug 的  run_simple 函数启动的 WebServer 。联系一下给出的 Werkzeug 代码示例，不难猜到 `t.cast(str,host)` 是经 Flask 处理后填入的 IP 地址，`port` 则是端口，从位置参数来看，`self` 对应的是示例中的 `hello` 函数。这种把对象实例当作函数传入的方法不由得让我们想起了 \_\_call\_\_ 魔术方法，接着查看 Flask 的源代码在 1481 行附近我们成功的找到了 Flask 类的  `__call__` 魔术方法实现，它长这样

```Python
def __call__(
    self, environ: WSGIEnvironment, start_response: StartResponse
) -> cabc.Iterable[bytes]:
```

不出我们所料，它的函数签名与 Werkzeug 代码示例中的 `hello` 函数的函数签名非常的相似。

这很难不让我们突发异想用之前在 [Flask Demo](#flask-demo) 看到的代码执行的方式实现 Werkzeug 代码示例中的效果

```Python
from werkzeug.serving import run_simple

class Flask(object):
    def __init__(self,*args) -> None:
        pass

    def __call__(self, environ, start_response):
        print("HelloWorld")
        
    def run(self):
        run_simple("127.0.0.1", 5000, self)

app = Flask(__name__)

if __name__ == "__main__":
    app.run()
```

此时，我们所写的 Flask 类已经与 Flask 框架中的 Flask 类的工作原理非常接近了。但是访问了这段代码所启动的 WebServer 后，我们无法像 Flask Demo 那样得到响应，如果直接把 `__call__` 方法中的 print 语句改为 return 的话，会得到这样的报错

```Python
from werkzeug.serving import run_simple

class Flask(object):
    def __init__(self,*args) -> None:
        pass

    def __call__(self, environ, start_response):
        return "HelloWorld"
        
    def run(self):
        run_simple("127.0.0.1", 5000, self)

app = Flask(__name__)

if __name__ == "__main__":
    app.run()

#* 127.0.0.1 - - [04/Apr/2024 19:06:21] "GET / HTTP/1.1" 500 -
#* Error on request:
#* Traceback (most recent call last):
#*   File "/usr/lib/python3.11/site-packages/werkzeug/serving.py", line 364, in run_wsgi
#*     execute(self.server.app)
#*   File "/usr/lib/python3.11/site-packages/werkzeug/serving.py", line 328, in execute
#*     write(data)
#*   File "/usr/lib/python3.11/site-packages/werkzeug/serving.py", line 255, in write
#*     assert status_set is not None, "write() before start_response"
#*            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#* AssertionError: write() before start_response
```

这表明我们的返回值没有满足 WerkZeug 的某种要求。让我们阅读 Flask 的源代码，看看它是如何进行返回的

```Python
def __call__(
    self, environ: WSGIEnvironment, start_response: StartResponse
) -> cabc.Iterable[bytes]:
    return self.wsgi_app(environ, start_response)
```

我们对函数返回值的调用链进行追踪，依次可以得到

```Python
def wsgi_app(
    self, environ: WSGIEnvironment, start_response: StartResponse
) -> cabc.Iterable[bytes]:
    ...
    response = self.full_dispatch_request()
    ...
    return response(environ, start_response)

def full_dispatch_request(self) -> Response:
    ...
    return self.finalize_request(rv)

def finalize_request(
    self,
    rv: ft.ResponseReturnValue | HTTPException,
    from_error_handler: bool = False,
) -> Response:
    response = self.make_response(rv)
    ...
    return response

def make_response(self, rv: ft.ResponseReturnValue) -> Response:
    """Convert the return value from a view function to an instance of
    :attr:`response_class`.
    :param rv: the return value from the view function. The view function
            must return a response.
    ...
    """
    ...
    if not isinstance(rv, self.response_class):
        if isinstance(rv, (str, bytes, bytearray)) or isinstance(rv, cabc.Iterator):
            rv = self.response_class(
                rv,
                status=status,
                headers=headers,  # type: ignore[arg-type]
            )
    ...
    return rv
```

经过一系列的溯源追踪，我们定位到了 Flask 类的 make_response 方法。通过阅读注释我们得知 rv 就是视图函数的返回值，以 Flask Demo 为例则 rv 是 str 类型的字面值 HelloWorld，即 `rv: str = "HelloWorld"`。make_response 方法会针对视图函数的返回值的类型对其进行对应的处理与封装，由于在本例中 rv 是字符串，程序会执行上面代码中保留的逻辑，将 HTTP 响应封装为一个 self.response_class 类型的实例。让我们查看它的定义

```Python
# flask/app.py
class Flask(App):
    ...
    response_class: type[Response] = Response
    ...

# flask/wrappers.py
class Response(ResponseBase):
    ...

# werkzeug/wrappers.py
#！ werkzeug 的源代码中其实是 class Response(_SansIOResponse):
class ResponseBase(_SansIOResponse):
```

我们发现，Flask 定义了继承自 WerkZeug 的 ResponseBase 类的 Response 类作为自己的 HTTP 响应。也就是说，Flask 框架响应的 HTTP Response 实际上是进行了一些封装的 WerkZeug 的 Response 类。让我们用 WerkZeug 的 Response 类作为返回值，仿照一下 Flask 框架的写法更新一下上文中我们自己实现的 Flask 类

```Python
from werkzeug.serving import run_simple
from werkzeug.wrappers import Response

class Flask(object):
    def __init__(self,*args) -> None:
        pass

    def __call__(self, environ, start_response):
        msg =  "HelloWorld"
        resp = Response(msg)
        return resp(environ,start_response)
        
    def run(self):
        run_simple("127.0.0.1", 5000, self)

app = Flask(__name__)

if __name__ == "__main__":
    app.run()
```

程序运行后，让我们访问一下启动的 WebServer

```plaintext
❯ curl localhost:5000
HelloWorld%
```

很好，符合我们的预期

### 总结

此时，我们已经能够对 Flask 的运行原理有了一个比较初步的认识

一个 WebServer 实际上可以分为 HTTP 服务器与 Web 应用程序两个部分。当用户发起了一个请求，这一请求通过 socket 发送到服务器后，会被 HTTP 服务器接收。HTTP 服务器会将其交给 Web 应用程序进行业务处理。在 Flask 框架创建的应用程序中，其依赖 WerkZeug 负责实现 HTTP 服务器所需要实现的功能，而 Flask 则作为一个 Web 应用被 HTTP 服务器所调用，通过传入的请求信息，例如 URL , HTTP Method 等信息执行对应的视图函数以实现对应的业务处理逻辑，例如表单检查，数据库 CRUD 等，并返回 HTTP Response 给用户。具体地说，Flask 通过 run 方法调用 WerkZeug 启动 HTTP 服务器，当用户的请求到达服务器时，HTTP 服务器会调用 Flask，Flask 再通过 \_\_call\_\_ 方法调用处理相关逻辑的其他方法，最终返回封装后的 WerkZeug 框架中的 Response 类实例给 HTTP 服务器，HTTP 服务器再生成响应的 HTTP Response 返回给用户

以上是本博客基于博客内容对 Flask 框架原理的简单概括

## Tips

### WSGI

HTTP 服务器与 Web 应用程序之间的交互需要一个接口，Python 将这一接口称作 WSGI (由 PEP 333 所规定)。只要 HTTP 服务器和 Web 应用程序框架都遵守这个约定，就能实现两者的自由组合。而按照这一规定，一个面向 WSGI 的 Web 应用程序框架必须实现以下方法

```Python
def application(environ,start_response)
```

其中的 `environ` 参数是一个字典，Web 应用程序从中获取请求信息。`start_response` 是一个函数，Web 应用程序进行业务处理后通过调用该函数设置响应头，并返回响应体(响应体需要是可迭代的)给 HTTP 服务器，HTTP 服务器再返回响应给用户

### WerkZeug

WerkZeug 是 Flask 唯一不可或缺的依赖，负责完成 WebServer 中较为底层的工作，例如请求与响应处理、中间件、调试器、实现 URL 到视图的映射、线程保护等等。它非常的强大，不过迫于精力与技术水平的有限，本系列不会深入 WerkZeug 的源码与实现，也不会深入 Jinja2 模板渲染、蓝图等额外功能的源码与实现，而是将主要篇幅放在 Flask 框架作为 WebServer 的核心源码上，如果你对 WerkZeug 感兴趣，可以到它们的[官方仓库](#reference)下阅读相关文档进行更深入的了解

## Reference

[Flask Repo](https://github.com/pallets/flask)
[Flask](https://flask.palletsprojects.com/en/2.0.x/)
[WerkZeug](https://github.com/pallets/werkzeug)
