---
layout:     post
title:      "VirtualBox网络配置详解"
subtitle:   "虚拟机连外网，主机与虚拟机互联，虚拟机与虚拟机互联"
date:       2016-07-28 00:00
author:     "wings27"
header-img: "img/tag-linux.jpg"
license:    true
tags:
    - Linux
---

本文将介绍VirtualBox虚拟机网络配置，使得虚拟机可以连接互联网，并且主机与虚拟机可以互相联通

## 目录
{:.no_toc}

- toc
{:toc}


### 前言

VirtualBox是我个人非常喜欢的虚拟机软件，比起VMWare轻量很多，非常适合只做服务器的虚拟机。

我的系统版本：

物理机主机（host）安装了Windows 7，以及主角VirtualBox 4.3.24。

虚拟机（guest）安装了CentOS 7，内核版本是 3.10.0-327.22.2.el7.x86_64

```bash
uname -a
```

```plain
Linux localhost.localdomain 3.10.0-327.22.2.el7.x86_64 #1 SMP Thu Jun 23 17:05:11 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

### 配置方式

虚拟机的安装过程不再详述，只说一下网络配置方式。

想让虚拟机可以连接互联网，并且主机与虚拟机可以互相联通，可以用这两种配置方式任选其一：

1. 桥接网卡
2. NAT + Host Only Adapter

本文将讲解这两种配置方式的原理和具体配置过程。

### 原理

#### 桥接网卡

桥接网卡可以理解成给虚拟机分配的一个虚拟网卡，通过虚拟机软件的虚拟交换机，与物理机的物理网卡进行桥接。

这样虚拟机的虚拟网卡就如同物理机的网卡一样，可以认为是一台独立的网络设备。然后我们就可以设置这个虚拟网卡，让它和物理机网卡同处在一个网段下。

例如物理机是通过路由器的DHCP获取IP连接上网的，那么虚拟机也设成DHCP动态获取即可。

如果物理机是手动填写的静态IP，那么虚拟机也填写一个不冲突的IP即可。

其他的网关DNS等配置也直接copy物理机的就好了。

VirtualBox的网卡配置如下：

![virtual-box-bridge-adapter.png](/img/in-post/virtual-box-bridge-adapter.png)

<!--todo： 插入拓扑结构图 -->

这种方式的好处是配置简单直观，桥接网卡后虚拟机可以认为是一台独立的网络设备，和真实的物理机是并列关系，虚拟机即可直接联网也可与物理机互联。

坏处是有些场景不适用，例如有些公司或大学宿舍的环境下，局域网内的IP是预先分配好的，不能自己随便加机器随便写IP，这样桥接网卡就不太适用了。
同样如果路由有设备数量限制的话那么桥接网卡也会使得虚拟机占用一个名额。

#### NAT + Host Only Adapter

**NAT（网络地址转换）**给虚拟机建立了一个通过物理机连接外部的通道。虚拟机可以访问外网，也可以访问物理机。但是物理机访问虚拟机不方便（需要端口转发）。

端口转发配置：
![virtual-box-port-forwarding-entrance.png](/img/in-post/virtual-box-port-forwarding-entrance.png)

例如物理机想通过ssh连接虚拟机，我们需要配置如下的端口转发规则：
![virtual-box-port-forwarding-settings.png](/img/in-post/virtual-box-port-forwarding-settings.png)

然后就可以在ssh客户端新建连接到本地 127.0.0.1:10022 即间接地连接到了虚拟机的22端口。
![xshell-connect-localhost.png](/img/in-post/xshell-connect-localhost.png)
（此处良心推荐XShell，真心好用）

如果需要连接的虚拟机的端口比较多，每次都配置端口转发会比较麻烦，所以我们可以在此基础上新增一个网卡配置为：**仅主机（Host-Only）配适器**，用于物理机直接连接虚拟机，以及同一主机下的多个虚拟机互联。

VirtualBox 安装时就会配置好VirtualBox Host-Only Network Adapter：
![virtual-box-host-only-adapter.png](/img/in-post/virtual-box-host-only-adapter.png)
![virtual-box-host-only-network-ip-config.png](/img/in-post/virtual-box-host-only-network-ip-config.png)

我们只需要把虚拟机配置为同网段的静态IP即可，例如192.168.56.10/24

两项都配置好的VirtualBox：
![virtual-box-nat.png](/img/in-post/virtual-box-nat.png)
![virtual-box-host-only.png](/img/in-post/virtual-box-host-only.png)


同时虚拟机也需要相应配置，NAT网络设备配置为DHCP，Host Only Adapter配置为静态IP[^1]（详细配置过程见下方）。


### 详细配置过程

先查看网络设备：

```ip addr```

```plain
 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
     inet 127.0.0.1/8 scope host lo
        valid_lft forever preferred_lft forever
     inet6 ::1/128 scope host 
        valid_lft forever preferred_lft forever
 2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
     link/ether 08:00:27:73:b9:5b brd ff:ff:ff:ff:ff:ff
     inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
        valid_lft 85998sec preferred_lft 85998sec
     inet6 fe80::a00:27ff:fe73:b95b/64 scope link 
        valid_lft forever preferred_lft forever
 3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
     link/ether 08:00:27:45:df:f5 brd ff:ff:ff:ff:ff:ff
     inet 192.168.56.10/24 brd 192.168.56.255 scope global enp0s8
        valid_lft forever preferred_lft forever
     inet6 fe80::a00:27ff:fe45:dff5/64 scope link 
        valid_lft forever preferred_lft forever
```

lo是本地回环地址不用管。enp0s3是我们配置的网络设备1(NAT)，enp0s8是网络2 (Host Only Adapter)。

这里的enp0s3和enp0s8都是默认的设备名，我们下面为这两个设备分别建立配置。配置按惯例命名为eth0(对应设备enp0s3)和eth1(对应enp0s8).

OK，召唤出网络配置神器nmtui

```bash
yum install NetworkManager-tui
nmtui
```

高大上的图形界面：
![nmtui-01.PNG](/img/in-post/nmtui-01.PNG)

#### DHCP动态IP的配置

NAT设备enp0s3配置为动态获取IP，默认就是这个，基本不用改什么：
![nmtui-02.PNG](/img/in-post/nmtui-02.PNG)

#### 静态IP的配置

Host Only Adapter设备enp0s8配置为静态IP，如下。**注意IP和网关**的配置：
![nmtui-03.PNG](/img/in-post/nmtui-03.PNG)

需要注意的是，enp0s8配置的IP要以/24为掩码而不是/32，并且网关要**留空**，不要填任何内容。否则主机无法连接虚拟机[^2]。

IP这里我填了 192.168.56.10/24，其实只要在同一个网段且无冲突即可。

配置完flush一下ip，然后重启生效。

```bash
ip addr flush enp0s3
ip addr flush enp0s8
```

#### 连接配置

配置好后虚拟机可以直接连外网，主机可以直接连接虚拟机的IP: 192.168.56.10，虚拟机互联同理。

虚拟机也可以连接主机：10.0.2.2（通过NAT）[^3]或 192.168.56.1（通过Host Only Adapter）

相关文章：VirtualBox 虚拟机和主机的文件共享（待填坑。。）


### 参考文献

[^1]: [VirtualBox: How to set up networking so both host and guest can ... - serverfault](http://serverfault.com/a/333584)
[^2]: [Centos 6.5 NAT dhcp + Host Only Adapter static = no internet - virtualbox.org](https://forums.virtualbox.org/viewtopic.php?f=3&t=63223)
[^3]: [Connect to the host machine from a VirtualBox guest OS? - superuser](http://superuser.com/a/310745)
