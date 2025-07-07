---
title: To Be Pythonic Ⅰ
toc: true
categories: Tech Blog
abbrlink: 9be8c95a
date: 2024-01-18 22:21:34
updated: 2024-01-18 22:21:34
---

该系列为我阅读 Effective Python 90 Specific Ways to Write Better Python, Second Edition 并结合我的 Python 编程心得的梳理总结

## 遵循 [PEP 8](https://peps.python.org/pep-0008/) 风格指南

PEP是 Python  Enhancement Proposal的缩写，通常翻译为“ Python 增强提案”。每个PEP都是一份为 Python 社区提供的指导 Python 往更好的方向发展的技术文档，其中的第8号增强提案（PEP 8）是针对 Python 语言编订的代码风格指南。尽管我们可以在保证语法没有问题的前提下随意书写 Python 代码，但是在实际开发中，采用一致的风格书写出可读性强的代码是每个专业的程序员应该做到的事情，也是每个公司的编程规范中会提出的要求，这些在多人协作开发一个项目（团队开发）的时候显得尤为重要。一些强烈建议遵守的规则包括但不限于:

### 空白

- 用空格(Space)表示缩进，而不要使用制表符(Tab)
- 和语法相关的每一层缩进用4个空格表示
- 每行不超过79个字符
- 对于占据多行的长表达式，除了首航之外的其余各行都应该在通常的缩进级别之上再加4个空格
- 同一份文件中，函数和类之间用两个空行隔开
- 同一个类中，方法与方法之间用一个空行隔开
- 使用使用字典时，键与冒号之间不加空格，写在同一行的冒号和值之间应该加一个空格
- 给变量赋值时，复制符号的左边和右边都应该加且仅加一个空格
- 给变量的类型做注解是，变量名和冒号不应该分开，但类型信息前应该有一个空格

### 命名

- 函数、变量及属性遵循snake_case命名规范
- 受保护的实例属性用_开头
- 私有的实例属性用__开头
- 类(包括异常)的命名遵循CamelCase命名规范
- 模块级别的变量的所有字母大写并，各个单词通过_连接
- 类中的实例方法，应该把第一个参数命名为self，表示对象本身
- 类方法的第一个参数，应该命名为cls，表示类本身

### 表达式和语句

The Zen of Python 中提到，**每件事都应该有最简单的做法，而且最好只有一种***(There should be one-- and preferably only one --obvious way to do it)*，这也是 PEP 8 规范表达式和语句的写法的理念

#### 采用行内否定

把否定词直接放在要否定的内容前面，而不要放在整个表达式前面

Pythonic :

```Python
if a is not b
```

Not Pythonic :

```Python
if not a is b
```

#### 用Python的方式判断True or False

不要通过长度或是否等于 `''` / `None` / `[]` / `{}` / `()` 判断容器与序列是否为空，而是直接通过if语句进行判断

 ```Python
if x:
if not x:
```

Pythonic :

```Python
name = '7erry'
fruits = ['7erry']
owners = {'7777': '7erry'}
if name and fruits and owners:
    print('I love fruits!')
```

Not Pythonic :

```Python
name = '7erry'
fruits = ['7erry']
owners = {'7777': '7erry'}
if name != '' and len(fruits) > 0 and owners != {}:
    print('I love fruits!')
```

### 与引入有关的建议

- `import`语句总是放在文件开头的地方
- 引入模块的时候，`from XXX import YYY`比`import XXX`更好。
- 如果有多个`import`语句，应该将其分为三部分，从上到下分别是Python**标准模块**、**第三方模块**和**自定义模块**，每个部分内部应该按照模块名称的**字母表顺序**来排列。

> `from XXX import YYY`真的总是比`import XXX`好吗?我想这应该是见仁见智的，在[Rust语言圣经的一个章节中](https://course.rs/basic-practice/base-features.html),它的作者在讲解以下代码的时候提到
>
> ```Rust
>// in main.rs
>use std::env;
>fn main() {
>    let args: Vec<String> = env::args().collect();
>    dbg!(args);
>} 
>```
>
>>“可能有同学疑惑，为啥不直接引入 `args` ，例如 `use std::env::args` ，这样就无需 `env::args` 来繁琐调用，直接`args.collect()` 即可。原因很简单，`args`方法只会使用一次，啰嗦就啰嗦点吧，把相同的好名字让给 `let args..` 这位大哥不好吗？毕竟人家要出场多次的。”
>
>Pylint 是一款流行的 Python 源代码静态分析工具，它会检查受测代码是否遵循 PEP 8 风格指南并找出程序中存在的错误。许多 IDE 和编辑器以及其他语言都有着这样的 linting 工具,可以借助它们规范你的代码

## 了解 bytes 和 str 的区别

Python 有两种类型可以表示字符序列，一个函数bytes,一个是str.bytes实例包含的是原始数据，即八位的无符号值，str实例包含的则是Unicode码点。二者可以借由`encode`与`decode`两个方法进行转换。

在编写 Python 程序的时候，应该把解码和编码的操作放到界面最外层来做，让程序的核心部分可以使用 Unicode 数据运作，这种方式被叫做 Unicode 三明治（ Unicode Sanwich）。程序的核心部分，应该使用 str 类型来表示 Unicode 数据，并且不要锁定到某种字符编码上面。 这样可以让程序接受许多种字符编码，并把它们转换成 Unicode , 也能保证输出的文本信息都是用同一种标准

## 用 f-string 代替 C 风格的格式字符串与 str.format 方法

格式化是值把数据填写到预先定义的文本模板里面，形成一条用户可读消息，并把这条消息保存成字符串的过程。用 Python 对字符串做格式化处理有四种办法可以考虑，它们都内置在语言和标准库里。即，采用`%`格式化操作符，也就是 C 风格的格式化字符串，内置的format函数和str类的format方法与插值格式字符串(即f-string),这四种办法有各自的优劣，其中C语言使用第一种， Rust 等语言使用第二、三种， Python 则推荐使用 f-string ，即在格式字符串前面加字母f作为前缀，与字母 b 和字母 r 的用法类似。Python 认为 f-string 与其配套的迷你语法最能够简洁而清晰地表达出各种逻辑，因此在编写 Pythonic Code 的时候，Pythoneer 往往都采用 f-string 作为格式化字符的首选。

## 使用 Unpacking

Python 具有unpacking机制，在其他语言例如 Rust 中，这种机制也被叫做模式匹配，它可以帮助我们通过更少的代码更清晰地完成一些任务

Pythonic :

```Python
a, b = b, a
```

Not Pythonic :

```Python
c = a
a = b
b = c
```

这样写可以成立的原因是，Python 处理赋值运算的时候，要先对`=`右边求职，于是，它会新建一个临时的元组，把`b`和`a`的值放到元组里，然后把临时元组里的值再分别写入`=`左边的变量中。unpacking 结束后，这个临时的元组会被释放掉。

除此以外，unpacking 机制也在构建列表，给函数设计参数列表，传递关键字参数，接受多个返回值等多处有着重要作用。它的另一个重要用法是与 enumerate 函数结合使用使得我们的代码变得更加清晰

## 用 in 取代 find

```Python
if x in items: # 包含
for x in items: # 迭代
```

Pythonic :

```Python
name = '7erry'
if 'L' in name:
   print('The name has an L in it.')
```

Not Pythonic :

```Python
name = '7erry'
if name.find('L') != -1:
    print('This name has an L in it!')
```

## 用 enumerate 取代 range

`enumerate`函数可以将迭代器封装为惰性生成器实现需要获取迭代对象长度时对迭代器的更简洁的迭代

Pythonic :

```Python
fruits = ['orange', 'grape', 'pitaya', 'blueberry']
for index, fruit in enumerate(fruits):
print(index, ':', fruit)
```

Not Pythonic :

```Python
fruits = ['orange', 'grape', 'pitaya', 'blueberry']
index = 0
for fruit in fruits:
   print(index, ':', fruit)
   index += 1
```

## 用 zip 函数同时遍历两个迭代器

`zip`函数用于创建惰性生成器，让它每次生成一个元组，当提供的迭代器长度不同时，当任何一个迭代器迭代完毕，`zip`就会停止，如果想按最长的迭代器遍历则可以改用 itertools 模块下的`zip_longest`函数

Pythonic :

```Python
keys = ['1001', '1002', '1003']
values = ['Jerry', '7erry', 'JeRy']
d = dict(zip(keys, values))
print(d)
```

Not Pythonic :

```Python
keys = ['1001', '1002', '1003']
values = ['Jerry', '7erry', 'JeRy']
d = {}
for i, key in enumerate(keys):
   d[key] = values[i]
print(d)
```

## 不要在for和while循环后写else块

Python 的 for/else 和 while/else 结构的设计时为了实现搜索逻辑，但我们完全可以用辅助函数等其他方式更简洁更优雅的实现相同的效果，这一设计带来的困惑已经盖过了它的好处，最好不要采用这种写法

## Reference

Effectivce Python:90 Specific Ways to Write Better Python,Second Edition
[http://safehammad.com/downloads/python-idioms-2014-01-16.pdf](http://safehammad.com/downloads/python-idioms-2014-01-16.pdf)
