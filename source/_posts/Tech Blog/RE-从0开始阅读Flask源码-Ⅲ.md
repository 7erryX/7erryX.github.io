---
title: 'RE:从0开始阅读Flask源码 Ⅲ'
toc: true
categories: Tech Blog
abbrlink: 62403fa6
date: 2024-04-24 22:26:02
updated: 2024-04-24 22:26:02
---

一个 Web 应用针对不同的请求路径会有不同的处理函数，而路由就是根据 HTTP 请求的 URL 找到对应处理函数的过程。Flask 的路由实现较为轻量，更为底层的路由处理逻辑由 WerkZeug 实现，在此系列博客中暂不进行深入的探讨，让我们先从经典的 Flask Demo 开始讨论

<!--more-->

## Flask Demo

```Python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return "HelloWorld"

if __name__ == "__main__":
    app.run()
```

## 路由注册/视图函数注册的流程

Flask Demo 使用了以下代码创建了一个视图函数

```Python
@app.route("/index")
def index():
    return "HelloWorld"
```

不难理解，该视图函数会用于处理 URL 为 /index 的请求并响应 HelloWorld 字符串。其中最引人注目的是视图函数上方的装饰器，Flask 可以通过使用 `route` 装饰器对视图函数进行注册。阅读 `route` 方法的源代码

```Python
@setupmethod
def route(self, rule: str, **options: t.Any) -> t.Callable[[T_route], T_route]:
    """Decorate a view function to register it with the given URL
    rule and options. Calls :meth:`add_url_rule`, which has more
    details about the implementation.

    .. code-block:: python

        @app.route("/")
        def index():
            return "Hello, World!"

    See :ref:`url-route-registrations`.

    The endpoint name for the route defaults to the name of the view
    function if the ``endpoint`` parameter isn't passed.

    The ``methods`` parameter defaults to ``["GET"]``. ``HEAD`` and
    ``OPTIONS`` are added automatically.

    :param rule: The URL rule string.
    :param options: Extra options passed to the
        :class:`~werkzeug.routing.Rule` object.
    """

    def decorator(f: T_route) -> T_route:
        endpoint = options.pop("endpoint", None)
        self.add_url_rule(rule, endpoint, f, **options)
        return f

    return decorator
```

阅读后可以得知，`route` 装饰器的效果，就是让视图函数在执行自身原本的功能以外，再额外根据传入的 rule 参数值与可选传入的 endpoint 参数值执行 `add_url_rule` 方法。即 Flask Demo 中的代码实际上等价于

```Python
def index():
    return "HelloWorld"
app.add_url_rule("/index",index)
```

也就是说，视图函数的注册是通过 `add_url_rule` 方法实现的，让我们进一步阅读 `add_url_rule` 方法的源代码

```Python
# scaffold.py
@setupmethod
def add_url_rule(
    self,
    rule: str,
    endpoint: str | None = None,
    view_func: ft.RouteCallable | None = None,
    provide_automatic_options: bool | None = None,
    **options: t.Any,
) -> None:
    """Register a rule for routing incoming requests and building
    URLs. The :meth:`route` decorator is a shortcut to call this
    with the ``view_func`` argument. These are equivalent:

    .. code-block:: python

        @app.route("/")
        def index():
            ...

    .. code-block:: python

        def index():
            ...

        app.add_url_rule("/", view_func=index)

    See :ref:`url-route-registrations`.

    The endpoint name for the route defaults to the name of the view
    function if the ``endpoint`` parameter isn't passed. An error
    will be raised if a function has already been registered for the
    endpoint.

    The ``methods`` parameter defaults to ``["GET"]``. ``HEAD`` is
    always added automatically, and ``OPTIONS`` is added
    automatically by default.

    ``view_func`` does not necessarily need to be passed, but if the
    rule should participate in routing an endpoint name must be
    associated with a view function at some point with the
    :meth:`endpoint` decorator.

    .. code-block:: python

        app.add_url_rule("/", endpoint="index")

        @app.endpoint("index")
        def index():
            ...

    If ``view_func`` has a ``required_methods`` attribute, those
    methods are added to the passed and automatic methods. If it
    has a ``provide_automatic_methods`` attribute, it is used as the
    default if the parameter is not passed.

    :param rule: The URL rule string.
    :param endpoint: The endpoint name to associate with the rule
        and view function. Used when routing and building URLs.
        Defaults to ``view_func.__name__``.
    :param view_func: The view function to associate with the
        endpoint name.
    :param provide_automatic_options: Add the ``OPTIONS`` method and
        respond to ``OPTIONS`` requests automatically.
    :param options: Extra options passed to the
        :class:`~werkzeug.routing.Rule` object.
    """
    raise NotImplementedError
```

这是在 `route` 方法所在的 scaffold.py 文件下的 `add_url_rule` 方法的定义，通过注释验证并补充了我们之前得出的结论，即 Flask Demo 中注册视图函数的代码实际上等价于

```Python
def index():
    return "HelloWorld"
app.add_url_rule("/index","index",index)
```

在进行视图函数的注册时，endpoint 的值默认等于视图函数名。如果不相等则需要通过 `endpoint` 装饰器将视图函数与 endpoint 进行绑定。

奇怪的是，`add_url_rule` 方法什么都没做，而只是抛出了未实现的异常。继续搜索 `add_url_rule` 方法可以发现，scaffold.py 文件下的 `add_url_rule` 方法处在 Scaffold 类中，在同目录下的 app.py 文件的 App 类则通过继承 Scaffold 类完成了 `add_url_rule` 方法的具体实现

```Python
# app.py
@setupmethod
def add_url_rule(
    self,
    rule: str,
    endpoint: str | None = None,
    view_func: ft.RouteCallable | None = None,
    provide_automatic_options: bool | None = None,
    **options: t.Any,
) -> None:
    if endpoint is None:
        endpoint = _endpoint_from_view_func(view_func)  # type: ignore
    options["endpoint"] = endpoint
    methods = options.pop("methods", None)

    # if the methods are not given and the view_func object knows its
    # methods we can use that instead.  If neither exists, we go with
    # a tuple of only ``GET`` as default.
    if methods is None:
        methods = getattr(view_func, "methods", None) or ("GET",)
    if isinstance(methods, str):
        raise TypeError(
            "Allowed methods must be a list of strings, for"
            ' example: @app.route(..., methods=["POST"])'
        )
    methods = {item.upper() for item in methods}

    # Methods that should always be added
    required_methods = set(getattr(view_func, "required_methods", ()))

    # starting with Flask 0.8 the view_func object can disable and
    # force-enable the automatic options handling.
    if provide_automatic_options is None:
        provide_automatic_options = getattr(
            view_func, "provide_automatic_options", None
        )

    if provide_automatic_options is None:
        if "OPTIONS" not in methods:
            provide_automatic_options = True
            required_methods.add("OPTIONS")
        else:
            provide_automatic_options = False

    # Add the required methods now.
    methods |= required_methods

    rule_obj = self.url_rule_class(rule, methods=methods, **options)
    rule_obj.provide_automatic_options = provide_automatic_options  # type: ignore[attr-defined]

    self.url_map.add(rule_obj)
    if view_func is not None:
        old_func = self.view_functions.get(endpoint)
        if old_func is not None and old_func != view_func:
            raise AssertionError(
                "View function mapping is overwriting an existing"
                f" endpoint function: {endpoint}"
            )
        self.view_functions[endpoint] = view_func
```

首先，如果 endpoint 为 None ，即 endpoint 为默认值，则调用 _endpoint_from_view_func 函数初始化 endpoint

```Python
if endpoint is None:
    endpoint = _endpoint_from_view_func(view_func)  # type: ignore
options["endpoint"] = endpoint
```

_endpoint_from_view_func 函数源代码为

```Python
def _endpoint_from_view_func(view_func: ft.RouteCallable) -> str:
    """Internal helper that returns the default endpoint for a given
    function.  This always is the function name.
    """
    assert view_func is not None, "expected view func if endpoint is not provided."
    return view_func.__name__
```

其功能为返回该函数的函数名，与之前阅读注释时获悉的 endpoint 默认为 view_function 函数名这一点相吻合

```Python
methods = options.pop("methods", None)

# if the methods are not given and the view_func object knows its
# methods we can use that instead.  If neither exists, we go with
# a tuple of only ``GET`` as default.
if methods is None:
    methods = getattr(view_func, "methods", None) or ("GET",)
if isinstance(methods, str):
    raise TypeError(
        "Allowed methods must be a list of strings, for"
        ' example: @app.route(..., methods=["POST"])'
    )
methods = {item.upper() for item in methods}
```

随后，从参数列表中取出 methods 参数，其默认值为 None 。若调用 `add_url_rule` 方法时未提供，则根据 view_function 的 methods 属性取值，如果仍为 None 则默认为 GET ，即默认路由 HTTP GET 请求。需要注意的是 methods 应该是一个元组而非字符串，否则会抛出 TypeError

```Python
# Methods that should always be added
required_methods = set(getattr(view_func, "required_methods", ()))

# starting with Flask 0.8 the view_func object can disable and
# force-enable the automatic options handling.
if provide_automatic_options is None:
    provide_automatic_options = getattr(
        view_func, "provide_automatic_options", None
    )

if provide_automatic_options is None:
    if "OPTIONS" not in methods:
        provide_automatic_options = True
        required_methods.add("OPTIONS")
    else:
        provide_automatic_options = False

# Add the required methods now.
methods |= required_methods
```

随后 `add_url_rule` 方法会以类似的逻辑确认 required_methods ，required_methods 是 view_function 默认支持的 HTTP 请求方法，它会被添加到 methods 中

```Python
rule_obj = self.url_rule_class(rule, methods=methods, **options)
rule_obj.provide_automatic_options = provide_automatic_options  # type: ignore[attr-defined]

self.url_map.add(rule_obj)
if view_func is not None:
    old_func = self.view_functions.get(endpoint)
    if old_func is not None and old_func != view_func:
        raise AssertionError(
            "View function mapping is overwriting an existing"
            f" endpoint function: {endpoint}"
        )
    self.view_functions[endpoint] = view_func
```

忽略处理 endpoint 与 methods 的相关逻辑后，这段代码就是 `add_url_rule` 方法实际上的工作内容，即更新 url_map 与 view_functions 两个成员。url_rule_class 即 Flask 表示 URL 规则的类，它默认为 WerkZeug 提供的 Rule 类。通过调用 `add_url_rule` 方法时提供的 rule 参数与根据前述规则构建的 methods 创建 Rule 类的实例 rule 并进行初始化后，`add_url_rule` 方法会将 rule 对象添加到 url_map 成员中。url_map 是一个 url_map_class 类的实例，后者是 Flask 表示 URL 规则与 endpoint 的映射的类，默认为 WerkZeug 提供的 Map 类。然后，`add_url_rule` 方法会从 view_functions 成员中检索 endpoint 参数对应的 view_function ，若该 endpoint 存在对应的 view_function 且与 view_function 参数指向的 view_function 不一致则抛出 AssertionError，这一判断的目的是为确保每个 view_function 的 endpoint 不重复。view_functions 成员是一个以 endpoint （str）与 view_function （RouteCallable）为键值对的字典，如果该检测通过，则将该 endpoint 与 view_function 插入到 view_functions 中

因此，Flask Demo 中视图函数的注册实际上是这样进行的

```Python
# app = Flask(__name__)
def index():
    return "HelloWorld"
rule_obj = app.url_rule_class("/index", methods=("GET",))
app.url_map.add(rule_obj)
app.view_functions["/index"] = index
```

## 路由分发

请求到达 Flask Web Server 时 Flask 会为这个请求创建生命周期为从请求到来到结束响应为止的请求上下文，在请求上下文创建时，Flask 会根据从 WSGI 接口处获得的 environ 创建对应的 Request 对象，并通过同时创建的 WerkZeug 的 MapAdapter 对象的 `match` 方法解析获取该请求的 url_rule 与 view_args 然后放入到上下文的 request 成员的对应属性中。view_args 是动态路由获取到的 URL 路径参数。

```Python
class Flask(App):
    def create_url_adapter(self, request: Request | None) -> MapAdapter | None:
        """Creates a URL adapter for the given request. The URL adapter
        is created at a point where the request context is not yet set
        up so the request is passed explicitly.

        .. versionadded:: 0.6

        .. versionchanged:: 0.9
           This can now also be called without a request object when the
           URL adapter is created for the application context.

        .. versionchanged:: 1.0
            :data:`SERVER_NAME` no longer implicitly enables subdomain
            matching. Use :attr:`subdomain_matching` instead.
        """
        if request is not None:
            # If subdomain matching is disabled (the default), use the
            # default subdomain in all cases. This should be the default
            # in Werkzeug but it currently does not have that feature.
            if not self.subdomain_matching:
                subdomain = self.url_map.default_subdomain or None
            else:
                subdomain = None

            return self.url_map.bind_to_environ(
                request.environ,
                server_name=self.config["SERVER_NAME"],
                subdomain=subdomain,
            )
        # We need at the very least the server name to be set for this
        # to work.
        if self.config["SERVER_NAME"] is not None:
            return self.url_map.bind(
                self.config["SERVER_NAME"],
                script_name=self.config["APPLICATION_ROOT"],
                url_scheme=self.config["PREFERRED_URL_SCHEME"],
            )

        return None

class RequestContext:
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

    def match_request(self) -> None:
        """Can be overridden by a subclass to hook into the matching
        of the request.
        """
        try:
            result = self.url_adapter.match(return_rule=True)  # type: ignore
            self.request.url_rule, self.request.view_args = result  # type: ignore
        except HTTPException as e:
            self.request.routing_exception = e
```

这些数据会被 Flask 的 `dispatch_request` 方法获取以进行路由分发

```Python
def dispatch_request(self) -> ft.ResponseReturnValue:
    """Does the request dispatching.  Matches the URL and returns the
    return value of the view or error handler.  This does not have to
    be a response object.  In order to convert the return value to a
    proper response object, call :func:`make_response`.

    .. versionchanged:: 0.7
       This no longer does the exception handling, this code was
       moved to the new :meth:`full_dispatch_request`.
    """
    req = request_ctx.request
    if req.routing_exception is not None:
        self.raise_routing_exception(req)
    rule: Rule = req.url_rule  # type: ignore[assignment]
    # if we provide automatic options for this URL and the
    # request came with the OPTIONS method, reply automatically
    if (
        getattr(rule, "provide_automatic_options", False)
        and req.method == "OPTIONS"
    ):
        return self.make_default_options_response()
    # otherwise dispatch to the handler for that endpoint
    view_args: dict[str, t.Any] = req.view_args  # type: ignore[assignment]
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]
```

`dispatch_request` 方法首先会从该请求的上下文中获取到请求的相关参数，若该请求无路由异常便获取其路由规则，否则通过 `raise_routing_exception` 方法进入到异常处理流程。随后判断其路由规则是否开启了自动预检选项，若该选项开启且请求方式为 OPTIONS 则调用 `make_default_options_response` 自动预检请求并生成预检请求的响应

```Python
def make_default_options_response(self) -> Response:
    """This method is called to create the default ``OPTIONS`` response.
    This can be changed through subclassing to change the default
    behavior of ``OPTIONS`` responses.

    .. versionadded:: 0.7
    """
    adapter = request_ctx.url_adapter
    methods = adapter.allowed_methods()  # type: ignore[union-attr]
    rv = self.response_class()
    rv.allow.update(methods)
    return rv
```

对于其它的路由规则，`dispatch_request` 方法会直接通过该路由规则的 endpoint 值与 view_functions 这一视图函数跳转表传递参数执行 endpoint 对应的视图函数，实现路由分发并向上传递视图函数的返回值

## 总结

从上文的讨论中不难看出，Flask 的路由中由 HTTP 报文到具体 URL 规则这一步骤的核心逻辑是由 WerkZeug 实现的，Flask 在路由上的实现主要体现在由 URL 规则到 endpoint 与从 endpoint 到视图函数上

Flask 的路由注册实质上就是通过 WerkZeug 提供的接口将 endpoint 与 URL 规则相关联，再将 endpoint 与对应的视图函数的键值对插入到 endpoint-view_function 的跳转表中；而其路由分发与动态路由则是通过请求上下文获取到经 WerkZeug 的 url_adapter 解析出的 URL 规则，并获取到该规则对应的 endpoint ，再以该 endpoint 为索引通过跳转表执行视图函数进行业务处理这一方式实现

## Reference

[Flask Repo](https://github.com/pallets/flask)
[Flask](https://flask.palletsprojects.com/en/2.0.x/)
[WerkZeug](https://github.com/pallets/werkzeug)
[Endpoint in Flask Routing](https://stackoverflow.com/questions/19261833/what-is-an-endpoint-in-flask/19262349#19262349)
