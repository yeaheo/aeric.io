---
layout:      post
title:       "Harbor 私有镜像仓库安装配置"
subtitle:    ""
description: "Harbor 是存放镜像的私有仓库，我们在企业内为了能更好的管理我们的业务镜像，我们可以将其上传至我们的私有镜像仓库，本次利用 Harbor 搭建自己的私有镜像仓库"
excerpt:     ""
date:        2019-01-10T11:37:01+08:00
author:      Aeric
image:       "https://wx4.sinaimg.cn/large/b258d7f7ly1g0ngh35u98j21ja0lo1b6.jpg"
published:   true
tags:        ["Harbor","Docker","Docker-compose"]
categories:  [ "TECH" ]
---

在一个企业里，企业自有的私有仓库是必须的，配置私有 docker 镜像仓库 harbor，为的是将自己构建的镜像 push 到私有镜像仓库中，方便以后拉取。

Harbor 的官方站点: <https://goharbor.io/>

Harbor 的 GitHub 地址: <https://github.com/goharbor/harbor>

Harbor 的安装和配置可以参考: [Installation and Configuration Guide](https://github.com/goharbor/harbor/blob/master/docs/installation_guide.md)

Harbor 的安装方式有在线安装和离线安装两种，由于网络的问题，本次安装采用离线安装的方式搭建私有镜像仓库。

安装 Harbor 需要满足以下软件条件：

| Software       | Version                 | Description                                                  |
| -------------- | ----------------------- | ------------------------------------------------------------ |
| Python         | version 2.7 or higher   | Note that you may have to install Python on Linux distributions (Gentoo, Arch) that do not come with a Python interpreter installed by default |
| Docker engine  | version 1.10 or higher  | For installation instructions, please refer to: https://docs.docker.com/engine/installation/ |
| Docker Compose | version 1.6.0 or higher | For installation instructions, please refer to: https://docs.docker.com/compose/install/ |
| Openssl        | latest is preferred     | Generate certificate and keys for Harbor                     |

## 下载离线安装包

首先需要从 [Harbor 的官方下载地址](https://github.com/goharbor/harbor/releases) 下载我们需要安装的软件离线安装包，harbor 服务具体安装步骤如下：

```bash
1、下载并解压软件包;
2、配置 `harbor.cfg` 文件;
3、执行脚本文件 `install.sh` 进行安装;
```

下载离线安装包如下：

```bash
$ mkdir /opt/soft
$ cd /opt/soft
$ wget https://storage.googleapis.com/harbor-releases/release-1.7.0/harbor-offline-installer-<HARBOR_VERSION>.tgz
```

解压安装包至指定安装目录：

```bash
$ cd /opt/soft
$ tar xvf harbor-offline-installer-<HARBOR_VERSION>.tgz -C /srv/
# harbor 安装目录为 /srv/ 目录

$ cd /srv/
```

## 准备 Harbor 配置文件

这里我们只是简单的安装 Harbor 如果需要更个性化的配置 harbor 可以参考 [Installation and Configuration Guide](https://github.com/goharbor/harbor/blob/master/docs/installation_guide.md)

在这里，我们只需要修改以下参数：

```bash
......
hostname = 192.168.8.69
......
harbor_admin_password = admin123.
......
```

> `harbor.cfg` 只需要修改 hostname 为你自己的机器 IP 或者域名，harbor 默认的 db 连接密码为 root123，可以自己修改，也可以保持默认，harbor 初始管理员密码为 Harbor12345，可以根据自己需要进行修改，email 选项是用来忘记密码重置用的，根据实际情况修改，如果使用 163 或者 qq 邮箱等，需要使用授权码进行登录，此时就不能使用密码登录了，否则会提示无效。

Harbor 的配置文件还是比较简单的。如果需要配置 Harbor 支持 HTTPS 可以参考 [Configuring Harbor with HTTPS Access](https://github.com/goharbor/harbor/blob/master/docs/configure_https.md)

## 执行相关脚本安装 Harbor

配置文件修改完成后就可以执行安装脚本安装 Harbor 相关服务了：

```bash
$ cd /srv/harbor
$ ./install.sh
```

等待安装过程即可，因为是离线安装，速度还是不错的。如果需要自定义安装 Harbor 的其他功能可以参考 [Configuration Guide](https://github.com/goharbor/harbor/blob/master/docs/installation_guide.md)

待脚本执行完成后使用 docke-compose ps 即可查看，常用命令包含以下几个：

```bash
docker-compose up -d      # 后台启动，如果容器不存在根据镜像自动创建
docker-compose down -v    # 停止容器并删除容器
docker-compose start      # 启动容器，容器不存在就无法启动，不会自动创建镜像
docker-compose stop       # 停止容器
```

> 其实上面是停止 `docker-compose.yml` 中定义的所有容器，默认情况下 `docker-compose`就是操作同目录下的 `docker-compose.yml`文件，所以我们需要切换到 harbor 目录下才可以执行 docker-compose 相关命令，如果使用其他 `yml`文件，可以使用 `-f` 自己指定。

至此，harbor 基本安装完成！

