---
layout:     post
title:      "MySQL语句truncate和delete的区别"
subtitle:   ""
date:		2016-09-29 12:00
author:     "wings27"
header-img: "img/tag-bg.jpg"
license:    true
tags:
    - MySQL
    - database
---

## 目录
{:.no_toc}

- toc
{:toc}


### 正文

本文内容主要总结自MySQL官方文档，**只适用于MySQL，不适用SQL SERVER等**

|       差异       |                 truncate                |                   delete                  |
|------------------|-----------------------------------------|-------------------------------------------|
| 分类             | 属于 DDL(Data Definition Language) 语句 | 属于 DML(Data Manipulation Language) 语句 |
| 执行方式         | 先DROP table，再重新 CREATE table       | 不改动table结构，仅仅是逐行删除数据       |
| WHERE语句        | 不支持                                  | 支持                                      |
| 日志             | 不记录删除数据的日志，无法恢复          | 记录删除数据的日志                        |
| 支持事务回滚     | 隐含commit，不支持回滚                  | 支持回滚                                  |
| 加锁范围         | 表级锁                                  | 行级锁                                    |
| 有外键约束 [注1] | 会执行失败                              | 是否成功取决于具体删除的数据              |
| 返回值           | 永远返回 "0 rows affected"              | 正常                                      |
| AUTO_INCREMENT   | 会重设                                  | 不会重设                                  |
| DELETE triggers  | 不会触发                                | 会触发                                    |
| (通常情况)性能   | 快                                      | 慢                                        |

> 注1: 这里的“外键约束”只适用 InnoDB 或 NDB 的表，且“约束”指的是其他表对当前表的引用约束。如果只是当前表的列之间的约束则不受影响 [^1]。

### 参考文献

[^1]: [MySQL :: MySQL 5.6 Reference Manual :: 13.1.33 TRUNCATE TABLE Syntax](http://dev.mysql.com/doc/refman/5.6/en/truncate-table.html)
