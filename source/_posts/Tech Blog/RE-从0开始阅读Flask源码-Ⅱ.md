---
title: 'RE:从0开始阅读Flask源码 Ⅱ'
toc: true
categories: Tech Blog
abbrlink: fb496e1c
date: 2024-04-11 16:08:24
updated: 2024-04-11 16:08:24
---

我们已经基本理解了 Flask 的框架原理，即 Flask 通过与 WerkZeug WSGI 框架进行交互实现 HTTP Web Server 所需要具备的功能，但这些框架原理的讨论实际上是将 Flask 框架视作为一个黑箱，或者说视作了 Web Application Framework 的一个实例为前提进行的。我们所探究的是较为一般的 Web Application Framework 与 HTTP Server 如何协同工作从而实现 Web Server 的方式，并基本了解了 Flask 如何作为 Web Application Framework 与 WSGI 交互以启动 WebServer 的。但我们仍不了解 Flask 在抛开 Web Application Framework 所需要做的基本工作以外，其工作流具体是什么样的。我们将路由匹配，上下文，异常处理的具体实现暂时忽略，单纯的从 Flask 接收到请求并响应的工作流程这一抽象层级上来看看 Flask 是如何工作的

<!--more-->

## 请求处理

首先我们知道，当 WerkZeug 获取到一个 HTTP 请求后，会通过 WSGI 接口以调用 Flask 实例的 `__call__` 方法的方式将该请求传递给 Flask

```Python
def __call__(
    self, environ: WSGIEnvironment, start_response: StartResponse
) -> cabc.Iterable[bytes]:
    """The WSGI server calls the Flask application object as the
    WSGI application. This calls :meth:`wsgi_app`, which can be
    wrapped to apply middleware.
    """
    return self.wsgi_app(environ, start_response)
```

随后，`__call__` 方法会通过调用 `wsgi_app` 方法进行处理

```Python
def wsgi_app(
    self, environ: WSGIEnvironment, start_response: StartResponse
) -> cabc.Iterable[bytes]:
    """The actual WSGI application. This is not implemented in
    :meth:`__call__` so that middlewares can be applied without
    losing a reference to the app object. Instead of doing this::

        app = MyMiddleware(app)

    It's a better idea to do this instead::

        app.wsgi_app = MyMiddleware(app.wsgi_app)

    Then you still have the original application object around and
    can continue to call methods on it.

    .. versionchanged:: 0.7
        Teardown events for the request and app contexts are called
        even if an unhandled error occurs. Other events may not be
        called depending on when an error occurs during dispatch.
        See :ref:`callbacks-and-errors`.

    :param environ: A WSGI environment.
    :param start_response: A callable accepting a status code,
        a list of headers, and an optional exception context to
        start the response.
    """
    ctx = self.request_context(environ)
    error: BaseException | None = None
    try:
        try:
            ctx.push()
            response = self.full_dispatch_request()
        except Exception as e:
            error = e
            response = self.handle_exception(e)
        except:  # noqa: B001
            error = sys.exc_info()[1]
            raise
        return response(environ, start_response)
    finally:
        if "werkzeug.debug.preserve_context" in environ:
            environ["werkzeug.debug.preserve_context"](_cv_app.get())
            environ["werkzeug.debug.preserve_context"](_cv_request.get())

        if error is not None and self.should_ignore_error(error):
            error = None

        ctx.pop(error)
```

忽略掉异常处理与上下文部分的逻辑，`wsgi_app` 方法的功能就是通过调用其它方法针对获取到的请求生成并返回 response 。而如果没有出现异常情况，这一 response 会通过 `full_dispatch_request` 方法进行请求调度后生成

> 在这段代码的注释中 Flask 框架的开发团队写下了他们在此处进行的设计理念。为什么 Flask 不直接在 `__call__` 方法中就进入到处理流程，而是要让 `__call__` 方法调用 `wsgi_app` 方法，再在 `wsgi_app` 方法中进行处理。其目的是为了解耦以提高框架的可拓展性。如果直接通过 `__call__` 方法进行处理，那么中间件需要重载 `__call__` 方法，即用一个新的类继承 Flask 类来达到目的
>
> ```Python
> app = MyMiddleware(app)
> ```
>
> 而 Flask 框架的开发团队认为更好的拓展方式应该是
>
> ```Python
> app.wsgi_app = MyMiddleware(app.wsgi_app)
> ```
>
> 这样，中间件的开发者就可以保持着对原本的 Flask 类实例的引用进行接下来的开发

```Python
def full_dispatch_request(self) -> Response:
    """Dispatches the request and on top of that performs request
    pre and postprocessing as well as HTTP exception catching and
    error handling.

    .. versionadded:: 0.7
    """
    self._got_first_request = True

    try:
        request_started.send(self, _async_wrapper=self.ensure_sync)
        rv = self.preprocess_request()
        if rv is None:
            rv = self.dispatch_request()
    except Exception as e:
        rv = self.handle_user_exception(e)
    return self.finalize_request(rv)
```

`full_dispatch_request` 方法首先会标记自身已处理过一个请求，以便有着针对接收到的第一个请求进行特殊处理需求的业务对此进行拓展。在发送了请求到达信号后，`full_dispatch_request` 方法会通过 `preprocess_request` 方法对到达的请求进行预处理

```Python
def preprocess_request(self) -> ft.ResponseReturnValue | None:
    """Called before the request is dispatched. Calls
    :attr:`url_value_preprocessors` registered with the app and the
    current blueprint (if any). Then calls :attr:`before_request_funcs`
    registered with the app and the blueprint.

    If any :meth:`before_request` handler returns a non-None value, the
    value is handled as if it was the return value from the view, and
    further request handling is stopped.
    """
    names = (None, *reversed(request.blueprints))

    for name in names:
        if name in self.url_value_preprocessors:
            for url_func in self.url_value_preprocessors[name]:
                url_func(request.endpoint, request.view_args)

    for name in names:
        if name in self.before_request_funcs:
            for before_func in self.before_request_funcs[name]:
                rv = self.ensure_sync(before_func)()

                if rv is not None:
                    return rv  # type: ignore[no-any-return]

    return None
```

进行的预处理操作来自于蓝图与通过 `before_first_request` 与 `before_request` 两个方法进行注册的预处理 Hook 函数。若所有预处理 Hook 函数执行完毕后返回值都为 None ，则 `preprocess_request` 方法也会返回 None ，`full_dispatch_request` 方法会通过 `dispatch_request` 方法进行路由分发。

## 路由分发

``` Python
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

`dispatch_request` 方法会通过上下文获取接收到的请求，若该请求无 URL 路由异常，即无 routing_exception ，则根据 URL 规则的 endpoint 执行相应的视图函数，视图函数如 Flask Demo 所示通过 `route` 方法进行注册。视图函数执行完毕则向上传递视图函数的返回值给 `full_dispatch_request` 方法

```Python
def full_dispatch_request(self) -> Response:
    ...
    return self.finalize_request(rv)
```

最后，在以上流程无异常的情况下， `full_dispatch_request` 方法通过 `finalize_request` 方法接受视图函数的返回值并生成响应

## 响应生成

```Python
def finalize_request(
    self,
    rv: ft.ResponseReturnValue | HTTPException,
    from_error_handler: bool = False,
) -> Response:
    """Given the return value from a view function this finalizes
    the request by converting it into a response and invoking the
    postprocessing functions.  This is invoked for both normal
    request dispatching as well as error handlers.

    Because this means that it might be called as a result of a
    failure a special safe mode is available which can be enabled
    with the `from_error_handler` flag.  If enabled, failures in
    response processing will be logged and otherwise ignored.

    :internal:
    """
    response = self.make_response(rv)
    try:
        response = self.process_response(response)
        request_finished.send(
            self, _async_wrapper=self.ensure_sync, response=response
        )
    except Exception:
        if not from_error_handler:
            raise
        self.logger.exception(
            "Request finalizing failed with an error while handling an error"
        )
    return response
```

`finalize_request` 主要做两件事，首先，它会通过 `make_response` 方法将视图函数的返回值封装为 HTTP 响应

```Python
def make_response(self, rv: ft.ResponseReturnValue) -> Response:
    """Convert the return value from a view function to an instance of
    :attr:`response_class`.

    :param rv: the return value from the view function. The view function
        must return a response. Returning ``None``, or the view ending
        without returning, is not allowed. The following types are allowed
        for ``view_rv``:

        ``str``
            A response object is created with the string encoded to UTF-8
            as the body.

        ``bytes``
            A response object is created with the bytes as the body.

        ``dict``
            A dictionary that will be jsonify'd before being returned.

        ``list``
            A list that will be jsonify'd before being returned.

        ``generator`` or ``iterator``
            A generator that returns ``str`` or ``bytes`` to be
            streamed as the response.

        ``tuple``
            Either ``(body, status, headers)``, ``(body, status)``, or
            ``(body, headers)``, where ``body`` is any of the other types
            allowed here, ``status`` is a string or an integer, and
            ``headers`` is a dictionary or a list of ``(key, value)``
            tuples. If ``body`` is a :attr:`response_class` instance,
            ``status`` overwrites the exiting value and ``headers`` are
            extended.

        :attr:`response_class`
            The object is returned unchanged.

        other :class:`~werkzeug.wrappers.Response` class
            The object is coerced to :attr:`response_class`.

        :func:`callable`
            The function is called as a WSGI application. The result is
            used to create a response object.

    .. versionchanged:: 2.2
        A generator will be converted to a streaming response.
        A list will be converted to a JSON response.

    .. versionchanged:: 1.1
        A dict will be converted to a JSON response.

    .. versionchanged:: 0.9
       Previously a tuple was interpreted as the arguments for the
       response object.
    """

    status = headers = None

    # unpack tuple returns
    if isinstance(rv, tuple):
        len_rv = len(rv)

        # a 3-tuple is unpacked directly
        if len_rv == 3:
            rv, status, headers = rv  # type: ignore[misc]
        # decide if a 2-tuple has status or headers
        elif len_rv == 2:
            if isinstance(rv[1], (Headers, dict, tuple, list)):
                rv, headers = rv
            else:
                rv, status = rv  # type: ignore[assignment,misc]
        # other sized tuples are not allowed
        else:
            raise TypeError(
                "The view function did not return a valid response tuple."
                " The tuple must have the form (body, status, headers),"
                " (body, status), or (body, headers)."
            )

    # the body must not be None
    if rv is None:
        raise TypeError(
            f"The view function for {request.endpoint!r} did not"
            " return a valid response. The function either returned"
            " None or ended without a return statement."
        )

    # make sure the body is an instance of the response class
    if not isinstance(rv, self.response_class):
        if isinstance(rv, (str, bytes, bytearray)) or isinstance(rv, cabc.Iterator):
            # let the response class set the status and headers instead of
            # waiting to do it manually, so that the class can handle any
            # special logic
            rv = self.response_class(
                rv,
                status=status,
                headers=headers,  # type: ignore[arg-type]
            )
            status = headers = None
        elif isinstance(rv, (dict, list)):
            rv = self.json.response(rv)
        elif isinstance(rv, BaseResponse) or callable(rv):
            # evaluate a WSGI callable, or coerce a different response
            # class to the correct type
            try:
                rv = self.response_class.force_type(
                    rv,  # type: ignore[arg-type]
                    request.environ,
                )
            except TypeError as e:
                raise TypeError(
                    f"{e}\nThe view function did not return a valid"
                    " response. The return type must be a string,"
                    " dict, list, tuple with headers or status,"
                    " Response instance, or WSGI callable, but it"
                    f" was a {type(rv).__name__}."
                ).with_traceback(sys.exc_info()[2]) from None
        else:
            raise TypeError(
                "The view function did not return a valid"
                " response. The return type must be a string,"
                " dict, list, tuple with headers or status,"
                " Response instance, or WSGI callable, but it was a"
                f" {type(rv).__name__}."
            )

    rv = t.cast(Response, rv)
    # prefer the status if it was provided
    if status is not None:
        if isinstance(status, (str, bytes, bytearray)):
            rv.status = status
        else:
            rv.status_code = status

    # extend existing headers with provided headers
    if headers:
        rv.headers.update(headers)  # type: ignore[arg-type]

    return rv
```

`make_response` 方法会根据视图函数的返回值类型进行响应的封装，封装后得到的类型取决于 response_class 成员，默认情况下其为继承了 WerkZeug 的 ResponseBase 类型的 Response 类型。对于接收了视图函数返回值的 rv 变量:

- 若 rv 为一个元组
  - rv 为一个三元组，则直接 unpacking 为 rv , HTTP status , HTTP headers
  - rv 为一个二元组
    - 若二元组的最后一个成员是字典，元组或列表，则将该二元组 unpacking 为 rv 与 HTTP headers
    - 否则将二元组 unpacking 为 rv 与 HTTP status
  - rv 为其它格式则抛出 TypeError
- 若 rv 为 None ，则抛出 TypeError
- 若 rv 不是一个 response_class 实例
  - rv 为 str ，byte , bytearray 类型或者是一个迭代器，则将 rv 封装为一个 response_class 实例
  - rv 为字典或列表，则将其封装为一个 json.response 实例
  - rv 为 WSGI 底层的 BaseResponse 对象实例或为一个函数（应为满足 WSGI 要求的函数），则通过 response_class.force_type 方法强制转换为 response_class 实例

以上处理逻辑按照顺序执行，最终 rv 会被作为 response_class 实例被返回给 `finalize_request` 方法

`finalize_request` 方法在获取到 `make_response` 方法生成的响应对象后，会再通过 `process_response` 方法对生成的请求通过 Hook 函数再进行响应处理

```Python
def process_response(self, response: Response) -> Response:
    """Can be overridden in order to modify the response object
    before it's sent to the WSGI server.  By default this will
    call all the :meth:`after_request` decorated functions.

    .. versionchanged:: 0.5
       As of Flask 0.5 the functions registered for after request
       execution are called in reverse order of registration.

    :param response: a :attr:`response_class` object.
    :return: a new response object or the same, has to be an
             instance of :attr:`response_class`.
    """
    ctx = request_ctx._get_current_object()  # type: ignore[attr-defined]

    for func in ctx._after_request_functions:
        response = self.ensure_sync(func)(response)

    for name in chain(request.blueprints, (None,)):
        if name in self.after_request_funcs:
            for func in reversed(self.after_request_funcs[name]):
                response = self.ensure_sync(func)(response)

    if not self.session_interface.is_null_session(ctx.session):
        self.session_interface.save_session(self, ctx.session, response)

    return response
```

处理响应的 Hook 函数通过 `after_request` 方法进行注册。

`process_response` 方法处理过后的 response 会返回给 `finalize_request` 方法，发送响应信号后若执行无异常则 `finalize_request` 方法会向上传递 response 给 `full_dispatch_request` 方法，`wsgi_app` 方法，最终通过 WSGI 接口响应给请求方。

## 总结

Flask Web Server 是这样工作的：

Flask 通过 WSGI 接口获取到 HTTP 请求，并通过调用 `wsgi_app` 方法对请求进行处理。`wsgi_app` 方法创建该请求的上下文，并调用 `full_dispatch_request` 方法进行进一步的处理。如果该请求为 Flask Web Server 收到的第一个请求 ， `full_dispatch_request` 会将自己的 _got_first_request 成员设置为 True 以标记已接受过请求(这一成员在 Flask Web Server 启动时被初始化为 False )。在接收到请求后，`full_dispatch_request` 方法会做三件事

- 通过 `preprocess_request` 方法对请求进行预处理
  - `preprocess_request` 方法会执行注册好的 Hook 函数对请求进行预处理，预处理阶段就可能会直接生成响应而非通过视图函数生成响应这一设计是出于业务场景的需求设计的，例如预处理阶段需要对请求方进行鉴权，鉴权不通过便直接响应 403 而非执行相应业务逻辑
  - Hook 函数通过 `before_request` 方法或通过蓝图的 `app_url_value_preprocessor` 方法注册
  - Hook 函数是顺序执行的，若出现非 None 的 Hook 函数返回值则 `preprocess_request` 方法会立即返回以将 Hook 函数返回值向上传递
- 通过 `dispatch_request` 方法进行路由分发
  - Hook 函数全部执行完毕后没有提前进行返回，即 `preprocess_request` 方法的返回值为 None 时，Flask 会进入 `dispatch_request` 方法进行路由分发，从请求中提取出 URL 规则，并根据 URL 的 endpoint 执行对应视图函数，并在视图函数执行完毕后向上传递其返回值
  - 视图函数通过 `route` 方法注册
  - 路由分发时会对路由异常的请求抛出异常以进行处理
- 通过 `finalize_request` 方法生成响应
  - 无论响应是由视图函数生成还是由 Hook 函数生成，它们都需要被 `make_response` 方法封装为 response_class 类型，这一类型默认为 Flask 的 Response 类型
  - 响应被 `make_response` 方法封装为 Response 类型后会被 `process_response` 方法再次进行处理，对响应进行处理的 Hook 函数通过 `after_request` 方法注册

经过以上处理流程后，`full_dispatch_request` 方法将响应传递给 `wsgi_app` 方法，后者将响应通过 WSGI 接口响应给请求方并销毁该请求的上下文

尽管我们在讨论中忽略了 Flask 异常处理，上下文管理，路由匹配与信号相关机制的实现，但这并不妨碍我们基本理解 Flask Web Server 的工作流程的大概样貌。在理解了 Flask 是如何通过它的请求响应循环实现 Web Server 的基本功能后，我们将进一步深入 Flask 框架的路由，上下文管理，异常处理与信号等模块的原理与实现

## Tips

Flask 中针对其功能实现定义了自己的 Request 类型与 Response 类型，不过并未在 WerkZeug 的 RequestBase 与 ResponseBase 类的基础上做太多修改

### Request 类

```Python
class Request(RequestBase):
    """The request object used by default in Flask.  Remembers the
    matched endpoint and view arguments.

    It is what ends up as :class:`~flask.request`.  If you want to replace
    the request object used you can subclass this and set
    :attr:`~flask.Flask.request_class` to your subclass.

    The request object is a :class:`~werkzeug.wrappers.Request` subclass and
    provides all of the attributes Werkzeug defines plus a few Flask
    specific ones.
    """

    json_module: t.Any = json

    #: The internal URL rule that matched the request.  This can be
    #: useful to inspect which methods are allowed for the URL from
    #: a before/after handler (``request.url_rule.methods``) etc.
    #: Though if the request's method was invalid for the URL rule,
    #: the valid list is available in ``routing_exception.valid_methods``
    #: instead (an attribute of the Werkzeug exception
    #: :exc:`~werkzeug.exceptions.MethodNotAllowed`)
    #: because the request was never internally bound.
    #:
    #: .. versionadded:: 0.6
    url_rule: Rule | None = None

    #: A dict of view arguments that matched the request.  If an exception
    #: happened when matching, this will be ``None``.
    view_args: dict[str, t.Any] | None = None

    #: If matching the URL failed, this is the exception that will be
    #: raised / was raised as part of the request handling.  This is
    #: usually a :exc:`~werkzeug.exceptions.NotFound` exception or
    #: something similar.
    routing_exception: HTTPException | None = None

    @property
    def max_content_length(self) -> int | None:  # type: ignore[override]
        """Read-only view of the ``MAX_CONTENT_LENGTH`` config key."""
        if current_app:
            return current_app.config["MAX_CONTENT_LENGTH"]  # type: ignore[no-any-return]
        else:
            return None

    @property
    def endpoint(self) -> str | None:
        """The endpoint that matched the request URL.

        This will be ``None`` if matching failed or has not been
        performed yet.

        This in combination with :attr:`view_args` can be used to
        reconstruct the same URL or a modified URL.
        """
        if self.url_rule is not None:
            return self.url_rule.endpoint

        return None

    @property
    def blueprint(self) -> str | None:
        """The registered name of the current blueprint.

        This will be ``None`` if the endpoint is not part of a
        blueprint, or if URL matching failed or has not been performed
        yet.

        This does not necessarily match the name the blueprint was
        created with. It may have been nested, or registered with a
        different name.
        """
        endpoint = self.endpoint

        if endpoint is not None and "." in endpoint:
            return endpoint.rpartition(".")[0]

        return None

    @property
    def blueprints(self) -> list[str]:
        """The registered names of the current blueprint upwards through
        parent blueprints.

        This will be an empty list if there is no current blueprint, or
        if URL matching failed.

        .. versionadded:: 2.0.1
        """
        name = self.blueprint

        if name is None:
            return []

        return _split_blueprint_path(name)

    def _load_form_data(self) -> None:
        super()._load_form_data()

        # In debug mode we're replacing the files multidict with an ad-hoc
        # subclass that raises a different error for key errors.
        if (
            current_app
            and current_app.debug
            and self.mimetype != "multipart/form-data"
            and not self.files
        ):
            from .debughelpers import attach_enctype_error_multidict

            attach_enctype_error_multidict(self)

    def on_json_loading_failed(self, e: ValueError | None) -> t.Any:
        try:
            return super().on_json_loading_failed(e)
        except BadRequest as e:
            if current_app and current_app.debug:
                raise

            raise BadRequest() from e

```

Flask 的 Request 类在它所继承的 RequestBase 类的基础上通过 @property 装饰器添加了 Flask 框架的蓝图，视图函数 endpoint 等属性，

### Response 类

```Python
class Response(ResponseBase):
    """The response object that is used by default in Flask.  Works like the
    response object from Werkzeug but is set to have an HTML mimetype by
    default.  Quite often you don't have to create this object yourself because
    :meth:`~flask.Flask.make_response` will take care of that for you.

    If you want to replace the response object used you can subclass this and
    set :attr:`~flask.Flask.response_class` to your subclass.

    .. versionchanged:: 1.0
        JSON support is added to the response, like the request. This is useful
        when testing to get the test client response data as JSON.

    .. versionchanged:: 1.0

        Added :attr:`max_cookie_size`.
    """

    default_mimetype: str | None = "text/html"

    json_module = json

    autocorrect_location_header = False

    @property
    def max_cookie_size(self) -> int:  # type: ignore
        """Read-only view of the :data:`MAX_COOKIE_SIZE` config key.

        See :attr:`~werkzeug.wrappers.Response.max_cookie_size` in
        Werkzeug's docs.
        """
        if current_app:
            return current_app.config["MAX_COOKIE_SIZE"]  # type: ignore[no-any-return]

        # return Werkzeug's default when not in an app context
        return super().max_cookie_size
```

## Reference

[Flask Repo](https://github.com/pallets/flask)
[Flask](https://flask.palletsprojects.com/en/2.0.x/)
[WerkZeug](https://github.com/pallets/werkzeug)
