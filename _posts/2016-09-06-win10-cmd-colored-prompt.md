---
layout:     post
title:      "Win10命令行实现彩色提示符"
subtitle:   ""
date:		2016-07-06 00:00
author:     "wings27"
header-img: "img/tag-windows.jpg"
license:    true
tags:
    - Windows
---

本方法是我自己试验得出的。随便用中文和英文google了下，应该还没人讲到过这个做法，所以发出来分享一下。

本文方法仅在Win10专业版测试过，理论上也支持Win10其他版本。

但是应该**不支持**Win7等其他发行版，暂未测试。此外在stackoverflow上有适用于Win7的方案[^1]，但需要更改系统文件。

## 目录
{:.no_toc}

- toc
{:toc}


### 方法

最终效果：

![win10-cmd-colored-prompt.png](/img/in-post/win10-cmd-colored-prompt.png "最终效果")

临时实验，可以在命令行输入： `prompt $e[1;36m$P$G$e[0;1m$S`

想永久生效，需要新建名为`%PROMPT%`的环境变量，并赋值为：`$e[1;36m$P$G$e[0;1m$S`

其中`$e`是表示改变颜色，`$P`表示当前路径，`$G`是大于号，`$S`是空格。

更详细的定义：

```plain
> prompt /?

更改 cmd.exe 命令提示符。

PROMPT [text]

  text    指定新的命令提示符。

提示符可以由普通字符及下列特定代码组成:

  $A   & (短 and 符号)
  $B   | (管道)
  $C   ( (左括弧)
  $D   当前日期
  $E   Escape 码(ASCII 码 27)
  $F   ) (右括弧)
  $G   > (大于符号)
  $H   Backspace (擦除前一个字符)
  $L   < (小于符号)
  $N   当前驱动器
  $P   当前驱动器及路径
  $Q   = (等号)
  $S     (空格)
  $T   当前时间
  $V   Windows 版本号
  $_   换行
  $$   $ (货币符号)

如果命令扩展被启用，PROMPT 命令会支持下列格式化字符:

  $+   根据 PUSHD 目录堆栈的深度，零个或零个以上加号(+)字符，
       一个推的层一个字符。

  $M   如果当前驱动器不是网络驱动器，显示跟当前驱动器号或
       空字符串有关联的远程名。
```

颜色定义：

以下定义摘自stackexchange[^2]，本来是linux的[^3]，但也基本适用于windows的cmd.

```plain
txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
bakgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset
```

### 参考文献

[^1]: [Color for the PROMPT (just the PROMPT proper) in cmd.exe and PowerShell? - StackOverflow](http://stackoverflow.com/a/6298825)
[^2]: [What color codes can I use in my PS1 prompt? - stackexchange](http://unix.stackexchange.com/a/124408)


[^3]: [Bash/Prompt customization - archlinux](https://wiki.archlinux.org/index.php/Bash/Prompt_customization#Colors)
