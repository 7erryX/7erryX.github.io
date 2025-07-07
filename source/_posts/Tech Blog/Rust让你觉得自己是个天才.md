---
title: (译)(中英对照) Rust 让你觉得自己是个天才
toc: true
categories: Tech Blog
thumbnail: images/Tech%20Blog/rust_lol.jpg
abbrlink: '86567545'
date: 2024-04-06 18:04:36
updated: 2024-04-06 18:04:36
---

当我写 Rust 时，我觉得自己像个天才。我稍后会告诉你为什么，但首先看一个简单的问题，这段代码正确吗？

When I write Rust , I feel like a genius . I'll tell you why in a moment , but first a simple question . Is this code correct ?

<!--more-->

```JavaScript
function add_one(n) {
    return n + 1;
}
```

emm ， 看情况。如果你或你的同时想要确保该函数能够始终正常工作，就必须添加大量样板代码：检查 n 的类型，在它不是数字的时候报错；确保 n 的大小以避免某种溢出；n 是否是负数或浮点数？它是否是按值传递而非按引用传递？我们是否获取了保护 n 所在共享内存的锁？

Well . It depends . If you or a colleague wanted to be totally sure this function could alway work , you'd have to add lots of boilerplate code :

- You'd check the type of n , erroring if it wasn't a number
- You'd make sure n wasn't so large that it caused some kind of overflow
- And what about negative numbers or floating point numbers
- Perhaps we'd ensure that n was passed by value not by reference or that we capture the lock on the part of shared memory that n was in

当然，大多数语言针对其中许多都有着合理的默认行为，但当你编写代码时，能否把这些规则与边界情况都记住？我们只是想要在一个数字上加一，怎能期望面对包括但不限于以上不确定性时在大脑中维持着整个语言的预设？我们需要一个符号以简介地囊括它们。Rust 在其丰富的类型系统中提供了这种表示方式，我们稍后再看。

Sure , most languages have sensible defaults for many of these , but do you have all these rules and edge cases in your memory as you're writing code ? All this uncertainly and we just added one to a number . How can we hope to keep a whole language's assumptions all in our heads ? We need a notation to concisely encapsulate all this . Rust provides this notation in the rich type system . We'll look at it in a moment .

众所周知， Rust 在 Stack OverFlow 的开发者最喜爱语言榜单中连续六年登顶。我认为编译器的反馈正是写 Rust 时的满足感的奥秘所在。这让我觉得自己是天才，我的代码可以一在生产环境中运行就正常工作！在告诉你为什么 Rust 让你觉得自己是个天才之前，让我向你展示其它语言是如何通过迫使你进入到被我称作“错误驱动”开发方式来让你感到笨拙的。

As many of you know , Rust has topped the Stack Overflow developer survey for most loved language 6 years in a row . Compiler feedback is the secret to the satisfaction of writing Rust , I think . It makes me feel like a genius . My code works first time when I run it on production . Before i tell you why Rust makes you feel like a genius , let me show you how other languages makes you feel stupid by forcing you into what I'll call Error Driven Development .

```JavaScript
let spam = ['cat','dog','mouse']
console.log(spam[6])

// no output,no errors, spam[6] is `undefined`
```

最糟糕的情况是没有报错。你运行了代码，而它没如你所愿地工作，也没报错。你不得不坐在那想到底是为什么你没得到错误信息。毕竟 JavaScript 肯定不会报告给你。如果没有注解，即使是 TypeScript 也无法帮到你

The worst case is no errors . You run the code and it doesn't do what you want , but there are also no errors . You just have to sit there and imagine why on earth you can't get your error ! Because JavaScript certainly not going to tell you . Without annotations , even TypeScript can't help you either .

与没有报错相比，糟糕的报错也会好上很多。让我们看看 Python 是如何处理的

Much better than no errors are bad errors . Let's look at how Python handles this .

```Python
spam = ['cat','dog','mouse']
print(spam[6])
```

Python error trace-back

```plaintext
Traceback (most recent call last):
  File "test.py", line 2, in <module>
    print(spam[6])
          ~~~~^^^
IndexError: list index out of range
```

结果没有你想的那么棒，Python 没有告诉我这里到底有什么问题，只是给了一些信息。这是大多数语言的典型特征。当然，只要你知道需要查找什么，是可以知道错误是 list 的索引超出了其上限。但这里有很多不足，哪个 list ，什么上限，第二行的哪个具体位置。动态类型语言的错误通常不怎么理想，这并不必然是因为编译器的作者在它身上下功夫，他们已经尽力而为了。如果你的类型系统是简单的，编译器显然不可能为你捕获那么多的错误。顺便一提，Python 看似发现了这个错误，但它没有。这个错误发生在运行时，已经被用户除法。在你运气好的时候，你的测试可能能够捕获到它

Not as well as you might think , it turns out : Python won't tell me exactly what's wrong here . It's only giving me some of the information . And this is typical with most languages . Sure , once you know what to look for you can see that a list index is out of bounds . But there's so much missing here . Which list , what bound , where even in line 2 is it ? Errors in dynamically typed languages are usually bad . And it's not necessarily because the compiler authors didn't put in the work . They're doing the best they can . If you have a simple type system , the compiler simply can't catch many errors for you . By the way , it might look like python has caught this error , but it actually didn't . Look again . This error happened at runtime . Your user has caught this error . If you're lucky , your tests might catch this error .

> 截止至今日，Python 对其错误提示进行了一定的改进，在原作者编写本文文案时，Python 还不会在错误部分下方添加 ~ ^ 等符号进行标记

这，是报错应有的样子

Here is hwo it should be .

```Rust
let spam = ["cat" , "dog" , "mouse"];
println!("{}",spam[6]);
```

Rust trace-back error

```plaintext
error: this operation will panic at runtime
 --> src/main.rs:2:19
  |
2 |     println!("{}",spam[6]);
  |                   ^^^^^^^ index out of bounds: the length is 3 but the index is 6
  |
  = note: `#[deny(unconditional_panic)]` on by default
```

Rust 的报错是我所见过的最漂亮的。看看它，有错误本身，值是什么，本不应超过 3 而实际上是 6 。我们不需要去记忆值是什么，编译器已经告诉了我们。Rust 的报错发生在编译时(广义的，即发生在开发者的开发环境中而非生产环境中)

Rust's error are the nicest I've ever seen . Just look at it : We have the error itself . What the value should be , no more than 3 , and what value actually was , 6 . We don't have to remember wht the value is , the compiler has told us . Rust's errors happen at compile time , which is a fancy way of saying they must happen on the developers machine , not on a server somewhere .

让我们再深入一些，比如说我想要在某个循环中打印某个数字以便调试

Let's get a little deeper . Say I want to print out a number inside a loop for debugging purpose .

```plaintext
error: format argument must be a string literal
  --> src/main.rs:10:14
   |
10 |     println!(n);
   |              ^
   |
help: you might be missing a string literal to format with
   |
10 |     println!("{}", n);
   |              +++++
```

但是，噢，就像在 C 语言中一样，数字需要一个格式化字符串才能打印出来。看看这个报错信息！你见过这么漂亮的东西吗？它不仅以易懂的语言告诉了我们问题是什么，还直观地指出了问题的确切位置，甚至还给出了修正它的建议！我想这就是为什么 Rust 被评为最受欢迎的语言。编译器就像一位驾校教练一样，慷慨地教导你如何在危险的公路上行驶。这一简单例子所展现出来的仍不是 Rust 的全部。它会以这样的方式手把手地帮助你安全驶过异步网络编程，多进程，channel 和锁。所有这些都能通过 Rust 的宏系统为所有人所用。第三方网络库与框架也提供了这般丰富的报错功能。慷慨、善良、周到的 Rust 开发者们告诉我们，那个很危险，用这个吧。

But whoops , like in C , numbers need a format string to be printed . Just look at this error message . Have you ever seen something so beautiful ? It's not only telling us the error in plain language , but visually pointing to exactly where the problem is , and then suggests what we should do to fix it ! I think this is why Rust has been voted most loved language . The compiler is like a driving instructor , gently coaching you on how to navigate the dangerous highway . This is another simple example , but the Rust compiler holds your hand in this way right through async network programing , multi-processing and through channels and locks and all this is available to anyone via the macro system , so that third party web libraries and frameworks have these rich error , too . The generous , kind , thoughtful Rust developers told us that it's dangerous out there , take this .

Rust 团队解决了我们在 C 中所面临的最困难的问题，即如何确保内存安全。他们采用了稍后会提到的“借用检查器”这一最坚决的方式解决了最困难的问题，而非用垃圾收集器作弊或留给开发者解决。通过与这种新的方式结合，这一解决方案能够轻易解决所有剩余问题。如果你要创造一个能详尽了解你的程序的内存的编译器，就必须先创造一个能完全理解你的代码的编译器。Rust 并不是什么只会在大学或只会被 Rust 黑魔法师使用的理论上的语言，它已经有了所有能够避免你犯错并在你违反规则时帮助你而应有的组件

The Rust team set out to solve the most difficult problem we face , in C , which is how to handle memory safely . They fixed it with the Borrow Checker , which I'll explain in a moment . Because they solved the most difficult problem in the hard way , not cheating with a garbage collector or leaving it up to developer , it was easy to use this solution to solve all the other problems , by hooking into this new way of programming . If you make a compiler that understands your program's memory exhaustively , then you have to made a compiler that understands your code exhaustively . And Rust isn't some theoretical language that is only used in university or by esoteric wizards . All the components are already here today to make a language that stops you making mistakes , and helps you if you break the rules .

我已经尽我所能地不提借用检查器了。不过好消息是它非常简单。并有着神奇的作用。借用检查器有两条规则

I've talked as long as I can without telling you about the Borrow Checker . The good news is that it's extremely simple . It's the effects that are profound . The Borrow Checker has two rules:

- 数据有一个所有者
   Data has one owner
- 数据可以被多个对象读取或被一个对象修改
   Data may have multiple readers or one writer

这就完了。这就是借用检查器的两条规则，它的所有行为都可以被这两条规则所解释。你可以把数据看作是一个变量，不过它实际上是变量所指向的目标

That's it . Those are the two rules of the borrow checker . All behavior can be explained by these two . You can think of data as a variable , though it's really the data that variable points to .

...

> 这里略去的是原作者对 Rust 的 Borrow Checker 机制的介绍，也就是针对所有权机制和引用机制的例子及其说明，实际上针对下面的讨论，理解此处列出的两条，即 Rust 中的数据自带 S 锁与 X 锁即可

这就是所有权与借用机制的底层工作方式。该系统被设计用于跟踪内存，并在不再使用时将其释放。但你可以基于这一系统为你的程序设计更复杂的不变性。让我们看一个实际的，由这一简单系统所产生的在较高层次上产生影响的例子

This is how ownership and borrowing work at a very low level . This system was designed to keep track of memory , and to be able to free it when it is no longer used . But you can use this system to design much more complex invariants for your programs ! Let's look at a practical , high-level example of the repercussions of this simple system .

>Do not communicate by sharing memory;
instead , share memory by communicating
> —— Effective Go

Go 团队为他们的语言采取了非常棒的设计，这是处理共享内存的正确方式，但他们没有真的阻止你共享内存，这就导致了问题。Rust 的所有权机制让我们可以轻易地把这一建议变成编译器检查的规则。在你理解了所有权之后，可以读一读这个

It's really nice that the Go team designed their language this way . It's the right way to handle shared memory . But they don't stop you sharing memory , which leads to problems . Rust's ownership made it easy to turn this recommendation into a compiler-checked rule . Now you understand ownership , I think you can read this .

```Rust
// Suppose channel: Channel<Vec<String>>

let mut uers = Vec::new();
// do some computation , maybe append some usernames

channel.send(users);
print_vec(&users);
```

Results in:

```plaintext
Error: use of moved value `vec`
```

我们创建了一个用户列表，并通过通道将其发送到了其它线程、进程或机器上。在我们发送之后，没人知道那里的数据会发生什么，哪怕是读取它都会是不安全的。尽管借用检查器本是为了保持内存安全而创建的，但它仍可以简单地用于创建编译时检查以确保安全的通道。接收数据的线程可能在这第一个线程运行的同时就修改它，所以 `print_vec` 处可能存在条件竞争。这种使用已被释放内存的 BUG 不需要进行测试就能够编译器发现并不让编译通过。在 Rust 社区，我们称之为无畏并发

We've created a list of users , and sent it down a channel to some other thread or process or machine . After we've sent it , who knows what will happen to the data in there . It is unsafe to even read the user list after we've sent it . The borrow checker , despite being created to keep memory safe , can be used trivially to create compile-time-checked guaranteed safe channels . The thread receiving users could modify it as this first thread continues running , so the call to print_vec could lead to race condition , or , for that matter , a use-after-free bug . You don't even need to test this code to find these race conditions . The Rust compiler won't let you compile . In the Rust community , we call this Fearless Concurrency .

在 Rust 中，Option 枚举类型无处不在，就像人生中你无法心想事成那样

In Rust , Options are everywhere . Because , as in life , you can't always get what you want .

WAYS TO TEST NULL IN JS

```JavaScript
typeof null           // Object
typeof undefined      // undefined
null === undefined    // false
null == undefined     // true
null === null         // true
null == null          // true
!null                 // true
isNan(l + null)       // false
isNan(l + undefined)  // true
```

Who is flying this thing ?

很难有人能记住 JS 这些复杂而残酷的判断 NULL 的方式。别让你的人生也这样。显然，除非我们需要一个函数不返回任何内容，不然 null 一直都是一个令人头疼的问题

No one remembers all this . It's byzantine and cruel . Your life doesn't have to be this way . Everyone agrees that nulls are bad until it's time to return nothing from a function .

> NULL 的发明者痛恨甚至忏悔自己发明了 NULL ，但这一重要概念又不得不使用。NULL 相关的处理一直都是一件令人头疼的事，除非你用 Rust :P

```Rust
enum Option<T> { // T can contain any type of value
   Some(T),
   None
}

let possibly_a_number = Some(l);

possibly_a_number.map(|n| n + 1).unwrap_or(0); // 2
```

将一个类型包裹在 Option 中清楚地向程序员，IDE 和编译器表明一个值可能为空，不是可能为 0 或空字符串，就是什么都没有。表示什么都没有的这个概念有着很大的用处。Rust 会要求你处理它。同时，在 Rust 中，就像 Option 是 null 的解决方案，Result 是 error 的解决方案。在 Rust 中，error 是值。你可能在其它语言中也见到过这种情况，例如在 Go 中

Wrapping a type in an Option signifies clearly to the programmer , the IDE , and the compiler , that this value might be something , or it might be nothing . It's not that it's zero or an empty string , it might just be nothing . Nothing , the value is useful , and the Rust compiler will force you to deal with it . Just as options transform nulls in Rust , Results transform errors . In Rust , errors are values . You might have seen this in other languages , like here , in Go .

```Go
f , err := os.Open("filename.ext")
if err != nil {
   log.Fatal(err)
}
```

这里的 err 就包含了错误，你必须在访问 f 前检查它。但 Go 没有阻止你忽略这个错误，事实上它总是被忽略 ( err 的位置被写成 _ ) 。Rust 在 Result 枚举类型中对其进行了捕获，这样编译器就能强制你去处理错误。

Here err contains the error , and you must check it before accessing f . But there's nothing stopping you ignoring the error , in fact this happens all the time . Rust captures this pattern in the Result type , so that the compiler can force you to handle the error .

以上提到的内容没有运行时的开销(我们称之为零成本抽象，例如下文给出的例子)。丰富的类型层次不会被植入到用户的电脑中。这个可选函数链完美地展开到没有错误的安全的值的过程不会运行在用户的手机上。甚至借用检查其在你把它编译到 WebAssembly 中运行的 GPU 加速的 DOOM 副本中时，也不会将自己在指令中写出来

Nearly all of this that I've shown you doesn't exist at run time . Your rich type hierarchy doesn't sneak no to your customers laptop . The chain of optional functions resolving down nicely into a safe value with no errors doesn't run on your user's phone . Even the borrow checker writes itself out of the code as you compile it into your gpu-accelerated doom clone running in web assembly .

Rust 惊人的丰富性和复杂性只存在于编译时，在你通过这些手段告诉编译器世界的运行方式之后，编译器会详尽地证实没有任何东西能违背你写进代码中的约束。如果一切顺利无误，所有这些信息都会在被编译成低级别地汇编时从代码中剥离掉。运行时不存在类型的概念，正如实际的程序执行时那样。我们发明了类型，它们就像逻辑严明的文学作品，只存在于我们的脑海中而非现实里。CPU 不知道什么是类型，只知道二进制数据与运算符。下面的两个代码块都会编译为相同的汇编指令

Rust's incredible richness and complexity only exists at compile time , after you have told the compiler how the world works by notating your code with all this markup , the compiler exhaustively proves that nothing could violate the contracts you have put into code . If everything checks out , all this information is stripped out of the code as it is compiled into low-level assembly . Types don't exist at runtime . And this is actually the way the world works . We invented types . They're like a logical fiction . They only exist in our minds . CPUs don't know anything about types . They only know 1s and 0s and a few operators . Both of these two code blocks compile down to exactly the same assembly .

```Rust
pub fn sum_loops(n: i32) -> i32 {
   let mut sum = 0;
   for i in 1..n {
      sum += i;
   }
   sum
}
```

IS EQUIVILANT TO

```Rust
pub fn sum_iterators(n: i32) -> i32 {
   (1..n).sum()
}
```

compile down to

```assembly
sum:
   xor   eax , eax
   cmp   edi , 2
   jl    .LBB0_2
   lea   eax , [rdi - 2]
   lea   ecx , [rdi - 3]
   imul  rcx , rax
   shr   rcx
   lea   eax , [rcx + 2*rdi]
   add   eax , -3
.LBB0_2:
   ret
```

在 Rust 中，只要你肯手动优化，你的代码可以变得更高级也更快。Rust 编译器会自动为我们验证包括但不限于这些内容：

Your code can be both HIGHER LEVEL and FASTER in rust than it could if you had hand-optimized it . Here is a non-exhaustive selection of some of the things the Rust compiler can validate for us for free .

- 所有的 AWS
   All of AWS
- 所有的 Windows API
   All of the MS Windows API
- WASM
   WebAssembly
- 迭代器，Option 与 Result 枚举类型
   Iterators,Options and Results
- 内存安全
   Memory safety

在我的上一个视频中我告诉过你，在 Rust 中，你向编译器描述这个世界是如何运作的，然后它会让你对其中的约束负责。丰富的类型系统就是你书写约束的方式，建立在借用检查器之上的编译器让你对其负责。这都意味着你一部署你的代码，它可以完美的工作，这让你感觉自己是个天才

In my last video I told you that in Rust , you tell the compiler how the world works , and it will hold you and everyone who contributes to your code accountable to the contract you have written . The rich type system is how you write the contract , the compiler built on the borrow checker then holds you to it . This all means your code works perfectly , the first time you deploy it , and makes you feel like a genius .

## Reference

[Rust makes you feel like a GENIUS](https://www.youtube.com/watch?v=0rJ94rbdteE)
