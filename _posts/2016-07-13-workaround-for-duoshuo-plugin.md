---
layout:     post
title:      多说分享插件显示undefined的解决方案
subtitle:   ""
date:       2016-07-12 19:20
author:     wings27
header-img: "img/tag-javascript.jpg"
tags:
    - javascript
---


## 目录
{:.no_toc}

- toc
{:toc}


## 问题

多说分享插件有某些分享渠道显示为undefined，如图：

![duoshuo-share-bug](/img/in-post/duoshuo-share-bug.png)

该bug官方已经确认[^1]，但只在unstable版本做了修复。stable版本暂未修复。

P.S. stable版就是我们都在用的： http://static.duoshuo.com/embed.js


## 解决方案

在触发分享列表时手动填充名字。（已有的名字也可以改变哦~）

把如下代码扔到分享插件所在页面的随便一个script标签下即可。

```javascript
$(document).one('mouseover', 'li[data-toggle="ds-share-icons-more"]', function () {
    var dataService2Text = {
        'netease': '网易',
        'mogujie': '蘑菇街',
        'meilishuo': '美丽说',
        'taobao': '淘宝',
        'diandian': '点点',
        'huaban': '花瓣',
        'duitang': '堆糖',
        'youdao': '有道',
        'pengyou': '朋友网',
        'msn': 'MSN',
        'google': 'Google+'
    };

    $.each(dataService2Text, function (key, value) {
        $('a[data-service="' + key + '"]').text(value);
    });
});
```

完整代码可以参考我的github: [wings27-blog.js](https://github.com/wings27/wings27.github.io/blob/master/js/wings27-blog.js#L67)

最终效果：

![duoshuo-share-bug](/img/in-post/duoshuo-share-bug-fixed.png)

另一个方案是选用unstable版的插件，已经修复了这个问题。但是unstable版不够稳定，而且取消了鼠标悬停的触发，个人不建议使用。


## 更新

最新消息，多说已经挂掉不运营了。全站改为vssue.


## 参考文献

[^1]: [为什么我的多说分享插件，今天打开突然出现好多undefined？](http://dev.duoshuo.com/threads/56519db55ca0552a02d706b8)
