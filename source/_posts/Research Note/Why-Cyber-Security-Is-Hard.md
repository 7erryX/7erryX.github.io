---
title: Why Cyber Security Is Hard
toc: true
date: 2024-12-25 18:52:35
updated: 2024-12-25 18:52:35
categories: Research Note
---

林志强教授就职于俄亥俄州立大学，是网络安全研究领域知名学者。他在 2021 年的 OSU Cybersecurity Days 论坛上作出的演讲深入浅出地讨论了网络安全研究领域中的诸多基本问题，令本人受益匪浅。

翻译如若不周，欢迎指正！

[烤肉视频](https://www.bilibili.com/video/BV14MCPYKE7o)已上传至 Bilibili

<!--more-->

## 讲稿

> Hello! Welcome to The Community Forum Session at the Cybersecurity Days. My name is Zhiqiang Lin. I'm a Professor of Computer Science & Engineering at the Ohio State University. I do research on computer security with a particular focus on software security such as vulnerability discovery and software hardening.

你好，欢迎参加[网络安全日](https://it.osu.edu/security/cybersecurity-days)社区论坛会议。我叫[林志强](https://zhiqlin.github.io/)。我是俄亥俄州立大学计算机科学与工程系的教授，从事计算机安全研究，且特别关注例如漏洞发现与软件加固在内的软件安全技术。

> Today I'm going to talk about a topic which you may have already thought about namely **Why Cybersecurity Is Hard**. The reason of why I would like to give this talk is, year 2021 is really a bad year for cybersecurity. So far we have heard numerous cyber attacks and this includes attacks against SolarWinds, Florida Water Plant, the Microsoft Exchange Server and the Colonial Pipeline. These cyber attacks have caused significant damages to our economy and the society.

今天我要讨论一个你可能已经思考过的话题————为什么网络安全如此困难？我想要讨论它的原因在于，2021 年对网络安全来说是非常糟糕的一年。到目前为止，我们已经听闻了无数的包括但不限于针对 SolarWinds、Florida Water Plant、Microsoft Exchange Server 与 Colonial Pipeline 等目标展开的网络攻击事件，它们对人们的经济和社会造成了重大危害。

> Then, I'm sure you must have started to wonder "Why there are so many cyber attacks?" or "Why Can Computers Be Attacked So Easily?". In order to answer this question, let me ask a slightly different question, "Why Can Airplanes Be Attacked So Easily?". Since like computers, airplane is also our human made artifact. But I know this may trigger you to easily think about the 911 attack and also the airport security such as passenger screening by the TSA which may be more on the management side. So let me focus more on the technology side by changing this question to "Why Can Airplanes Not Be Crashed So Often?".

那么，我相信你一定已经开始思考为什么会有这么多网络攻击或为什么计算机可以如此轻易地被攻击。为了回答这个问题，我想要先问一个稍微不同的问题，为什么飞机可以如此轻易地被攻击？因为飞机也和计算机一样是人类的造物。但我知道这可能很容易让你想到 911 袭击和例如安检之类的机场安全这些更多地涉及管理方面的思考方向，因此让我修改这个问题为，为什么飞机不经常坠毁，以更好地专注在技术领域的讨论。

> Well, we all know airplane is extremely complicated. To build an airplane, it requires tremendous amount of science and engineering knowledge from such as math, physics, aerodynamics, control theory, autopilot, etc. But if you look at the number of the accidents in the past fifteen years in airline industry, you will notice that the rate of crash is extremely low. It's almost like one among one million. So why we can achieve such a high reliability when building an airplane? Why we cannot build crash resilient computers?

首先，我们都知道飞机极其复杂。制造一架飞机需要大量的科学与工程知识，例如数学、物理、空气动力学，控制理论，自动驾驶等。但如果你去查看过去十五年航空业的事故数量，将会发现飞机的坠毁率极低，几乎是百万分之一。那究竟是为什么人们能做到在制造飞机时实现如此高的而可靠性却不能制造能够抗破坏的计算机呢？

> Then let's look at the aircraft design. An airplane has many key components such as the engines, the wings, the stabilizers and so on. To make aircraft resilient to crash, it has included many of the best engineering principles and techniques, from fault-avoidance by use such as formal methods, to fault-tolerance by using such as redundancy design, single version, multi version, CRC, Hamming code and multiple-voting, etc. To get a sense on what is fault-tolerance, let's look at one of the fault-tolerant techniques CRC to see how it works. CRC stands for Cyclic Redundancy Check. You can think about it as a checksum of a message. Here is how it works.

接下来，让我们看看飞机的设计。一架飞机有着诸多关键的组件，例如引擎、机翼、稳定器等。为了避免飞机坠毁，它包含了从故障避免到故障容忍的许多最佳工程原则与技术，例如使用形式化方法实现故障避免，使用冗余设计、单/多版本、CRC、汉明码和多重投票等手段进行实现 故障容忍。为了让大家简单理解什么是故障容忍，让我们看向其中一种技术，CRC，以了解它是如何工作的。CRC 代表循环冗余校验，你可以将其视作一种消息校验和。它是这样工作的：

> Assume Alice wants to send a message to Bob. During the transmission of the message, there could be cosmic ray, air molecules, etc that can cause bit flips of the message. Therefore, when Bob receives the message, it can be a completely different one because of the bit flips. To detect such a bit flip, CRC is introduced. Now to transmit our message, Alice will first compute the CRC of the message and attach the CRC with the message and send it to Bob. Bob will also then verify whether the CRC is consistent with the message, if not, bit flips are detected.

假设 Alice 想向 Bob 发送一条消息，在消息的传输过程中，可能会有宇宙射线或空气分子之类的因素导致消息的比特位发生翻转。因此，当 Bob 收到消息时，收到的消息可能会因为位翻转而变得完全不同。为了检测这种位翻转，人们引入了 CRC。现在为了传输消息，Alice 将首先计算消息的 CRC，并将 CRC 附加到消息上一同发送给 Bob。Bob 随后将验证 CRC 是否与消息一致，如果不一致即可检测到位翻转。

> Then, is CRC secure against attacks? Well, the answer is no, since CRC is not designed for security but rather for reliability because fundamentally attackers can intercept the message, modify the message from m to m prime and regenerate a new CRC for m prime. And then when Bob verifies, the CRC will still be consistent with the modified message m prime.

那么，在遭受到攻击时，CRC 安全吗？好吧，答案是否定的，因为 CRC 不是为安全性而是为可靠性设计的。显然攻击方能够拦截消息，修改它并重新生成 CRC。当 Bob 收到消息并验证时，CRC 依然与修改后的消息一致。

> Then how we solve this security problem? Well, the way to defeat attackers' modification is to use message syndication code namely Mac, in which our cryptographic key is first shared between Alice and Bob. Then when sending the message from Alice, it will use both the message and the cryptographic key together to generate our Mac. Therefore, attackers cannot modify the Mac because they do not have the key. But Bob Can still verify the message because he has the key.

那么，人们是如何解决这一安全问题的？避免攻击方修改的方法是使用叫做 Mac 的消息认证码，其中密钥在 Alice 和 Bob 之间共享。这样当 Alice 发送消息时会基于消息内容和密钥生成 Mac。攻击方无法在没有密钥的情况下修改 Mac 而 Bob 却仍然可以验证消息，因为他有密钥。

> So now you can see clearly. The essence of reliability is to deal with the errors from the natural environment such as radiations, whereas the essence of cybersecurity is to deal with the intelligent adversary. So cybersecurity is an inherently adversarial discipline. There are always two parties, offenders and defenders. And they always play the games by trying to exploit the assumptions and weaknesses of the other in order to win the game. Unfortunately the game is completely unfair. Because it is completely asymmetric as defenders. They must defend against everyone ability, both known and unknown through every vector and must do so perfectly. But offenders need only one tiny mistake from the defenders in order to win the game.

因此，现在你可以清楚地知道，可靠性的本质是处理来自自然环境的错误，例如辐射，而网络安全的本质是提防聪明的敌手。因此网络安全本质上是一门对抗性的学科。总是有两方，攻击方与防守方，在试图利用对方的假设与弱点不断地进行博弈以在攻防对抗中取得胜利。不幸的是攻防对抗完全不公平，因为它完全不对称。防守方必须防御所有方位的攻击，无论其已知还是未知，并且需要防御得尽善尽美，反观攻击方只需要能抓到防守方犯下的一个微小的错误便能取胜。

> Defenders' strategies chiefly include making it expensive for offenders to attack for example by adding more layers of defenses. And whereas offenders' strategists are keeping searching for just one vulnerability. There are also dilemmas in defenders, you cannot defend against their attacks which you don't know exist. For instance, to fight for covid-19, we need to first develop the Vaccine based on the symptoms from the infected patients. Then, when viruses comes again, our immune system can stop its intrusions. If there are other new viruses such as the beta variant, we have to repeat this process again. In cybersecurity, it works the same and you cannot defeat their attacks you don't know exist.

防守方的策略主要是提高攻击的成本，例如增加防御的层数，而攻击方的策略是持续搜寻目标的某一漏洞。防守方还面临着一些困境————你无法防御你不知道的攻击。例如为了抵御 COVID-19 ，我们需要先基于感染患者的症状研发并注射疫苗才能让我们的免疫系统在病毒出现时阻止它的入侵。如果出现了新的病毒例如 β-变体，我们则必须先重复这一过程。对于网络安全也同理，你无法防御你不知道其存在的攻击。

> I have introduced how offenders and defenders play the game. Let's zoom in to say who are the offenders, what are the motivations and how powerful are they. There could be various offenders. This includes script kiddies, hacktivist, insiders, cyber criminals and even state sponsored attackers, who have unlimited resources. They are motivated for various reasons such as financial gain, intellectual property, business competition, cyber warfare, politics or social gain, etc. They are extremely powerful, and they can use all the tools available today such as cryptography, AI, automation and even quantum computers when they come out. I want to particularly emphasize that the offenders are both humans and machines. We know exactly their strength such as humans are really good at intuition, abstraction and creativity and machines are good at brute force, precision, and they can be scaled massively. And a machine never feels tired, they can easily perform sophisticated tasks and they can be easily replicated and they have our forever memory. So it is really hard to defeat such types of offenders.

我已经介绍了攻守双方是如何博弈的。让我们更进一步地讨论攻击方有哪些，有着怎样的动机以及有多么危险。攻击方的画像多种多样，包括但不限于脚本小子、黑客行为主义者、业内人士、网络罪犯甚至是有无限资源的政府资助的攻击方。它们的动机多种多样，可能是为了经济利益、知识产权、商业竞争、网络战、政治或社会利益等。它们非常危险且掌握着如今所有可用的密码学、人工智能、自动化甚至未来的量子计算机在内的各种工具。我想要特别强调的是，攻击方既指代人类也指代机器。我们熟知它们各自的优势，例如人类擅长直觉、抽象和创造，而机器擅长暴力破解与要求精确和准确度的工作并且可以大规模扩展。机器永远也不会感到疲惫，能够轻松地执行复杂的任务，拥有着永久的记忆甚至还能被轻易地复制。击败这样的攻击方当真是一件非常困难的事。

> In order to win the game, defenders have to learn a lot of knowledge. This includes from fundamental theory such as Game theory, access control and assurance, to computer assistance knowledge such as operating systems security, software security, network security, physical layer security, to various application domains such as mobile, cloud, Edge, IoT to various techniques such as vulnerability analysis, fuzzing, reverse engineering and data analytics to even human factors such as social engineering and risk management. So it is really complicated

为了在攻防对抗中取得胜利，防守方必须学习非常多的知识，包括：

- 基础理论例如博弈论，访问控制
- 计算机辅助知识例如操作系统安全，软件安全，网络安全，物理层安全
- 应用领域知识例如移动，云，边缘，物联网
- 各种技术知识例如漏洞分析，模糊测试，逆向工程，数据分析
- 甚至还有人类因素方面的知识例如社会工程和风险管理

它真的很复杂。

> Why Does Cybersecurity Become Harder and Harder? Why year 2021 is such a bad year for cyber security? Well, this lies in the Dilemma between Isolation and Convenience. Let's look at the history of cyber evolution to understand this Dilemma. In the early days, computers were mostly built for single users or collected with trusted users. However, when Internet was born computers started to be connected with the untrusted ones in the Internet. Then later, when moving to the mobile era, more and more devices such as even your phones and tablets are collected. Today we are in the era of IoT, remaining computing devices including even our cars are connected to the Internet. You can also see that our trust paradigm has evolved from earlier trusting everything to trust nothing, which leads to the zero trust, an extremely popular concept in the security industry today.

为什么网络安全在变得越来越难，为什么 2021 年的网络安全会如此糟糕？其原因在于隔离性与便利性之间的两难困境。让我们通过观察网络空间的进化史来理解这一困境。早期，计算机主要是为了单用户或受信任用户构建的。然而当互联网诞生后，计算机开始与互联网中那些未被信任的用户连接。再后来，当进入到移动互联网的时代，越来越多的设备例如手机与平板电脑都被接入到了互联网中。现在，我们身处物联网的时代，其余的计算设备例如车辆都被接入到了互联网。可以发现我们的信任范式发生了进化，从早期的信任一切进化到了一切不信，后者导向了零信任这一当今安全行业中非常流行的概念。

> In the zero trust architecture, devices today should not be trusted by default even if they are connected to our managed corporate network such as the corporate LAN and even if they were previously verified. Let's also look at why we have to do this. One dimension to look at is their attack surface. This is how it looks like today. You can see many of your home devices such as your cameras, your locks, your TVs are connected to the Internet. Critical infrastructures such as power plants, smart grids, hospitals are connected to the Internet as well. Certainly, given such a large attack surface, it will be easier for attackers to find one single vulnerability and attack these systems. That is why it is not a surprise for a water plant to be attacked this year. You can imagine many other cyber attacks will happen.

如今在零信任架构中，设备默认不被信任，哪怕它们连接到了我们管理的公共网路中例如公共的局域网甚至哪怕它们此前已被验证。让我们看看为什么不得不这样做。我们需要考虑的第一个维度是攻击面。你可以看到你的摄像头、门锁、电视都连接到了互联网。那些关键基础设施例如电厂、智能电网和医院也都连接到了互联网。当然，考虑到如此大的攻击面，攻击方更容易找到用于攻击这些系统的某一漏洞。这就是为什么今年水厂被攻击并不令人惊讶，不难想象还会有许多其它的网络攻击将会发生。

> What have defenders been working on over the years, are we getting better at defending against cyber attacks? In the rest of my talk, I would like to briefly talk about the following four directions, Inventing isolation primitives, Developing memory safe programming languages, Formal revocation and lastly, using AI for cybersecurity.

这些年来防守方们都做了哪些工作，是否能够更好的防御网络攻击？在我的演讲的剩余部分，我想简要谈谈以下四个方面

- 发明隔离原语
- 开发内存安全编程语言
- 形式化验证
- 为网络安全使用 AI

> The first one isolation, I have talked about the dilemma between isolation and convenience. Because more devices are connected to the Internet for our conveniences, it has huge security problems. But in order to achieve security we have to use isolation. Professor Gene Spafford once said "The only system which is truly secure is one which is switched off and unplugged, locked in a titanium land safe, buried in a concrete bunker and is surrounded by nerve gas and very highly paid armed guards". But we also know such truly secure computers are useless. Therefore over the years, security community has developed numerous isolation primitives to achieve the balance between convenience and security.

针对第一点，隔离技术，我已经讨论了隔离性与便利性之间的两难困境。由于更多的设备出于便利性的目的连接到了互联网上，自然也出现了巨大的安全问题。但我们必须为了保证安全性而使用隔离技术。Gene Spafford 教授曾说过：“唯一真正安全的系统是断电拔插头后锁在钛制保险箱里被埋在充满神经毒气的重兵把守的混凝土掩体中的系统”。但我们也知道这种真正安全的计算机是无用的。因此，多年来，安全社区开发了许多的隔离原语，以达成便利性与安全性之间的某种平衡。

> This includes, from virtual memory, to ring protection, to virtualization, to https, which is a cryptography based isolation, Arm TrustZone, Intel VT, AMD-V to recently hardware-based sandboxes such as Intel SGX, AMD SEV to even Intel TME and MKTME, which are not market available at this moment. So here is how it looks like in today's computer. It has many software and hardware building isolations. From physical layer to virtual machine monitor layer by using such as MPX, Intel VT or AMD SEV, to OS layer such as the Ring architecture and virtual memory, to application layer such as Intel SGX and encryptions. Meanwhile, When computers communicate with each other, they will use encrypted channels which is a very strong isolation primitive

这包括从虚拟内存，到环形保护，到虚拟化，到 HTTPS（一种基于密码学的隔离），到 Arm TrustZone，Intel VT，AMD-V 到最近的基于如 Intel SGX，AMD SEV 甚至目前未上市的 Intel TME 和 MKTME 这样的基于硬件的沙箱技术。它有许多软件和硬件构建的隔离，从物理层到虚拟机监控层到 OS 层再到应用层。同时，当计算机彼此通信时，它们将使用加密通道这一非常强大的隔离原语。

> The second direction I want to talk about is to develop memory safe programming languages. We know today many of our systems software are developed by memory unsafe languages such as C and C++. Unfortunately, programmers when using such languages can easily introduce buffer overflow vulnerabilities which allow attackers to control critical data structures such as the return addresses in the stack which can further lead to attacks such as control flow hijacking.

我想谈的第二个方向是开发内存安全编程语言。我们知道今天许多系统软件是使用诸如 C 和 C++ 这样的内存不安全的语言开发的。不幸的是，程序员们在使用这样的语言时很容易引入缓冲区溢出漏洞。这允许攻击方控制关键数据结构，例如栈中的返回地址，进而导致控制流劫持之类的攻击。

> In fact, there is a heated arm race between buffer attacks and defenses. Let me dive into deeper off this arm race to see clearly how offenders and defenders play the security game. The first few buffer flow attacks use code injection in which attackers directly overflow the buffer instead with injected shell and execute them in the stack. To defeat code injection attacks, defenders then proposed canary and Data Execution Prevention namely DEP. Attackers then proposed ret2libc attack in which attackers could reuse by reusing the address in the standard library to create the shellcode instead of directly inject them. In response to this attack, defenders then proposed address space layout randomization namely ASLR. Later, in 2005 there was another code reuse attack called borrowed code chunk attack and in the same year there is a new defense called control flow integrity or CFI to defeat attack that violates the intended program control flow. Then in 2007, the very famous ROP attack was proposed followed by Q-ROP in 2011, Then there was the defense in 2012 to randomize the addresses of both standard libraries and main executables. In 2013, There was the JIT ROP and also BinCFI defense. In 2014, there was the BROP and Forward-Edge CFI. In 2015, there was the Microsoft control flow guard from visual studio. In 2016, there was data oriented programming as well as runtime ASLR. In 2017, there was the address oblivious code reuse and the defense of Intel CET and ARM pointer authentication code. Most recently, there were other new attacks and defenses as well.

事实上，缓冲区溢出的攻防之间有着一场激烈的军备竞赛。让我深入探讨这场军备竞赛以看清攻击方与防守方之间是如何进行安全博弈的。最初的一些缓冲区溢出攻击使用代码注入技术，攻击方直接溢出缓冲区并在栈中执行注入的 shellcode。为了避免代码注入攻击，防守方提出了 Canary 与 DEP/NX 技术。随后攻击方提出了 ret2libc 攻击，通过复用标准库中的地址创建 shellcode 而非直接注入它们。为了应对这种攻击，防守方提出了内存地址空间随机化技术即 ASLR。2005 年出现了另一种名为借用代码块攻击的代码复用攻击，同年也出现了一种新的防御技术叫做控制流完整性检验或者说 CFI 技术以防止违背预期程序执行流的攻击。随后，非常著名的 ROP 攻击技术在 2007 年被提出，紧跟其后的是 2011 年提出的 Q-ROP。之后的 2012 年出现了同时随机化标准库与主要代码内存地址的防御技术。2013 年则出现了 JIT ROP 攻击与 BinCFI 防御技术。2014 年出现了 BROP 攻击与 Forward-Edge CFI 防御技术。2015 年出现了自 Visual Studio 而来的 Microsoft CFG 防御技术。2016 年 DOP 攻击与运行时 ASLR 防御技术问世。2017 年出现了地址无关代码复用攻击，Intel CET 防御与 ARM PAC 防御技术。以及最近也有着其它新的攻击和防御技术出现。

> I have to emphasize that this is by no means our complete list. There are many other attacks and defenses not listed here. But the key point I want to show you here is that this arm race started from early code injection attacks for attackers with ASLR and DEP from defenders and then code reuse attacks such as ROP and JIT-ROP to control for integrity defense which have been implemented in modern hardware such as the pointer authentication code. However, we cannot have this unrest forever. We need memory safe programming languages.

我必须强调，这绝不是我们的完整列表，其中还有许多其它攻击与防御技术未列出。但我想向你展示的关键在于，这场军备竞赛始于早期攻击方的代码注入攻击，防守方的 ASLR 与 DEP，然后是代码复用攻击如 ROP 和 JIT-ROP，再到 PAC 等已在现代硬件中得到实现的控制流完整性防御技术。可是，我们不能永远这样下去，我们需要内存安全的编程语言。

> Then let's look at the history of the programming language development. Over the past seventy years, numerous programming languages have been developed. And this includes early days that assembly language, to c in 1970s, to Java, php and javascript in 1990s, to go in 2009, rust in 2010, Swift in 2014, etc. Among them, I want to particularly highlight rust which is memory safe by design and meanwhile performance. Today, the good news is that rust has become the most loved programming language according to our recent survey from programmers and many Tech companies such as Microsoft and Facebook have started to use rust in their production.

纵观编程语言的历史，七十年来已经有许多语言被开发了出来。这包括早期的汇编语言，到 70 年代的 C， 90 年代的 Java，PHP 和 JavaScript，2009 年的 Go，2010 年的 Rust，2014 年的 Swift 等等。其中我想着重讲讲 Rust，它是一门从语言设计层面兼具内存安全与性能的编程语言。今天，一个好消息是，根据我们最近的调查，Rust 已经成为程序员中最受欢迎的编程语言，许多科技公司如微软和脸书已经开始在生产中使用 Rust。

> The third direction I want to talk about is the formal verification. We know formal methods have been used during the aircraft design which is one of the reasons why airplanes are more resilient to crashes. In the past a few years, we have witnessed a number of news headlines such as hack-proof drones, formal verification in automotive software design and recently formally verified software in real world. These are all good signs.

我想谈的第三个方向是形式化验证。我们知道形式化方法已经在飞机设计中使用且成为了飞机更能抗坠毁的原因之一。在过去几年中，我们已经看到了许多新闻头条例如防黑客无人机，汽车软件设计中的形式化验证以及最近在现实世界中正式验证的软件，这些都是好迹象。

> However, we also have to be aware that the difficulty of proving software is secure is way more challenging than finding a vulnerability in the software. While I do not work on formal revocation at this moment, I do have seen some advancements in the systems community which is started from 2009 where a micro kernel with less than 10,000 lines of code was formally verified. Then in 2012, an execute-verify architecture was proposed to handle the verification for multi core servers. In 2013 it was the verification of computations with states. 2014, end to end security VIA automated full system verification. 2016, verification of file systems. Suddenly, in 2017 three papers on verification. They focused on either file systems or operating system kernels or enclave software. 2014 four papers on verification. They focus on either information flow control
to concurrent software or computationality of file systems or concurrent services. 2019, 4 papers, 2020, 5 papers. So clearly we see the trend and we can anticipate more formal verifications will be applied in real world computer systems design and implementations.

然而，我们也必须意识到证明软件安全远比发现软件中的漏洞更具挑战性。虽然我目前并不从事形式化验证的研究，但我确实看到了系统社区的一些进展。2009 年，一个少于 10,000 行代码的微内核被正式验证。2012 年，一个执行-验证的架构被提出以用于处理多核服务器的验证，2013 年，出现了带状态的计算验证技术，2014 年通过全自动化系统验证端到端安全技术，2016 年，文件系统的验证。突然，2017 年出现了 3 篇关于形式化验证的论文，它们分别聚焦于文件系统，操作系统内核和隔区软件。2014 年出现了 4 篇关于形式化验证的论文，分别聚焦于信息流控制，并发软件，文件系统的计算行和并发服务。2019 年 4 篇，2020 年 5 篇。所以很明显我们能够看到这一趋势，并预期更多的形式化验证技术将被应用于现实世界的计算机系统设计和实现。

> The last direction I would like to talk about is using AI for cybersecurity. Remember I have talked about machine is really good at brute force, precision and scalability and they never feel tired. So we can absolutely use machines particularly the AI to automate many of our sophisticated tasks such as cyber data analytics, improve the precision of attack detection, predict the risks and respond to attacks instantly. Recently, Ohio state was awarded the 20 million dollars AI-Edge institute from the national science foundation. I'm very fortunate to be one of the faculty members in this institute. The mission of this institute is to design the next generation edge network such as 6G and beyond that are highly efficient, reliable and robust. Clearly, security and privacy are crucial in the edge network, and we will investigate, how AI can help secure the edge network and meanwhile, how to secure the AI itself and protect the user's privacy. I'm quite excited about having the opportunities to work on these topics.

我想谈的最后一个方向是使用人工智能进行网络安全。记得我谈过机器非常擅长暴力破解，精确性和可扩展性。它们永远不会感到疲劳。因此我们当然能使用机器，特别是人工智能来自动化许多复杂的任务，例如：

- 网络数据分析
- 攻击检测的准确性改良
- 风险预测
- 即时攻击响应

最近，俄亥俄州立大学获得了国家科学基金会 2000 万美元的人工智能研究所。我很幸运成为这个研究所的教员之一。这个研究所的使命是设计下一代边缘网络例如 6G 以及其它高效，可靠且鲁棒的技术。显然，安全和隐私在这一边缘网络中是至关重要的。我们将调研 AI 如何帮助保护边缘网络且同时保护其自身与用户隐私。我非常兴奋有机会在这些主题上工作。

> Let me conclude my talk by briefly talking about the Non technical aspect in cybersecurity. Cybersecurity is complicated. It requires not only the technology development but also the laws to deter their attackers and who
then accountable if they commit any cyber attacks. We can see there are already a number of cyber-secured laws and regulations from earlier CFAA to recently GDPR and CCPA. These laws can certainly make attackers think twice before launching any attacks and meanwhile make the Tech companies invest more in cyber security
Otherwise, they will face huge financial punishment for example by paying the fine with up to billions of dollars, for cyber attacks such as data breaches

让我通过简要谈谈网络安全的非技术方面来总结这次演讲。网络安全很复杂，它不仅需要技术发展，还需要法律来阻止攻击者，并在他们进行任何网络攻击时追究责任。我们可以看到已经有许多网络安全法律和法规，从早期的 CFAA 到最近的 GDPR 和 CCPA。这些法律当然可以让攻击方在发动任何攻击前三思，同时让科技公司更多地投资于网络安全。否则它们将因为数据泄露之类的网络攻击面临巨大的经济处罚，例如支付高达数十亿美元的罚款。

> However, We have to be aware that there are many other challenges such as attribution, which aim to locate the attackers but for the Internet it is so easy for attackers to hide themselves. And also the jurisdiction challenge where we need the international laws and orders and the enforcement of these laws across the globe. Now I have reached the end of my presentation. Hopefully I have convinced you why cyber security is hard. If you have any questions and comments, please feel free to contact me at this email address. Thank you for watching

然而，我们必须意识到还有许多其它挑战，例如归因————我们需要定位攻击者但在互联网中攻击者很容易隐藏自己，管辖权挑战————我们需要国际法律和秩序并在全球范围内推行这些法律法规。我的演讲到此结束，希望我已经说服了你为什么网络安全如此困难，如果你有任何问题和评论，请随时通过这个电子邮件地址联系我，感谢观看。

## Reference

[Prof. Zhiqiang Lin's Homepage](https://cse.osu.edu/people/lin.3021)
[Cybersecurity Days](https://it.osu.edu/security/cybersecurity-days)
[Records on YouTube Channel](https://go.osu.edu/CSD21blog)
