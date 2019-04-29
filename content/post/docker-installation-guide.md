---
layout:      post
title:       "CentOS 7 安装 Docker"
subtitle:    ""
description: "docker 的安装方式有好多种，除了直接用自带的 yum 源安装外，官方还提供了 docker 各个版本的 yum 源，本次安装选择在 CentOS 7 系统上安装免费版的的 ce 版本"
excerpt:     ""
date:        2018-07-27T21:35:11+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/gfkAWd.jpg"
published:   true
tags:        ["Docker"]
categories:  [ "TECH" ]
---

本次安装的 docker 客户端是 CE 版本，具体安装教程可以参考官方文档： [Docker Installation](https://docs.docker.com/glossary/?term=installation)

## 卸载旧版本 Docker

如果要重新安装 Docker ，首先需要在安装之前卸载之前安装过的 Docker 版本，具体卸载过程可参考如下:

```bash
$ yum remove docker docker-common docker-selinux docker-engine
```
## 准备 Docker yum 仓库

因为直接需要用 yum 安装 docker，所以先要安装一些依赖软件包：

```bash
$ yum install -y yum-utils device-mapper-persistent-data lvm2
```

添加  repo 软件源：

```bash
$ yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

> Enable the edge and testing repositories. These repositories are included in the docker.repo file above but are disabled by default. You can enable them alongside the stable repository.

```bash
$ yum-config-manager --enable docker-ce-edge
$ yum-config-manager --enable docker-ce-testing
```
当然，我们也可以禁用某些版本：

```bash
$ yum-config-manager --disable docker-ce-edge
```
> 以上这些配置都是非必需的，直接引入repo源就可以直接安装 docker

## 安装 Docker 社区版本

引入 repo 源后直接安装即可：

```bash
$ yum -y install docker-ce
```
默认是安装 docker 社区版的最新版本，如果需要安装其他版本可以通过以下命令查看可用的版本：

```bash
$ yum list docker-ce.x86_64  --showduplicates | sort -r
Loading mirror speeds from cached hostfile
docker-ce.x86_64            17.06.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.0.ce-1.el7.centos            @docker-ce-stable
docker-ce.x86_64            17.03.2.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable 
```
安装某个具体的版本可以参考下面的命令：

```bash
$ yum install docker-ce-<VERSION>
```
启动 Docker 服务：

```bash
$ systemctl start docker
```
设置 Docker 开机自启动：

```bash 
$ systemctl enable docker
```
至此， docker 的社区版本已经安装完成，我们可以利用如下命令查看 docker 的具体版本：

```bash
$ docker version 
Client:
 Version:           18.09.1
 API version:       1.39
 Go version:        go1.10.6
 Git commit:        4c52b90
 Built:             Wed Jan  9 19:35:23 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          18.09.1
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.6
  Git commit:       4c52b90
  Built:            Wed Jan  9 19:02:44 2019
  OS/Arch:          linux/amd64
  Experimental:     false
```

