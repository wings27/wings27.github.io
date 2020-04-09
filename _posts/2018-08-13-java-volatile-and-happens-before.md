---
layout:     post
title:      "谈谈volatile与happens-before原则（二）"
subtitle:   "volatile的语义含义，happens-before和synchronize-with"
date:		2018-08-13 12:00
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


## 理解happens-before语义

### 程序顺序与线性一致性

**程序顺序（Program Order）**，这个概念很简单，对于单个线程来说，就是内部的、语义上的执行顺序。

如果没有循环、分支、方法调用等跳转逻辑，那么就完全等同于代码书写顺序。

多线程下的程序顺序不是唯一的，只要求按照某个顺序执行，每个线程都能保证自身的程序顺序，那么这个执行顺序就是一个有效的，多线程场景下的程序顺序。

**线性一致性（Sequential consistency）**指的是一种约束：具体指多线程场景下：

1. 实际的执行顺序与程序顺序一致
2. 同时还需保证执行顺序靠前的写入操作w产生的结果，一定能被靠后的读取操作r正确读取到。

可见，线性一致性是一个非常强的约束。执行顺序与程序顺序一致，这个容易达到。

但同时还需要保证所有写入都是原子的（atomic），并且写入对所有其他线程必须是实时可见的（immediately visible），否则就不满足上述第2个约束条件了。

Java的内存模型（JMM）没有采用线性一致性。否则很多编译器和执行引擎的性能优化，都会违背上述约束。如果取缔了这些优化项，虽然线性一致了，但是程序的性能会受到很大影响。


### 同步语义顺序与同步操作

**同步语义顺序（Synchronization Order）**指的是**同步操作**的顺序与线程的**程序顺序**一致。https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.4.4

**同步操作**指定是Java中的一些特殊操作 https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.4.2 ，包含：

1. volatile读
2. volatile写
3. 管程锁定（monitor lock）
4. 管程解锁
5. 线程首项操作（一个假想的操作，位于线程run方法第一行代码执行前）
6. 线程末项操作（一个假想的操作，位于线程run方法最后一行执行后，或抛异常退出线程前）
7. 线程start()方法
8. 探测线程是否终止的方法，如`Thread.interrupted(), t.isAlive(), t.join(), t.isInterrupted()`

### synchronized-with关系

**同步操作**定义了一系列的关系，称为*synchronized-with*关系：

1. 对管程m的解锁操作，*synchronizes-with* 后续所有对m的加锁操作。（后续指**同步语义顺序**上靠后的，下同）
2. 对volatile变量v的写操作，*synchronizes-with* 后续所有对v的读操作。
3. 线程start()方法 *synchronizes-with* 该线程的首项操作
4. 变量赋予默认值（0, null, false） *synchronizes-with* 该线程的首项操作
5. 线程末项操作 *synchronizes-with* 其他线程对该线程的探测终止操作（`t.isAlive(), t.join()`等）
6. 如果线程T1 interrupt 线程T2，则interrupt操作 *synchronizes-with* 其他线程对该线程的探测终止操作

因为没有对应中文翻译，我下面把它简写为sw. 例如 sw(A, B) ，代表A操作 synchronized-with B操作。

那么sw关系有啥用？请接着看。


### happens-before语义顺序

如果程序顺序上，A先发生于B，同时A的影响对B可见，则称A *happens-before* B.

这里需要注意，如果A对B本身就无影响，或者说B不关心A对它的影响，我们也认为A的影响对B可见，即A *happens-before* B，这种情况下，JVM实现时，不需要和程序顺序一致，可以任选A和B的执行顺序，依然认为满足A *happens-before* B 的约束。

这一点可以结合离散数学中善意推定的概念去理解，即前件为假时，命题总为真。

例如命题：“如果1+1=3，那么太阳从西方升起。”，这个命题是真命题。

*happens-before* 我下面把它简写为hb. 例如 hb(A, B) ，代表A操作 *happens-before* B操作。







### 参考文献

