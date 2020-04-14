---
layout:     post
title:      "理解volatile的三重境界（一）"
subtitle:   "Java中volatile的基本作用"
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

- 第一重境界：（本篇），理解`volatile`的基本作用
- 第二重境界：理解`volatile`背后的底层原理
- 第三重境界：理解happens-before语义和synchronize-with语义，掌握Java的线程模型和锁机制


## 目录
{:.no_toc}

- toc
{:toc}


## volatile的基本作用

很多技术博客和“面试宝典”一类的书中都提到过，Java的`volatile`关键字主要有如下几个作用。

1. 保证long和double等64位的数据类型在操作时的原子性
2. 消除线程工作内存的缓存，保证volatile变量的读写在线程间的可见性
3. 保证volatile变量声明和相关操作的语句不会受指令重排优化的影响

对于完全不了解volatile原理的同学，以上内容请**熟读全文并背诵**。


当然，以上对volatile的描述仅限初学Java理解和记忆，多见于国内“从入门到精通系列”。

实际上述描述并不全面，个别情况下为了方便理解甚至描述都不准确。

想要真正理解volatile底层原理，以及Java内存模型（JMM）的设计思路，需要结合Java语言标准（Java Language Specification）加深理解。

国内涉及JLS的相关资料比较少，如果有兴趣，请看下一篇。
