---
layout:     post
title:      "谈谈volatile与happens-before原则（二）"
subtitle:   "volatile的语义含义，happens-before和synchronize-with"
date:		2018-08-12 12:00
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

第一重境界：（上一篇），理解`volatile`的基本作用
第二重境界：（上一篇），理解`volatile`基本作用背后的底层原理
第三重境界：（本篇），理解happens-before语义和synchronize-with语义，掌握Java的线程模型和锁机制


## 目录
{:.no_toc}

- toc
{:toc}


## volatile基本作用

### 作用1：保证64位操作的原子性

首先，详细解释上面提到的：

> 保证long和double等64位的数据类型在操作时的原子性

何谓“64位数据类型的操作原子性”？我们知道Java中long和double是64位。底层指令对64位数据进行写入时，出于性能和实现成本的考虑，可能会拆分成两次写入指令，分别写入高32位和低32位。

具体是否拆分，取决于JVM的具体实现，官方JVM标准是允许（但不建议）做拆分实现的。[^1]

> Implementations of the Java Virtual Machine are encouraged to avoid splitting 64-bit values where possible. 

而一个合法的JVM，完全可以实现为指令拆分，这就导致写入操作的非原子性：当指令仅执行完第一条时，变量的高32位和低32位一半是新值一半是旧值。

此时另一个线程读取这个64位的变量，就会读取到完全错误的值（整体既非旧值也非新值），造成错乱。

因此JVM规范要求：标记为volatile的变量，不允许指令拆分，必须保证操作的原子性。

所以在共享使用long或double类型变量时，尽量标记为volatile以避免问题。

> Programmers are encouraged to declare shared 64-bit values as volatile or synchronize their programs correctly to avoid possible complications.

### 作用2：消除缓存

以`Thread.sleep`为例，由于该方法没有同步语义(synchronization semantics)，因此对寄存器中的缓存进行写操作时，不保证也会写入到共享内存（shared memory）中。读操作也可能直接读取寄存器缓存，而不需要读内存。

那么如下代码：

```java
while (!this.done)
    Thread.sleep(1000);
```

可能导致底层执行时，只读取一次`this.done`的值，之后就只从寄存器缓存中读取。

哪怕另一个线程修改了`this.done`的值，当前线程也会一直陷入循环。

如果对`this.done`声明时标记`volatile`，则可以消除这个影响，保证另一线程修改后，当前线程能够读取到修改后的值。


### 参考文献


[^1]: https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html