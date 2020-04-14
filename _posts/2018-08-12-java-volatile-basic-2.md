---
layout:     post
title:      "理解volatile的三重境界（二）"
subtitle:   "Java中volatile的底层原理"
date:		2018-08-12 22:00
author:     "wings27"
header-img: "img/post-bg-java.png"
license:    true
tags:
    - Java
    - multithreading
---


## 前言

本系列文章将带你了解Java中volatile的基本作用和原理，以及happens-before原则和synchronize-with原则，帮助大家更好地理解Java的线程模型和锁机制。

理解volatile的三重境界：

- 第一重境界：理解`volatile`的基本作用
- 第二重境界：（本篇），理解`volatile`背后的底层原理
- 第三重境界：理解happens-before语义和synchronize-with语义，掌握Java的线程模型和锁机制

## 目录
{:.no_toc}

- toc
{:toc}


## volatile底层原理

### 作用1：保证64位操作的原子性

首先，详细解释之前提到的：

> 保证long和double等64位的数据类型在操作时的原子性

何谓“64位数据类型的操作原子性”？我们知道Java中long和double是64位。底层指令对64位数据进行写入时，出于性能和实现成本的考虑，可能会拆分成两次写入指令，分别写入高32位和低32位。

具体是否拆分，取决于JVM的具体实现，官方JVM标准是允许（但不建议）做拆分实现的。[^1]

> Implementations of the Java Virtual Machine are encouraged to avoid splitting 64-bit values where possible. 

而一个合法的JVM，完全可以实现为指令拆分，这就导致写入操作的非原子性：当指令仅执行完第一条时，变量的高32位和低32位一半是新值一半是旧值。

此时另一个线程读取这个64位的变量，就会读取到完全错误的值（整体既非旧值也非新值），造成错乱。

因此JVM规范要求：标记为volatile的变量，不允许指令拆分，必须保证操作的原子性。未标记的情况下，也建议但不强制实现原子性。

由于Java官方规范的建议，目前市面常见的JVM实现，即便不标记volatile，也默认实现了64位变量的原子操作。

当然我们在使用共享的long或double类型变量时，也尽量标记为volatile以避免问题。

> Programmers are encouraged to declare shared 64-bit values as volatile or synchronize their programs correctly to avoid possible complications.

**同时需要注意：**这里所说的“保证操作的原子性”，前提是操作本身就对32位类型具备原子性。

例如赋值操作，本身对int就是原子的，只不过对64位的long型不具备原子性。

在标记volatile的情况下，才能保证64位的原子性，不会出现赋值执行一半被其他线程读取的情况。

但是对于本身非原子的操作，例如自增操作，标记volatile也**不会**把自增过程变为原子的。依然需要我们做额外的处理。


### 作用2：消除缓存

volatile的另一个作用，是消除线程工作内存[^2]*（working memory，一个JMM的抽象概念，实际可能包含各级缓存、寄存器等）*的缓存值，直接使用共享内存*（又称主存）*中的值。

如下代码为例：

```java
while (!this.done)
    Thread.sleep(1000);
```

由于`Thread.sleep`没有同步语义(synchronization semantics)，因此sleep执行前后，其他线程对寄存器中的缓存进行写操作时，不保证也会写入到共享内存（shared memory）中，读操作也可能直接读取寄存器缓存，而不需要读共享内存。

这可能导致底层执行上述代码时，只读取一次`this.done`的值，之后就只从寄存器缓存中读取。

哪怕另一个线程修改了`this.done`的值，当前线程也会一直陷入循环。[^3]

如果对`this.done`声明时标记`volatile`，则可以消除这个影响，保证另一线程修改后，当前线程能够读取到修改后的值。


### 作用3：消除指令重排序

看下面这个例子：

有r1, r2两个本地变量，及A, B两个线程间共享变量。初始化`A == B == 0`

|  Thread 1  |  Thread 2  |
|------------|------------|
| 1: r2 = A; | 3: r1 = B; |
| 2: B = 1;  | 4: A = 2;  |

当两个线程执行上述代码时，最终r1和r2可能有不同的结果。

例如执行顺序为1,3,2,4，则结果是`r2 == 0, r1 == 0`。执行顺序为1,2,3,4，则结果是`r2 == 0, r1 == 1`等等。

但是按照常理来看，结果不可能出现`r1 == 1, r2 == 2`：

如果想要`r2 == 2`，4必须先于1执行，同时由于3先于4并且1先于2，所以3一定先于2执行，这样r1就不能是1.

但是我们多次尝试就可能得到`r1 == 1, r2 == 2`的结果。原因是根据Java规范，编译器可以对指令进行重排序，只要重排序不影响当前线程的独立运行结果即可[^4]。这个例子中，单拿出一个线程看，指令的顺序对于自己这个线程确实没有影响。因此考虑指令重排，1与2的执行顺序、3与4的执行顺序都是不确定的。

> ... compilers are allowed to reorder the instructions in either thread, when this does not affect the execution of that thread in isolation.

如果对A标记volatile，则可以消除重排序，进而不会再出现`r1 == 1, r2 == 2`的结果。


当然，以上对volatile的描述仅限初学Java理解和记忆，多见于国内“从入门到精通系列”。

实际上述描述并不全面，个别情况下为了方便理解甚至描述都不准确。

想要真正理解volatile底层原理，以及Java内存模型（JMM）的设计思路，需要结合Java语言标准（Java Language Specification）加深理解。

国内涉及JLS的相关资料比较少，如果有兴趣，请看下一篇。


### 参考文献

[^1]: [Java Language Specification 17.7](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.7)
[^2]: [Synchronization and the Java Memory Model, by Doug Lea](http://gee.cs.oswego.edu/dl/cpj/jmm.html)
[^3]: [Java Language Specification 17.3](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.3)
[^4]: [Java Language Specification 17.4-A](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.4-A)