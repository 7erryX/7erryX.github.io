---
title: RE:从0开始阅读Flask源码 Ⅳ
toc: true
date: 2024-05-10 22:26:02
updated: 2024-05-10 22:26:02
categories: Tech Blog
---

程序的本质就是指令+上下文。

作为一个 Web Application ，Flask 也必然有着自己的上下文。例如视图函数需要知道包括请求的方法，路径，参数等请求信息的上下文才能够正常的工作。如果你有过其它语言的编程经验，就会很容易想到通过在调用这些函数时在参数中传递相关的数据或这些数据的指针来为函数提供这些必要的上下文信息。如果这门语言支持 OOP ，那么这些请求相关的信息还可以被封装到请求的抽象类中。事实上，确实有不少框架是这样做的，例如 [sanic](https://sanic.dev/en/) 。但这样设计上下文的话，视图函数应该会长成这样

```Python
# demo.py
@app.route(path)
def view_function(request):
    ...
```

也就是说，视图函数应该有 `request` 这么一个参数才对，但从 Flask Demo 中我们并没有发现这样一个参数。显然，Flask 采用了另外一种不同的实现方式。

<!--more-->

## Flask 上下文的实现

Flask 的上下文由类似于全局变量的方式实现，这些全局变量可以通过导入对应模块进行访问。

```Python
# demo.py
from flask import Flask,request

app = Flask(__name__)

@app.route("/",endpoint="root")
def hello_world():
    if request.method =="GET":
        print(request)
    return "hello！"

```

显然，这个全局变量必然需要进行某些设计，例如不同线程或协程之间的上下文应该各自保持独立以避免脏读脏写或竞争。同时这样的全局变量应当有多个，因为 Flask 的不同模块都有着自己不同用途的上下文需要处理。通过阅读源码可以发现这些全局变量都在 globals.py 中被定义，它的内容非常简单，具体如下

```Python
# globals.py
from __future__ import annotations

import typing as t
from contextvars import ContextVar

from werkzeug.local import LocalProxy

if t.TYPE_CHECKING:  # pragma: no cover
    from .app import Flask
    from .ctx import _AppCtxGlobals
    from .ctx import AppContext
    from .ctx import RequestContext
    from .sessions import SessionMixin
    from .wrappers import Request


_no_app_msg = """\
Working outside of application context.

This typically means that you attempted to use functionality that needed
the current application. To solve this, set up an application context
with app.app_context(). See the documentation for more information.\
"""
_cv_app: ContextVar[AppContext] = ContextVar("flask.app_ctx")
app_ctx: AppContext = LocalProxy(  # type: ignore[assignment]
    _cv_app, unbound_message=_no_app_msg
)
current_app: Flask = LocalProxy(  # type: ignore[assignment]
    _cv_app, "app", unbound_message=_no_app_msg
)
g: _AppCtxGlobals = LocalProxy(  # type: ignore[assignment]
    _cv_app, "g", unbound_message=_no_app_msg
)

_no_req_msg = """\
Working outside of request context.

This typically means that you attempted to use functionality that needed
an active HTTP request. Consult the documentation on testing for
information about how to avoid this problem.\
"""
_cv_request: ContextVar[RequestContext] = ContextVar("flask.request_ctx")
request_ctx: RequestContext = LocalProxy(  # type: ignore[assignment]
    _cv_request, unbound_message=_no_req_msg
)
request: Request = LocalProxy(  # type: ignore[assignment]
    _cv_request, "request", unbound_message=_no_req_msg
)
session: SessionMixin = LocalProxy(  # type: ignore[assignment]
    _cv_request, "session", unbound_message=_no_req_msg
)
```

我们能够从源代码中看出，globals.py 首先创建了两个与上下文有关的错误信息与变量，`_cv_app` 与 `_cv_request`，随后通过它们创建了另外六个变量，即 `app_ctx`, `current_app`, `g`, `request_ctx`, `request` 和 `session`。这些全局变量尽管类型有所区别，但都由 LocalProxy 这个代理所操作的对象产生，查看其对应的签名可以发现其操作的对象所属的类分别与 `_cv_app` 和 `_cv_request` 一致

```Python
# local.py
class LocalProxy(
    local: ContextVar[AppContext] | Local | LocalStack[AppContext] | (() -> AppContext),
    name: str | None = None,
    *,
    unbound_message: str | None = None
)

class LocalProxy(
    local: ContextVar[RequestContext] | Local | LocalStack[RequestContext] | (() -> RequestContext),
    name: str | None = None,
    *,
    unbound_message: str | None = None
)
```

分别阅读这两个类的注释

```plaintext
# ctx.py
AppContext
The app context contains application-specific information. An app context is created and pushed at the beginning of each request if one is not already active. An app context is also pushed when running CLI commands.

RequestContext
The request context contains per-request information. The Flask app creates and pushes it at the beginning of the request, then pops it at the end of the request. It will create the URL adapter and request object for the WSGI environment provided.

Do not attempt to use this class directly, instead use ~flask.Flask.test_request_context and ~flask.Flask.request_context to create this object.

When the request context is popped, it will evaluate all the functions registered on the application for teardown execution (~flask.Flask.teardown_request).

The request context is automatically popped at the end of the request. When using the interactive debugger, the context will be restored so request is still accessible. Similarly, the test client can preserve the context after the request ends. However, teardown functions may already have closed some resources such as database connections.
```

也就是说，Flask 中的上下文主要分为两类，`AppContext` 和 `RequestContext`，其中前者代表了应用级别的上下文，后者代表了请求级别的上下文。这两类上下文包含了六个全局变量，尽管我们目前还不理解这六个全局变量的具体功能（其实看变量名也能大概理解），但能够确定它们的实质是来自 WerkZeug 的 `LocalProxy` 类（见第 6 行）的实例。这是非常合理的，因为尽管 Flask 已经支持使用其它的 WSGI Server，但 Flask 仍是基于一个 WerkZeug 的 WSGI Application，直接使用 WerkZeug 提供的上下文实现作为自己的上下文实现确实是一件非常自然的事

> 这两级上下文的概念在 [Flask 的文档说明](#reference) 中有着详细的解释，在此就不过多赘述。

## 线程上下文与 WerkZeug 上下文的实现

阅读了 globals.py 中的代码后不难看出，为了理解 Flask 上下文的实现，我们的下一个目标就是探索 `LocalProxy` 这个类。但在此之前，我们需要先从线程上下文的实现方式谈起。为了避免不同线程共用同一上下文时产生竞争或未定义行为，程序往往需要实现一个能够线程隔离的上下文。一个容易想到的实现方式是，使用一个字典存储本线程的上下文，再使用一个以各个线程的线程 ID 为键，以该线程 ID 对应的线程的上下文作为值的字典来存储所有线程的上下文。这样，每个线程只需要以自己的线程 ID 为索引，便可以分别从同一全局变量中访问自己的上下文，且不同线程的上下文彼此隔离。

```Python
import threading

class ThreadLocal(object):
    def __init__(self):
        # self.storage = {}
        object.__setattr__(self,"storage",{})

    def __setattr__(self, key, value):
        ident = threading.get_ident()
        self.storage.setdefault(ident,{})[key] = value
    def __getattr__(self,item):
        ident = threading.get_ident()
        if ident not in self.storage:
            return
        return self.storage[ident].get(item)        
```

这是一个较为简单的基于嵌套线程上下文的实现，其中每一个线程的上下文都是独立的。这一点可以借由下列 POC 验证

```Python
local = ThreadLocal()

def task(arg):
    local.key = arg
    print(local.key)

task_list = []

for i in range(7):
    t = threading.Thread(target=task(i))
    t.start()
    task_list.append(t)

for t in task_list:
    t.join()
```

它的输出应该是

```plaintext
0
1
2
3
4
5
6
```

实际上，Python 内置的 `ThreadLocal` 就是以类似的方式实现的，它可以通过 `threading.local()` 获取。而 WerkZeug 并没有直接使用 `threading.local`，而是自行实现了略有区别的 `werkzeug.local.Local` 类，还实现了 `LocalStack` 和 `LocalProxy` 这两种新的数据结构。`Local` 类与我们的 `ThreadLocal` 一样使用了一个字典来保存本线程的上下文以提供属性访问，而 `LocalStack` 则是使用了一个栈来保存本线程上下文以提供栈访问，除此以外大同小异。`LocalProxy` 类主要用于代理它的 `Local` 对象或 `LocalStack` 对象，负责把所有对自己的操作转发给内部的 `Local` 对象或 `LocalStack` 对象。其实现方式不在本文的讨论范围之内，故在此不再深究。

Flask 主要通过 `LocalProxy` 来操作 `LocalStack` 以存储上下文对象，其目的在于兼容多 application 的使用情况。当多个 Flask Application 同时运行时，当前应用的上下文需要动态更新，而使用栈存储上下文可以确保当前运行的上下文的准确

## Flask 上下文的管理

在[RE:从0开始阅读Flask源码 Ⅱ](http://7erry.com/2024/04/11/RE-%E4%BB%8E0%E5%BC%80%E5%A7%8B%E9%98%85%E8%AF%BBFlask%E6%BA%90%E7%A0%81-%E2%85%A1/#%E8%AF%B7%E6%B1%82%E5%A4%84%E7%90%86)中我们已经了解了 Flask 请求-响应循环的工作流程，而在这一流程的第一步，WSGI Server 调用 WSGI Application 时，我们便已经能够看到上下文的身影

```Python
# app.py
def request_context(self, environ: WSGIEnvironment) -> RequestContext:
    """Create a :class:`~flask.ctx.RequestContext` representing a
    WSGI environment. Use a ``with`` block to push the context,
    which will make :data:`request` point at this request.

    See :doc:`/reqcontext`.

    Typically you should not call this from your own code. A request
    context is automatically pushed by the :meth:`wsgi_app` when
    handling a request. Use :meth:`test_request_context` to create
    an environment and context instead of this method.

    :param environ: a WSGI environment
    """
    return RequestContext(self, environ)

def wsgi_app(
    self, environ: WSGIEnvironment, start_response: StartResponse
) -> cabc.Iterable[bytes]:
    ctx = self.request_context(environ)
    ...
    try:
        try:
            ctx.push()
            ...
        except Exception as e:
            ...
        ...
    finally:
        ...
        ctx.pop(error)
```

WSGI Server 每次在调用 Flask 对象的 `__call__` 方法时，都会将对应的请求信息入栈，并在请求处理完毕后将其出栈。入栈时，这一请求信息通过 `request_context` 方法，即通过 `RequestContext` 的构造方法被封装为一个 `RequestContext` 对象

```Python
# ctx.py
class RequestContext:
    """The request context contains per-request information. The Flask
    app creates and pushes it at the beginning of the request, then pops
    it at the end of the request. It will create the URL adapter and
    request object for the WSGI environment provided.

    Do not attempt to use this class directly, instead use
    :meth:`~flask.Flask.test_request_context` and
    :meth:`~flask.Flask.request_context` to create this object.

    When the request context is popped, it will evaluate all the
    functions registered on the application for teardown execution
    (:meth:`~flask.Flask.teardown_request`).

    The request context is automatically popped at the end of the
    request. When using the interactive debugger, the context will be
    restored so ``request`` is still accessible. Similarly, the test
    client can preserve the context after the request ends. However,
    teardown functions may already have closed some resources such as
    database connections.
    """

    def __init__(
        self,
        app: Flask,
        environ: WSGIEnvironment,
        request: Request | None = None,
        session: SessionMixin | None = None,
    ) -> None:
        self.app = app
        if request is None:
            request = app.request_class(environ)
            request.json_module = app.json
        self.request: Request = request
        self.url_adapter = None
        try:
            self.url_adapter = app.create_url_adapter(self.request)
        except HTTPException as e:
            self.request.routing_exception = e
        self.flashes: list[tuple[str, str]] | None = None
        self.session: SessionMixin | None = session
        # Functions that should be executed after the request on the response
        # object.  These will be called before the regular "after_request"
        # functions.
        self._after_request_functions: list[ft.AfterRequestCallable[t.Any]] = []

        self._cv_tokens: list[
            tuple[contextvars.Token[RequestContext], AppContext | None]
        ] = []
    
    ...

    def match_request(self) -> None:
        """Can be overridden by a subclass to hook into the matching
        of the request.
        """
        try:
            result = self.url_adapter.match(return_rule=True)  # type: ignore
            self.request.url_rule, self.request.view_args = result  # type: ignore
        except HTTPException as e:
            self.request.routing_exception = e

    def push(self) -> None:
        # Before we push the request context we have to ensure that there
        # is an application context.
        app_ctx = _cv_app.get(None)

        if app_ctx is None or app_ctx.app is not self.app:
            app_ctx = self.app.app_context()
            app_ctx.push()
        else:
            app_ctx = None

        self._cv_tokens.append((_cv_request.set(self), app_ctx))

        # Open the session at the moment that the request context is available.
        # This allows a custom open_session method to use the request context.
        # Only open a new session if this is the first time the request was
        # pushed, otherwise stream_with_context loses the session.
        if self.session is None:
            session_interface = self.app.session_interface
            self.session = session_interface.open_session(self.app, self.request)

            if self.session is None:
                self.session = session_interface.make_null_session(self.app)

        # Match the request URL after loading the session, so that the
        # session is available in custom URL converters.
        if self.url_adapter is not None:
            self.match_request()

    def pop(self, exc: BaseException | None = _sentinel) -> None:  # type: ignore
        """Pops the request context and unbinds it by doing that.  This will
        also trigger the execution of functions registered by the
        :meth:`~flask.Flask.teardown_request` decorator.

        .. versionchanged:: 0.9
           Added the `exc` argument.
        """
        clear_request = len(self._cv_tokens) == 1

        try:
            if clear_request:
                if exc is _sentinel:
                    exc = sys.exc_info()[1]
                self.app.do_teardown_request(exc)

                request_close = getattr(self.request, "close", None)
                if request_close is not None:
                    request_close()
        finally:
            ctx = _cv_request.get()
            token, app_ctx = self._cv_tokens.pop()
            _cv_request.reset(token)

            # get rid of circular dependencies at the end of the request
            # so that we don't require the GC to be active.
            if clear_request:
                ctx.request.environ["werkzeug.request"] = None

            if app_ctx is not None:
                app_ctx.pop(exc)

            if ctx is not self:
                raise AssertionError(
                    f"Popped wrong request context. ({ctx!r} instead of {self!r})"
                )

```

因此，Flask 上下文的管理逻辑实际上为，当收到请求时，创建当前进程/线程的上下文对象（`RequestContext` 对象），上下文对象在被创建时，会将 WSGI Server 传递的 `environ` 参数封装为一个 `Request` 对象并存储到上下文对象的 `request` 成员中。然后，Flask 将调用上下文对象的 `push` 方法，将自身压入到请求上下文的堆栈中

> 上下文对象除了保存了 `request` 外，还保存了另外一个重要的上下文 `session` 。与 `request` 不同的是，在请求上下文对象创建时会被设置为 `None`，在请求上下文被推入到请求上下文堆栈时才会被创建

进一步观察 Flask 在创建上下文时的行为，尤其是这几行代码

```Python
# app.py
    app_ctx = _cv_app.get(None)
    self._cv_tokens.append((_cv_request.set(self), app_ctx))
    ctx = _cv_request.get()
```

我们能从这些感到熟悉的行为中联想到线程上下文中类似的操作方式。结合 globals.py 中创建变量时的类型注解，会发现，`_cv_app` 和 `_cv_request` 实际上就是存储各线程的线程上下文的 `LocalStack`。而 `app_ctx`, `current_app`, `g`, `request_ctx`, `request` 和 `session` 这六个由 `LocalProxy` 的构造方法所创建的全局变量，实际上是类似于某种动态指针。它们所引用的对象由 `LocalProxy` 自动获取，当它们被使用时则是通过触发 `LocalProxy` 的魔术方法自行查找并返回

因此，在理解了这些全局变量的实际作用后，Flask 的上下文管理方式就更加清晰了。在每次从 WSGI Server 接收请求时，Flask 创建当前进程/线程需要处理的两个包含了对应上下文具体信息的上下文对象，并将它们 push 到线程隔离的栈中。当视图函数需要读取上下文进行响应处理时，则通过 `LocalProxy` 代理从栈中动态地获取上下文对象中保存的包含了对应信息的具体对象，并在处理结束后将上下文对象 pop 出栈清理内存

## 总结

让我引用一下[flask工作原理与机制解析](#reference)中的一段话作为这篇博客的结尾

> Flask中的上下文由表示请求上下文的 RequestContext 类实例和表示程序上下文的 AppContext 类实例组成。请求上下文对象存储在请求上下文堆栈中，程序上下文对象存储在程序上下文堆栈中。
> 当一个请求发来的时候：
> 1）需要保存请求相关的信息——有了请求上下文
> 2）为了更好地分离程序的状态，应用起来更加灵活——有了程序上下文
> 3）为了让上下文对象可以在全局动态访问，而不用显式地传入视图函数，同时确保线程安全——有了 Local（本地线程）
> 4）为了支持多个程序——有了 LocalStack（本地堆栈）
> 5）为了支持动态获取上下文对象——有了 LocalProxy（本地代理）
> 6）……
> 7）为了让这一切愉快的工作在一起——有了 Flask

## Reference

[Flask Repo](https://github.com/pallets/flask)
[Flask](https://flask.palletsprojects.com/en/2.0.x/)
[WerkZeug](https://github.com/pallets/werkzeug)
[Flask 的 Context 机制](https://blog.tonyseek.com/post/the-context-mechanism-of-flask/)
[flask工作原理与机制解析](https://blog.csdn.net/baidu_33387365/article/details/108339983)
[Flask Document about Application Context](http://flask.pocoo.org/docs/appcontext/)
[Flask Document about Request Context](http://flask.pocoo.org/docs/reqcontext/)
