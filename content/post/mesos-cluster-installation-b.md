---
layout:      post
title:       "Mesos集群二进制方式部署二 "
subtitle:    ""
description: "本次 Mesos 集群部署主要基于Zookeeper+Mesos+Marathon+Docker，各个组件均需单独部署并配置，具体安装配置过程可以参考如下过程，"
excerpt:     ""
date:        2019-01-12T20:44:13+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/zRmwCh.jpg"
published:   true
tags:        ["Docker","Mesos","Marathon"]
categories:  [ "TECH" ]
---

本次部署基于 Zookeeper+Mesos+Marathon+Docker，具体部署环境如下：

```bash
mesos-master1   172.16.8.120   mesos+zookeeper+marathon
mesos-master2   172.16.8.121   mesos+zookeeper+marathon
mesos-master3   172.16.8.122   mesos+zookeeper+marathon
mesos-slave1    172.16.8.110   mesos+docker
```

上述所有机器系统版本如下：

```bash
[root@mesos-master1 ~]# java -version
openjdk version "1.8.0_191"
OpenJDK Runtime Environment (build 1.8.0_191-b12)
OpenJDK 64-Bit Server VM (build 25.191-b12, mixed mode)
```

```bash
[root@mesos-master1 ~]# uname -r
4.19.0-1.el7.elrepo.x86_64
[root@mesos-master1 ~]# cat /etc/redhat-release 
CentOS Linux release 7.5.1804 (Core) 
```

> 在部署基本组件之前需要先配置好各个机器上的 Java 环境，这里不再赘述

所有主机上的 `hosts` 文件如下所示：

```bash
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.8.110 mesos-slave1
172.16.8.120 mesos-master1
172.16.8.121 mesos-master2
172.16.8.122 mesos-master3
```



### 安装并配置 Zookeeper

Zookeeper 的安装方式有多种，常用的一般是用源码二进制的方式（tar包）安装，另一种是直接用 yum 安装。

二进制方式安装可以参考：https://www.jianshu.com/p/950fb55ea53a

为了可以安装较新版本的 zookeeper 本次安装使用二进制方式安装，具体内容如下：

Zookeeper 的官方站点：https://zookeeper.apache.org/

Zookeeper 的官方下载地址：https://zookeeper.apache.org/releases.html 我们可以在官方站点下载我们需要的版本即可。

#### 下载 zookeeper 

```bash
$ wget http://apache.01link.hk/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz
$ tar xf zookeeper-3.4.13.tar.gz -C /srv/
```

#### 配置 Zookeeper

我们需要在所有 master 节点上手动创建 zookeeper 的数据及日志存放目录：

```bash
$ mkdir -pv /data/zookeeper/{data,logs}
```

准备 zookeeper 的配置文件：

```bash
$ cp /srv/zookeeper-3.4.13/conf/zoo_sample.cfg /srv/zookeeper-3.4.13/conf/zoo.cfg

# 修改配置文件内容如下：
$ cat /srv/zookeeper/conf/zoo.cfg | grep -v '^#' | grep -v '^$'
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/data
dataLogDir=/data/zookeeper/logs
clientPort=2181
server.1=mesos-master1:2888:3888
server.2=mesos-master2:2888:3888
server.3=mesos-master3:2888:3888
```

> 所有节点上的配置文件一致

准备 myid 文件：

```bash
# mesos-master1上执行
echo '1' > /data/zookeeper/data/myid

# mesos-master2上执行
echo '2' > /data/zookeeper/data/myid

# mesos-master3上执行
echo '3' > /data/zookeeper/data/myid
```

配置完成后就可以启动 zookeeper 服务了：

```bash
$ systemctl start zookeeper.service
```

> 三台机器上均需要启动 zookeeper 服务



### 安装配置 Mesos-Master 节点

在所有 master 机器上执行如下命令安装 mesos 和 marathon：

```bash
$ rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-3.noarch.rpm
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mesosphere
$ yum -y install mesos marathon
```

> 有时候安装的 marathon 软件包不是我们需要的，这个是因为我们的 yum 源不对，只需将对应的 yum 源禁用,重新安装即可

安装完成的相关软件包如下所示：

```bash
$ rpm -qa | grep -E 'mesos|marathon'
mesos-1.7.0-2.0.3.x86_64
mesosphere-el-repo-7-3.noarch
marathon-1.4.13-1.0.683.el7.x86_64
```

安装完成后需要我们配置 mesos ，mesos 的高可用配置是由 zookeeper 实现的，所以需要配置 zookeeper，具体操作如下：

```bash
# 在所有 master 上执行
$ vim /etc/mesos/zk
zk://mesos-master1:2181,mesos-master2:2181,mesos-master3:2181/mesos
```

设置文件`/etc/master-/quorum`内容为一个大于（master节点数除以2）的整数。即采用四舍五入，比如这里有3个master节点，那么3/2=1.5，四舍五入为2

```bash
# 在所有 master 上执行
$ echo 2 > /etc/mesos-master/quorum
```

设置 mesos 集群 `hostname` 和集群名称

```bash
# 在 mesos-master1 上执行
$ echo 172.16.8.120 > /etc/mesos-master/hostname
$ echo Mesos-Cluster > /etc/mesos-master/cluster

# 在 mesos-master2 上执行
$ echo 172.16.8.121 > /etc/mesos-master/hostname
$ echo Mesos-Cluster > /etc/mesos-master/cluster

# 在 mesos-master3 上执行
$ echo 172.16.8.122 > /etc/mesos-master/hostname
$ echo Mesos-Cluster > /etc/mesos-master/cluster
```

配置完成后就可以启动 mesos-master 服务了：

```bash
$ systemctl start mesos-master
```

服务启动后可以通过浏览器访问 mesos 的界面：http://172.16.8.120:5050



### 配置 Marathon

在上述安装 mesos 的时候已经安装了 marathon，这里只需配置即可（所有 mesos-master 机器均执行）。

创建 marathon 配置文件目录：

```bash
# 在所有master上执行
$ mkdir -pv /etc/marathon/conf

# 在mesos-master1上执行
$ echo 172.16.8.120 > /etc/marathon/conf/hostname
$ cp  /etc/mesos/zk   /etc/marathon/conf/master
$ cp  /etc/mesos/zk   /etc/marathon/conf/zk

# 修改相关文件
$ vim /etc/marathon/conf/zk
zk://mesos-master1:2181,mesos-master2:2181,mesos-master3:2181/marathon

# 在mesos-master2上执行
$ echo 172.16.8.121 > /etc/marathon/conf/hostname
$ cp  /etc/mesos/zk   /etc/marathon/conf/master
$ cp  /etc/mesos/zk   /etc/marathon/conf/zk

# 修改相关文件
$ vim /etc/marathon/conf/zk
zk://mesos-master1:2181,mesos-master2:2181,mesos-master3:2181/marathon

# 在mesos-master3上执行
$ echo 172.16.8.122 > /etc/marathon/conf/hostname
$ cp  /etc/mesos/zk   /etc/marathon/conf/master
$ cp  /etc/mesos/zk   /etc/marathon/conf/zk

# 修改相关文件
$ vim /etc/marathon/conf/zk
zk://mesos-master1:2181,mesos-master2:2181,mesos-master3:2181/marathon
```

配置完成后就可以起相应的服务了：

```bash
$ systemctl start marathon.service
```

marathon 默认监听 8080 端口，也可以通过浏览器访问其界面：http://172.16.8.120:8080



### 配置 Mesos-Slave 节点

mesos-slave 也需要安装 mesos，不需要安装 marathon，首先引入 mesos 的 yum 源：

```bash
$ rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-3.noarch.rpm
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mesosphere
```

安装 mesos 软件包：

```bash
$ yum -y install mesos
```

安装完成后 mesos-slave 的配置文件默认在 `/etc/mesos-slave` 目录下，需要自定义配置：

```bash
$ echo 172.16.8.110 > /etc/mesos-slave/hostname
```

配置 mesos-master 信息：

```bash
$ vim /etc/mesos/zk
zk://mesos-master1:2181,mesos-master2:2181,mesos-master3:2181/mesos
```

配置 marathon 调用 mesos 运行 docker 容器:

```bash
$ echo 'docker,mesos' > /etc/mesos-slave/containerizers
```

配置完成后，启动 mesos-slave 服务

```bash
$ systemctl start mesos-slave
```

至此，一个 mesos 集群创建完成，全部安装完成后就可以在 mesos 界面看到加入到的 slave 节点。