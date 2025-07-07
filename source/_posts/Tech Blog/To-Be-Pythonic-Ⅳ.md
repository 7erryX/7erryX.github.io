---
title: To be Pythonic Ⅳ 推导与生成
toc: true
categories: Tech Blog
abbrlink: 79de166e
date: 2024-02-22 22:16:25
updated: 2024-02-22 22:16:25
---

我们经常需要处理 list 、 dict 和 set 等数据结构，并以这种处理逻辑为基础构建程序。Python 提供了一种特殊的写法，叫做推导 (comprehension) ，可以简洁地迭代这些结构，并根据迭代结果派生出另一套数据。Python 还将这一理念运用到了函数上，也就是生成器。泛式可以使用迭代的任务都支持生成器函数(例如循环，带星号的表达式等)。生成器可以提升性能，减少内存用量并提升代码的可读性，是 Pythonic Code 的鲜明特征
<!--more-->
## 用列表推导取代 map 与 filter

假设我们要用一个列表中的每个元素的平方值构建一份新的列表

传统的写法是

```Python
example = [1,2,3,4,5,6,7]
squares = []

#version 1
for x in example:
    squares.append(x**2)

#version 2
squares = map(lambda x:x**2,a)
```

但如果使用列表推导表达式的话，可以写为

```Python
example = [1,2,3,4,5,6,7]
squares = [x**2 for x in a]
```

相较之下后者显然会更加简洁已读，这一差距会在更复杂的情况下变得显著。例如，这个新列表只需要纳入源列表中的偶数的平方时，传统的写法是

```Python
#version 1
for x in example:
    if x % 2 == 0:
        squares.append(x**2)

#version 2
squares = map(lambda x:x**2,filter(lambda x:x % 2 == 0,a))
```

而使用列表推导表达式的话则可以写为

```Python
squares = [x**2 for x in a if x % 2 == 0]
```

字典与集合也有相应的推导机制，例如

```Python
# traditional
squares_dict = dict(map(lambda x:(x,x**2),filter(lambda x: x % 2 == 0,a)))
squares_set = set(map(lambda x:x**2,filter(lambda x:x % 2 == 0,a)))

# comprehension
squares_dict = {x:x**2 for x in a if x % 2 == 0}
squares_set ={x**2 for x in a if x % 2 == 0}
```

相比之下显然推导式要更为直观好懂

## 控制推导逻辑的子表达式不应该超过两个

除了最基本的写法外，推导式还支持多层循环，例如要把矩阵转化成普通的一维列表，可以在推导时使用两个 for 表达式，这些表达式会按照从左到右的顺序执行

```Python
matrix = [
    [1,2,3],
    [4,5,6],
    [7,8,9]
    ]
flat = [x for row in matrix for x in row]
```

这样写简单易懂，也是多层循环在列表推导之中的合理用法。它还可以通过嵌套推导逻辑构建二维数组，例如

```Python
squares = [[x**2 for x in row] for row in matrix]
```

当然，相较于只有一层循环的推导式而言，有着多层循环的推导逻辑相较而言已经开始有了可读性的下降。因此，在表示推导逻辑时，最多只应该写两个子表达式，也就是 for 和 if 不应该超过两对。面对更为复杂的问题情景时，应考虑使用辅助函数或普通的 for 和 if 语句实现

## 用赋值表达式消除推导中的重复代码

对于以下代码

```Python
stock = { ... }
order = [ ... ]

def func(value) -> Optional[int]:
    ...

result = {}
for key in order:
    foo = stock.get(key,0)
    bar = func(foo)
    if bar:
        result[key] = bar
```

我们很容易想到用字典推导表达式改写为

```Python
result = {
            key:func(stock.get(key,0)) 
            for key in order 
            if func(stock.get(key,0))
        }
```

但这段代码看的人恨不舒服，原因是它会重复计算 `func(stock.get(key,0))` , 同时如果我们需要对代码进行修改时，如果忘记对两处代码同步修改，很容易导致一些奇怪的 bug 。用于解决的这个问题的方案是使用 Python 3.8 引入的海象计算符 `:=` 进行赋值

```Python
result = {
            key:value 
            for key in order 
            if value := func(stock.get(key,0))
        }
```

赋值表达式被我们写在了子表达式中，这是显然的。从推导表达式的执行流程我们不难想到子表达式会被先求值，若将赋值表达式写在 for 的前面，则子表达式中就会出现变量未定义引起的错误。而如果推导逻辑不带条件，而表示新值的部分使用了 `:=` 操作符，那么操作符左边的变量就会泄漏到包含这条推导语句的作用域中，与 for 循环中的循环变量类似

```python
foo = [1,2,3,4,5,6,7]
bar = [y := x+1 for x in foo]
print(f"The last one in bar is {y}")
for y in foo:
    pass
print(f"The last one in foo is {y}")
#The last one in bar is 8
#The last one in foo is 7
```

不过，在上面的代码中，推导语句中的 for 循环所使用的循环变量 ( x ) 不会泄露到外部作用域。为了避免循环变量的泄露，建议赋值表达式只出现在推导逻辑的条件之中

> 在最新的 Python 里，即便这样写变量似乎还是会泄漏到外部，参见 [PEP 572](https://peps.python.org/pep-0572/#why-not-use-a-sublocal-scope-and-prevent-namespace-pollution) 和[作者勘误](https://github.com/bslatkin/effectivepython/issues/83)
>

## 让函数返回迭代器而非直接返回列表

如果函数要返回的是包含了许多结果的序列，那么最简单的办法是将这些结果放到列表中，例如

```Python
def get_index(some_list) -> list:
    indexes = []
    for index , _ in enumerate(some_list):
        indexes.append(index)
    return indexes
```

使用生成器的写法是

```Python
def get_index(some_list) -> Generator[int,Any,None]:
    for index,_ in enumerate(some_list):
        yield index
```

相比于迭代列表等数据结构，迭代迭代器有着显著的优势，一是迭代器不会像列表一样占用宝贵的内存空间，这在列表很大的时候尤其重要，同时迭代器是惰性的，其中的代码不会立即执行，而是在需要的时候才执行，他不需要全部读取整个输入值，也不用一次星计算出所有的输出。与传统编程语言例如 C 语言那样的通过索引进行循环的方式相比，迭代器也不需要进行边界检查。这些特性为迭代器带来了优异的的性能表现。调用者唯一需要注意的是，迭代器是有状态的，这意味着同一迭代器不能重复使用

## 用生成器表达式改写数据量较大的列表推导

当直接使用列表推导表达式生成的列表可能会过大时，可以考虑使用生成器表达式来完成对应的任务。程序在对生成器表达式求值的时候，并不会直接构建出生成式描述的序列，而是生成一个迭代器，该迭代器会根据表达式中的逻辑生成对应值。生成器表达式的语法与列表推导式类似，只是生成器表达式会被写在圆括号内。唯一需要注意的是生成器表达式返回的迭代器是有状态的，不可重复使用

## 不要用 send 给生成器注入数据

Python 的迭代器支持 send 方法，这可以让迭代器变成双向通道。send 方法可以把参数发给迭代器，让它成为上一条 yield 表达式的求值结果，并获取迭代器下一个生成的值。另外一个内置函数 next 等价于 send(None) 。由于刚开始使用迭代器时它是从头执行的，并没有从某一条 yield 表达式开始执行，因此首次调用 send 方法时只能传 None ，否则程序会抛出异常。send 方法不适合与 yield from 表达式搭配起来使用，可能导致奇怪的结果，例如会让程序在本该输出有效值的时候输出 None 。一种更简单好用的方法是封装它，通过迭代器向组合起来的生成器主数据，这样迭代器可以来自任何地方，并且完全可以是动态的，不过这个方案有一个缺陷，就是必须假设负责输入的生成器绝对能保证线程安全，但有时我们不能保证这一点

## 不要通过 throw 变换生成器的状态

生成器生成的迭代器有着 throw 方法，可以往迭代器内注入异常，当迭代器开始迭代时，会在上一次执行后停留的 yield 表达式处抛出 throw 方法注入的异常。生成器函数可以用 try/except 复合语句把 yield 表达式包裹起来，如果函数上次执行到了这条表达式处，而这次即将继续执行时，发现外界通过 throw 方法给自己注入了异常，这个异常就会被 try 结构捕获，如果捕获之后不继续抛出异常，则生成器函数会和正常情况一样推进到下一条 yield 表达式

```Python
def foo():
    yield 1
    try:
        yield 2
    except Exception as e:
        print(f"{e}")
    else:
        yield 3
    yield 4

bar = foo()
print(next(bar))
print(next(bar))
print(bar.throw(Exception("Error!")))

# 1
# 2
# Error!
# 4   
```

但凡是需要用生成器和异常实现的功能，通常都可以改用异步机制或者可迭代的容器对象(也就是用类的 \_\_iter\_\_ 方法实现生成器，并专门提供一个方法让调用者触发这种特殊的状态变换逻辑)更好地实现。通过 throw 方法诸如一场会让代码变得难懂，因为我们往往需要用多层嵌套的模板结构来抛出并捕获这种异常。故最好不要通过 throw 方法变换生成器的状态

## 使用 itertools 拼装迭代器与生成器

Python 内置的 itertools 模块里有很多函数，可以用来安排迭代器之间的交互关系

### 连接多个迭代器

#### chain

chain 函数接收多个可迭代对象作为参数，并返回一个将它们从头到尾连成的迭代器

#### repeat

repeat 函数接收两个参数，可以生成一个将第一个参数重复生成第二个参数次数的迭代器，第二个参数为空时则默认无重复次数上限

#### cycle

cycle 函数接收一个可迭代参数，生成一个不断循环生成参数中各项元素的迭代器

#### tee

tee 函数可以将一个迭代器分裂成多个平行的迭代器，分裂出的个数由第二个参数指定

#### zip_longest

该函数与 Python 内置的 zip 函数类似，但它会在原迭代器长不够时用 fillvalue 参数的值填补提前耗尽的迭代器留下的空缺

### 过滤源迭代器中的元素

#### islice

islice 函数可以在不拷贝数据的前提下按照下标切割原迭代器，其使用方式与标准的序列切片及步进机制类似，即 islice(iterable,begin,end,step),当除迭代器外只提供一个参数时该参数表示切割的终点

#### takewhile

takewhile 函数接收一个函数和一个迭代器为参数，会一直从原迭代器中获取元素直到最新获取到的元素让提供的函数返回 False 为止。

#### dropwhile

与 takewhile 函数相反，dropwhile 函数会一直跳过源迭代器里的元素，直到某元素让提供的函数返回 True 为止，然后它会从这个地方开始取值

#### filterfalse

filerfalse 函数和内置的 filter 函数相反，它会逐个输出源迭代器里使得提供的函数返回 False 的元素

### 用源迭代器中的元素合成新元素

#### accumulate

accumulate 函数会从源迭代器中取出一个元素，并把已经累计的结果与这个元素一起传给表示累加逻辑的函数，然后输出那个函数的计算结果，并把结果当成新的累计值，默认累计逻辑为两值相加

#### product

product 会从一个或多个源迭代器里获取元素，并计算笛卡尔积，它可以取代多层嵌套的列表推导代码

#### permutations

permutations 函数会考虑源迭代器所能给出的全部元素，并逐个输出由其中的 N 个元素形成的每种有序排列方式，N由第二个参数指定

#### combinations

combinations 函数会考虑源迭代器所能给出的全部元素，并逐个输出由其中的 N 个元素形成的每种无序组合方式，N由第二个参数指定

#### combinations_with_replacement

该函数与 combinations 函数类似，但它允许同一个元素在组合里多次出现
