---
layout:     post
title:      "利用Windows映像劫持实现默认程序的替换"
subtitle:   ""
date:       2015-05-26 12:00:00
author:     "wings27"
header-img: "img/tag-windows.jpg"
tags:
    - Misc
    - Windows
---

众所周知，Windows NT内核的系统（Windows XP, Windows 7 等）拥有一项叫做IFEO的神奇技术，俗称映像劫持。本来是用于加载调试器的[^1]，不过我们也可以另辟蹊径，利用这一机制来替换系统默认程序关联。

## 目录

<!-- TOC depthFrom:3 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [文件关联](#文件关联)
- [使用IFEO](#使用ifeo)
- [详细操作](#详细操作)
- [参考文献](#参考文献)

<!-- /TOC -->

<a name="文件关联"></a>

### 文件关联

我们可能都遇到过需要更改系统默认文件关联的情况。比如想用我们心爱的编辑器打开所有文本类型的文件。这就需要了解Windows的文件关联。

简单解释一下，Windows的资源管理器识别文件类型是由扩展名决定的（而并不是文件头决定文件类型）。首先扩展名会对应一种文件类型，这种文件类型的不同操作再对应到不同的具体命令。

比如： `.txt --> txtfile --> { "open": "notepad.exe %1", "edit": "notepad.exe %1", ... }`

这些对应关系保存于注册表的`HKEY_CLASSES_ROOT`项，由Explorer读取后，决定文件该用什么命令处理。

文件扩展名与文件类型的对应关系，可以通过`assoc`命令查看或修改。

例如：

- 查看后缀关联：

 `assoc .txt`
> .txt=txtfile

- 新增/更改关联：

 `assoc .json=txtfile`
> .jpg=txtfile

- 删除关联：

 `assoc .json=`
> (无返回内容)

文件类型与open command的对应关系，可以通过`ftype`命令查看或修改。用法与`assoc`类似，使用`%1`表示目标文件，`%2`等表示其他参数，`%*`代表所有参数。
例如：

`ftype txtfile`
> txtfile=%SystemRoot%\system32\NOTEPAD.EXE %1

进而，文件扩展名就与相应程序关联上了。

*以上的命令只改变扩展名对应的打开方式，文件类型的其他相关信息不受影响。*

<a name="使用ifeo"></a>

### 使用IFEO

我们发现，想使用指定程序打开特定后缀的文件，只需 `assoc` 和 `ftype` 就可以搞定了。

`assoc .json=txtfile`

`ftype txtfile=MY_FAVOURITE_EDITOR.exe %1`

不过这种方案只能更改open command。比如.bat后缀的批处理文件，右键点击编辑，还是用回（很挫的）notepad打开了。

于是很自然想到另一个方案，干脆用我们的编辑器替换掉notepad.exe算了。不过这样做的缺陷也显而易见。何况 XP系统还可能触发系统文件保护机制。

因此，更好的办法是使用IFEO，以加载“调试器”的形式，在运行时“替换”掉系统默认程序。这样既不会产生新文件（符号链接），也不会改动系统文件。

<a name="详细操作"></a>

### 详细操作

使用IFEO很简单。注册表定位到

`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe`

（注意其中的Windows NT）

创建Debugger字符串值(REG_SZ)，更改其值为`MY_FAVOURITE_EDITOR.exe -z`就可以了。

这里的"-z"参数表示跳过后面的参数，如果不加这个参数，Sublime Text就会同时打开notepad.exe本身，因为后者是作为被调试的程序传参传入Sublime Text的。

"-z"参数适用于Sublime Text。如果使用Notepad2，则"-z"参数要改为"/z".

至于Notepad++, 暂时无解，可以尝试用AutoHotKey实现该功能。

至此，使用IFEO替换默认编辑器就已经完成了。快去开心地撸代码吧！\\(^o^)/ YEAH!

<a name="参考文献"></a>

### 参考文献

[^1]: [Launching the Debugger Automatically - MSDN](https://msdn.microsoft.com/en-us/library/a329t4ed%28VS.71%29.aspx)
