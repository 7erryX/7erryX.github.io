---
title: ForkBomb
toc: true
categories: Tech Blog
abbrlink: 5e5fcbac
date: 2023-08-07 00:00:00
updated: 2023-09-05 00:00:00
---

## 简介

ForkBomb可通过创建大量进程消耗大量的系统资源，从而拖慢系统与正常进程的运行速度，增大响应时间，使得操作系统的正常运作受到较大影响

<!--more-->

## ForkBomb原理解析

一个非常经典的ForkBomb为

```Bash
:(){ :|: & };:
```

这其实是一个扁平化的表达式，它可以格式化为

```Bash
:(){
    :|: &
};
:
```

因为在 Bash 中，:、.、/ 等一些字符也能够被用于函数命名，因此，上面的代码按照更常规的写法其实等价于：

```Bash
func()
{
    func | func &
};
func
```

ForkBomb的核心是函数体执行的 ```func | func &``` ，它代表的操作是

- 递归执行func 函数
- 使用管道```|```把前一个func函数的返回值传给第二个func函数
- 第二个func函数通过```&```标志将会在后台执行，且fork出的子进程在父进程被回收时不会被回收
ForkBomb的执行结果是创建两个函数实例，然后不断地递归调用使得实例数量指数式增长，最终耗尽系统所有资源

## 防御手段

- 修改系统配置，设置一个用户拥有的进程数上限，例如```ulimit -u 77```限制用户最多拥有77个进程

## Reference

[https://en.wikipedia.org/wiki/Fork_bomb](https://en.wikipedia.org/wiki/Fork_bomb)
