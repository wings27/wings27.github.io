---
layout:     post
title:      "MySQL语句返回的影响行数"
subtitle:   "以及参数useAffectedRows的作用"
date:       2017-06-03 12:00
author:     "wings27"
header-img: "img/tag-bg.jpg"
license:    true
tags:
    - MySQL
---


MySQL语句返回的影响行数是怎么得来的？为什么同样的更新语句，直连MySQL和通过Java代码执行，会返回不同的结果？

本文参考官方文档，总结出各种不同场景下MySQL影响行数的取值。

下面先简单介绍几个基本概念。只关注结果不想看原理的，可以直接跳到“表格总结”部分。


## 目录
{:.no_toc}

- toc
{:toc}

## 影响行数 affected-rows

无论是使用Mybatis，还是直接使用JDBC，还是直接使用MySQL提供的C语言的api: `mysql_real_connect()`，最终返回的影响行数，底层都是由`mysql_affected_rows()`提供的。

下文将影响行数称为affected-rows，和官方文档保持一致。[^1]


## 参数 useAffectedRows

对于MySQL的Java Connector 5.1.7以后的版本，可以配置一个useAffectedRows参数，默认为false.

useAffectedRows置为false，相当于MySQL底层开启`CLIENT_FOUND_ROWS`标识。（相当于这两个标识是相反的）

这时affected-rows返回的将是匹配的行数（found rows） 而不是实际影响行数（affected rows）。

例如 `UPDATE xxx SET a = 1 WHERE ...`，如果a字段本来就是1，那么执行 UPDATE 前后的数据就没有发生变化，则这条语句执行后匹配行数=1，实际影响行数=0.

如果参数 useAffectedRows=true，那么affected-rows表现如下：

对于 SELECT 语句，`mysql_affected_rows()`等价于`mysql_num_rows()`，也就是返回的查询结果的行数。 [^2]

对于 UPDATE 语句，返回的affected-rows是实际变化了的行数。

对于 INSERT / DELETE 没什么特殊的，返回的影响行数就是实际插入or删除的行数。

对于 REPLACE 语句，如果实际匹配到了1行，那么返回的affected-rows等于2. 这是因为 REPLACE 的执行机制是先 delete 再 insert.


对于 INSERT ... ON DUPLICATE KEY UPDATE：

如果没有唯一键冲突，语句将执行 INSERT，那么返回的affected-rows是1.

如果有唯一键冲突，语句将执行 UPDATE，这种情况下：

0. 如果实际变化了1行，那么返回的affected-rows将是2，不要问为啥，问就是规定如此~
0. 如果匹配到了1行，但实际没有变化（set的值等于原值），那么affected-rows返回0.


## 表格总结

|------------------------------------------------|----------------------|-----------------------|
|                                                | useAffectedRows=true | useAffectedRows=false |
|------------------------------------------------|----------------------|-----------------------|
| SELECT                                         |                    1 |                     1 |
| INSERT                                         |                    1 |                     1 |
| DELETE                                         |                    1 |                     1 |
| REPLACE唯一键不冲突                            |                    1 |                     1 |
| REPLACE唯一键冲突                              |                    2 |                     2 |
| UPDATE造成变化                                 |                    1 |                     1 |
| UPDATE未造成变化                               |                    0 |                     1 |
| INSERT O.D.K UPDATE 唯一键不冲突               |                    1 |                     1 |
| INSERT O.D.K UPDATE 唯一键冲突，UPDATE造成变化 |                    2 |                     2 |
| INSERT O.D.K UPDATE 唯一键冲突，UPDATE无变化   |                    0 |                     1 |

**以上表格都假设只命中1行数据，对于可能命中N行数据的情况，表格中结果乘N即可**

**以上表格中出现的唯一键冲突也包含主键冲突**


## 参考文献

[^1]: [mysql-affected-rows](https://dev.mysql.com/doc/refman/5.7/en/mysql-affected-rows.html)
[^2]: [mysql-num-rows](https://dev.mysql.com/doc/refman/5.7/en/mysql-num-rows.html)

