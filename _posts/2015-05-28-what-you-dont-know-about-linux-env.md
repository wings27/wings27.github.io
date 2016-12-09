---
layout:     post
title:      "你不知道的Linux环境变量"
subtitle:   ""
date:		2015-05-28 00:29
author:     "wings27"
header-img: "img/tag-bg.jpg"
license:    true
tags:
    - linux
---

Windows上的环境变量配置大家都比较熟悉了，通常我们都会使用系统提供的图形界面来配置，简(shi)单(fen)易(dan)用(teng)。其实Linux上的环境变量配置更为简洁。

## 目录
{:.no_toc}

- toc
{:toc}


### 正文

#### 环境变量: Windows v.s. Linux

众所周知，Windows的逻辑是系统配置各种扔进注册表里，而Linux的配置通常则是放入文件里。

事实上，以Linux的尿性[^1]，何止配置是文件，简直一切皆文件。[^2]

比如: `cat /dev/urandom > /dev/dsp` 能够在扬声器中播放白噪声。好玩吧~

额好像扯远了。。。 

Anyway, Linux 的环境变量配置，正如大家所知道的，只要写入到 `/etc/profile`下就可以了。不过这其实**并不是**推荐的做法。

想知道原因，首先需要了解一下Linux下环境配置文件的加载顺序。

#### Linux 环境配置加载顺序 (以CentOS 7 为例)

Linux通常有以下几个环境配置文件：

- /etc/profile
- /etc/profile.d/*.sh
- ~/.bash_profile
- ~/.bashrc
- /etc/bashrc

不同场景下配置文件加载的机制也不同，这里我们分情况来说。

1. 用户正常登录（密码或公钥）进入bash环境。
加载顺序： 
    `/etc/profile` > `/etc/profile.d/*.sh` > `~/.bash_profile` > `~/.bashrc` > `/etc/bashrc`

2. 使用su切换用户，如 su someuser
加载顺序：
`~/.bashrc` > `/etc/bashrc` > `/etc/profile.d/*.sh`

3. ssh连接至非交互环境执行命令
加载顺序(与2相同)：
`~/.bashrc` > `/etc/bashrc` > `/etc/profile.d/*.sh`

并且Linux环境加载某个配置文件时，该文件内部有主动加载的配置也会同步地加载（就像传统的方法调用那样），比如 /etc/profile.d/lang.sh 可能会加载 /etc/sysconfig/i18n

以及后面声明的环境变量值会覆盖掉之前的同名变量。

#### 验证

在我的机器(CentOS 7.0) 上做测试，编辑上述文件，加入不同的环境变量，赋值为当前时间。

例如在`/etc/profile`行首加入: 

    export TEST_ETC_PROFILE=`date +'%c %N'`

其余以此类推。

##### 测试结果：

![测试结果](/img/in-post/linux-env-test-result.png)

从时间戳可以看出，上述加载顺序是正确的。

#### 结论

1. 原则上**不推荐**对`/etc/profile`做任何更改，（在`/etc/profile` 头部的注释中就能看到），主要应该是基于维护成本考虑。

2. `/etc/profile.d/*.sh`总是会加载，无论是登录进入bash还是su进入bash都会加载，因此**系统级别**的变量配置脚本推荐放入`/etc/profile.d/`下。（注意后缀名和权限）。

3. 对bash本身的自定义配置推荐写在`~/.bash_profile`里。

4. 自写自用的辅助脚本需要加到`$PATH`的（如 `PATH=$PATH:/opt/scripts` ），推荐写在`~/.bashrc`里。需要多用户共用的，则放在`/etc/bashrc`里。

更多详情参见 CentOS官方文档 [^3] , 解释比较全面，好顶赞！


### 参考文献

[^1]: [尿性_互动百科](http://www.baike.com/wiki/%E5%B0%BF%E6%80%A7)

[^2]: [知乎 - Linux 下 “一切皆文件” 思想的本质和好处在哪里？](http://www.zhihu.com/question/25696682)

[^3]: [Configuration / Environment Variables | CentOS HowTos](http://centoshowtos.org/environment-variables/)
