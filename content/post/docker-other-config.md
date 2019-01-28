---
layout:      post
title:       "Docker 服务的一些常用配置"
subtitle:    ""
description: "在日常使用 docker 的过程中，一般 docker 默认的配置不能满足我们正常的业务需要，这个时候就需要我们对 docker 做一些其他的配置来实现我们的需求或者功能"
excerpt:     ""
date:        2018-07-29T21:36:09+08:00
author:      Aeric
image:       "https://wx1.sinaimg.cn/large/b258d7f7ly1fy64d8h12nj21ja0lodoc.jpg"
published:   true
tags:        ["Docker"]
categories:  [ "TECH" ]
---

## 同步容器与宿主机时间

在 Docker 容器创建好之后，可能会发现容器时间跟宿主机时间不一致，这就需要同步它们的时间，让容器时间跟宿主机时间保持一致。

宿主机时间：

```bash
[root@ceph-node1 ~]# date
2017年 07月 30日 星期日 13:46:52 CST
```
容器时间：

```bash
[root@ceph-node1 ~]# docker run -i -t centos:latest /bin/bash
[root@0ce1de90e209 /]# date
Sun Jul 30 05:47:14 UTC 2017
```
发现两者之间的时间相差了八个小时！

宿主机采用了 CST 时区，CST 应该是指（China Shanghai Time，东八区时间）

容器采用了 UTC 时区，UTC 应该是指（Coordinated Universal Time，标准时间）

### 时间同步方式

**方法1：共享主机的 localtime**

创建容器的时候指定启动参数，挂载 localtime 文件到容器内，保证两者所采用的时区是一致的。

示例如下：

```bash
[root@ceph-node1 ~]# docker run -i -t --name my-httpd -v /etc/localtime:/etc/localtime:ro centos:httpd /bin/bash
[root@be91e9bd5d95 /]# date
Sun Jul 30 14:01:53 CST 2017
```
**方法2：复制主机的 localtime**

示例如下：

修改前

```bash
[root@ceph-node1 ~]# docker run -i -t centos:latest /bin/bash
[root@0ce1de90e209 /]# date
Sun Jul 30 05:47:14 UTC 2017
```
修改后

```bash
[root@ceph-node1 ~]# docker cp /etc/localtime 9ec4c03133dd:/etc
[root@ceph-node1 ~]# docker start 9ec4c03133dd
9ec4c03133dd
[root@ceph-node1 ~]# docker attach 9ec4c03133dd
[root@9ec4c03133dd /]# date
Sun Jul 30 14:05:25 CST 2017
```
**方法3：创建 dockerfile 文件的时候，自定义该镜像的时间格式及时区。**

在 dockerfile 文件里添加下面内容，示例 dockerfile 文件如下：

```bash
......
#设置时区
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone
......
```
用 dockerfile 制作镜像：

```bash
[root@ceph-node1 centos]# docker build -t centos:zone .
[root@ceph-node1 centos]# docker run -i -t centos:zone /bin/bash
[root@5d143e9813f7 /]# date
Sun Jul 30 13:49:42 CST 2017
```
> 使用 dokcerfile 生成的镜像的容器改变了容器的时区，这样不仅保证了容器时间与宿主机时间一致，并且如果用 tomcat 镜像作为基础镜像的话，JVM 的时区也是和宿主机保持一致，前两种方法只是保证了素质宿主机时间与容器时间一致，JVM 的时区并没有该 Bain， tomcat 打印的日志不会改变。

## 配置容器一直运行

有时候我们需要的是当 docker 服务重启后以前运行的容器依然在运行，但是官方默认的是当 docker 服务停止后，以前运行的容器就会停止，需要重新启动

Docker 官方参考链接：<https://docs.docker.com/engine/admin/live-restore>

在 Linux 系统中 Docker 服务默认的配置文件是 `/etc/docker/daemon.json`

编辑 `/etc/docker/daemon.json` 增加如下内容：

```bash
{
  "live-restore": true
}
```
修改完成，重启 docker 使其生效即可

```bash
systemctl restart docker.service
```