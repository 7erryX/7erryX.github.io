---
title: To Be Pythonic Ⅱ 列表与字典
toc: true
categories: Tech Blog
abbrlink: 2754b39a
date: 2024-01-31 19:35:49
updated: 2024-01-31 19:35:49
---

list 和 dict 作为用途非常广泛的数据结构，在使用了 Python 提供的特殊语法与模块后，可以用清晰的代码实现出很多简单的 array 、 vector 与 hash table 所不能比的强大的功能

<!--more-->

## 对序列做切片

Python 中所有实现了 __getitem__ 与 __setitem__ 这两个特殊方法的类都能产生切片。Python 内置的 list、str 与 bytes是这种类的典型。最基本的写法是用`list[start:end]`这一形式产生从 start 到 end 处但不包括 end 处元素的切片。如果从头开始产生切片，或者切片一直取到序列末尾，则冒号左边的 0 和右边的列表长度值都应该省略使其看起来更清晰

切片可以出现在赋值符号左侧，与 unpacking 形式的赋值不同，对于切片的复制两侧的元素个数可以不同，也就是说

```Python
a,b = c[x:x+2] # ✔
a,b = c[x:x+3] # ❌
```

对于 unpacking 来说只有第一种写法才是合法的，但如果是切片

```Python
# b = a[:3]
b = [1,2,3,4]
b = [1,2]
```

这两种写法都是合法的，此时的赋值实际表示用右侧的元素替换原列表中位于这个位置范围的元素，在等号左右元素数量不同时会导致原本的列表的长度发生改变。

## 停止在切片中同时指定起始下标于步进

除了最基本的切片写法，Python 还有一种特殊的步进切片形式`list[start:end:stride]`, stride 是步长，即每多少个取一个元素作为切片成员。带有步进的切片经常会引发意外的效果。例如 Python 中有一个常见的技巧，以 -1 为步长对 bytes 类型的字符串做切片就能将字符串翻转过来，但若该字符串为 UTF-8 标准的字节数据，则会导致 UnicodeDecodeError 。同时使用起止下标和步进会让切片会增大阅读程序时的思考负担。如果要使用步进，最好省略起止下标并采用正数作为步长，或者使用 itertools 模块内的 islice 方法完成对应任务

## 通过带星号的 unpacking 操作捕获多个元素

进行 unpacking 操作时必须提前确定需要拆解的序列长度。当存在不确定序列长度的情况是，可以通过带星号的表达式( starred expression)解决。这种表达式可以囊括所有剩余元素

```Python
list_case = [1,2,3,4,5]

first , *others , last = list_case
print(first,others,last)
#1 [2, 3, 4] 5

*others , sub_last , last = list_cae
print(others,sub_last,last)
#[1, 2, 3] 4 5

first , second , *others = list_case
print(first,second,others)
#1 2 [3, 4, 5]

first , *others , last = [1,2]
print(first,others,last)
#1,2,[]
```

星号表达式需要搭配其他变量一同使用，以及对于单层结构来说，同一级只能使用一个带星号的表达式。也就是说，下面的写法是不合法的

```Python
*others = list_case
first , *others1 , *others2 , last = [1,2,3,4]
```

带有星号的 unpacking 操作也可以作用于迭代器，可以使用带星号的表达式形成列表以囊括迭代器能够产生的其余元素

## 用 sort 方法的 key 参数来表示复杂的排序逻辑

list 对象具有 sort 方法，可以使用多种方式给 list 实例中的元素排序。在默认情况下，sort 方法按照自然升序排列列表内的元素。凡是具备自然顺序的 Python 内置类型都可以用 sort 方法排序，例如字符串，浮点数等。但在更常见的情形下，很多对象需要在不同的情况下按照不同的标准进行排序，此时自然排序并不一定能很好的达到开发者的目的。 sort 方法可以使用 key 参数实现复杂的排序逻辑。key 参数可以接收函数作为参数，这个函数需要带有一个参数，并返回一个可以进行比较的值，sort 方法会根据函数的返回值为对象进行排序

```Python
class Obj(object):
    def __init__(self,a,b,c):
        self.a = a
        self.b = b
        self.c = c

    def __repr__(self) -> str:
        return f"Obj: a:{self.a} b:{self.b} c:{self.c}"

obj_list = [
    Obj(2,1,"bar"),
    Obj(1,1,'foo')
]
obj_list.sort(key=lambda x:x.a)
print(obj_list)
obj_list.sort(key=lambda x:x.c)
print(obj_list)
obj_list.sort(key=lambda x:(x.b,x.a))
print(obj_list)

#[Obj: a:1 b:1 c:foo, Obj: a:2 b:1 c:bar]
#[Obj: a:2 b:1 c:bar, Obj: a:1 b:1 c:foo]
#[Obj: a:1 b:1 c:foo, Obj: a:2 b:1 c:bar]
```

我们需要以哪一个属性作为排序依据，传给 key 的函数就返回对象实例的哪一个属性。当需要根据多个属性的值作为排序依据时，函数可以返回一个对应的元组，利用元组若首个元素相等则比较第二个元素，仍然相等则继续往后比较的特性比较不同对象

## 不要过分依赖给字典添加键值对时所用的排序

在 Python 3.5 及其以前的版本中，字典类型通过哈希表算法实现，该算法通过内置的 hash 函数与一个随机的，在每次启动 Python 解释器时确定的种子数运行。这样的机制导致键值对在字典中的存放顺序不一定与添加时的顺序相同并且每次运行程序存放顺序都可能不同。但在 Python 3.6开始，字典会保留这些键值对在添加时所用的顺序，Python 3.7 的语言规范确立了这一规则。虽然内置的 collections 模块提供了这种保留了插入顺序的字典 OrderedDict ， 但二者性能上有着很大的区别，在此就不过多赘述。由于这一语言规范仍相对较新，最好不要太过分依赖给字典添加键值对时所用的顺序

## 用 get 处理键不再字典中的情况，不要使用 in 与 keyError

字典的内容常常发生变动，所以完全有可能会出现这样一种应用情景，我们不确定想要访问的键值对是否还在字典中。解决这一问题的常见的写法是

```Python
# Use in keyword
if key in dictionary:
    do(dictionary[key])
else:
    do_else()

# Use KeyError exception
try:
    do(dictionary[key])
except KeyError:
    do_else()
```

Python 内置的字典类型提供了 get 方法用以更简洁地完成这个任务。get 方法的第一个参数是需要访问的键，第二个参数是该键不存在时的返回值，例如

```Python
dictionary.get(key,0)
```

## 用 defaultdict 处理内部状态中确实的元素而非 setdefault

字典还提供了 setdefault 方法，它接收两个参数，第一个参数是想要查询的键，第二个参数是一个默认值。当字典中存在这个键时，方法返回对应的值，否则将默认值与键关联起来并插入到字典中。但在 setdefault 适用的解决问题方式的范围内，Python 内置的 collections 模块提供了 defaultdict 类，它能够轻松地实现在需要查找的键缺失时自动添加该键与其对应默认值的业务逻辑，更好地解决对应问题。在绝大多数情况下，用 defaultdict 处理内部状态中确实的元素而非 setdefault 往往是更好的方案，对于没法用 defaultdict 解决的问题，我们也完全由其他的 Python 工具对其进行处理

## 用 __missing__ 构造依赖键的默认值

对于 setdefault 和 defaultdict 都无法处理的任务，Python 内置了一种解决方案，可以通过继承 dict 类型并实现 __missing__ 方法解决这一问题。

```Python
class Obj(dict):
    def __missing__(self,key):
        value = ...
        self[key] = value
        return value
```

当访问 dictionary[key] 时，如果 dictionary 字典中没有对应的键，__missing__ 方法会将默认值与键配对插入到字典中，并返回该值。(类似的机制还体现在 __getattr__ 方法中)
