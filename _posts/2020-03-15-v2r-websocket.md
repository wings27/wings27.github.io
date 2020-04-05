---
layout:     post
title:      "搭建v2ray上科学网"
subtitle:   "使用https+websocket，有效防止IP被墙"
date:		2020-03-15 12:00
author:     "wings27"
header-img: "img/tag-bg.jpg"
license:    true
tags:
    - network
---

## 目录
{:.no_toc}

- toc
{:toc}


## 买买买

购买VPS、域名，并配置域名的CNAME/A记录等。

[推荐一个比较靠谱的服务商: Vultr](https://www.vultr.com/?ref=7267152)，New York (NJ)地区每月3.5刀，按实际使用时长付费。

tips：使用以上购买链接可获得10刀。

## 安装nginx

登录VPS服务器。

`yum install -y epel-release && yum install -y nginx`


## 配置防火墙

防火墙开启HTTP80端口和HTTPS443端口

```bash
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --reload
```


## 安装certbot用于获取证书

[参考：安装certbot的官方教程](https://certbot.eff.org/lets-encrypt/centosrhel8-nginx)

```bash
wget https://dl.eff.org/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto
```

然后，为nginx安装HTTPS及相关证书配置

`sudo /usr/local/bin/certbot-auto --nginx`

安装过程会提示：

>Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator nginx, Installer nginx
Enter email address (used for urgent renewal and security notices) (Enter 'c' to
cancel):

输入自己的邮箱，用于接收Let's Encrypt的紧急更新和安全公告。继续。

>Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf. You must
agree in order to register with the ACME server at
https://acme-v02.api.letsencrypt.org/directory

以上提示阅读服务条款，选择A同意。

>Would you be willing to share your email address with the Electronic Frontier
Foundation, a founding partner of the Let's Encrypt project and the non-profit
organization that develops Certbot? We'd like to send you email about our work
encrypting the web, EFF news, campaigns, and ways to support digital freedom.

以上是否和EFF组织分享邮件地址，这个随便选。

>No names were found in your configuration files. Please enter in your domain
name(s) (comma and/or space separated)  (Enter 'c' to cancel):

按提示输入申请好的域名，没有的去godaddy上买。

继续后，如果提示Challenge failed for domain xxx，一般是防火墙没有开放端口导致的。

正常的输出如下：

>Please choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.

>1: No redirect - Make no further changes to the webserver configuration.

>2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
new sites, or if you're confident your site works on HTTPS. You can undo this
change by editing your web server's configuration.

>Select the appropriate number [1-2] then [enter]:

此时输入2，代表重定向所有HTTP请求到HTTPS.

出现Congratulations代表成功。证书安装成功后，按官方推荐，配置证书自动更新job，防止证书过期。

`echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null`


## 配置nginx

检查nginx配置（一般为/etc/nginx/nginx.conf）

某些情况下，certbot自动化脚本会额外新增两个server：80和443，而原有的server 80的配置还在。

因此需要检查下，确保server只有两个，listen 80的是HTTP，listen 443的是HTTPS，多余的server配置注释掉。

正确的配置类似于：



```nginx
    # HTTP请求，收到请求直接跳转到HTTPS:
    server {
    if ($host = 域名) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


        listen       80 ;
        listen       [::]:80 ;
    server_name 域名;
    return 404; # managed by Certbot
```


```nginx
    # HTTPS请求，正常处理:
    server {
    server_name 域名; # managed by Certbot
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }


    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/域名/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/域名/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

```

执行`nginx -s reload`重载配置，如果提示`nginx: [error] open() "/run/nginx.pid" failed (2: No such file or directory)`，

说明有nginx被启动了但是没有记录pid，此时手动重启一下nginx：

```bash
kill nginx主进程ID
systemctl enable nginx
systemctl restart nginx
systemctl status nginx
```

启动后服务状态显示为Active(running). 则表示正常启动。

此时浏览器直接输入自己的域名，会自动跳转HTTPS，并且页面为nginx测试页。


## 安装v2ray

采用[v2ray官方](https://www.v2ray.com/chapter_00/install.html)的一键脚本进行安装。

`bash <(curl -L -s https://install.direct/go.sh)`

此脚本会自动安装以下文件：

>/usr/bin/v2ray/v2ray：V2Ray 程序；

>/usr/bin/v2ray/v2ctl：V2Ray 工具；

>/etc/v2ray/config.json：配置文件；

>/usr/bin/v2ray/geoip.dat：IP 数据文件

>/usr/bin/v2ray/geosite.dat：域名数据文件

>此外还会配置自动运行脚本。

修改v2ray配置，参考[v2ray白话文教程WS+TLS+Web](https://toutyrater.github.io/advanced/wss_and_web.html)

需要注意的是按照教程修改nginx配置时，不要修改ssl证书相关配置，只需要新增location配置即可。

服务器 V2Ray 配置示例：

```json
{
  "log": {
  	"access": "/var/log/v2ray/access.log",
  	"error": "/var/log/v2ray/error.log",
  	"loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10000,
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "b831381d-6324-4d53-ad4f-8cda48b30811",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}

```


Nginx 配置示例：

```nginx
server {
        location /ray { # 与 V2Ray 配置中的 path 保持一致
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;#与 V2Ray 配置中的 port 保持一致
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;

        # Show realip in v2ray access.log
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}
```

`nginx -t`测试配置是否正确

`nginx -s reload`重载使配置生效


## 开启安全策略

开启Linux安全策略，允许nginx转发流量到内网：

`setsebool -P httpd_can_network_connect 1`

## 客户端配置

安卓建议用Bifrostv，Mac建议ClashX(强大)或v2rayU(易用)


