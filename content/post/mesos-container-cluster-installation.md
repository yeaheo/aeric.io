---
layout:      post
title:       "容器化部署 Mesos 集群"
subtitle:    ""
description: "整个 mesos 集群主要由 Zookeeper、Mesos、Marathon 和 Docker 几个组件构成,本次部署的是基于三个 master 和一个 salve 的 mesos 集群，实现高可用，高扩展性"
excerpt:     ""
date:        2018-12-06T16:34:08+08:00
author:      Eric
image:       "https://wx4.sinaimg.cn/large/b258d7f7ly1fxx45wx20rj21ja0loh0x.jpg"
published:   true
tags:        ["Docker","Mesos","Zookeeper"]
categories:  [ TECH ]
---

整个 mesos 集群主要由 Zookeeper、Mesos、Marathon 和 Docker 几个组件构成，各组件用途及扮演的角色信息如下所示：

- **Zookeeper:** Zookeeper 是一个分布式的，开放源码的分布式应用程序协调服务，是 Google 的 Chubby 一个开源的实现，是 Hadoop 和 Hbase 的重要组件。它是一个为分布式应用提供一致性服务的软件，提供的功能包括：配置维护、名字服务、分布式同步、组服务等。
- **Mesos:** Mesos 采用与 Linux kernerl 相同的机制，只是运行在不同的抽象层次上。Mesos kernel 利用资源管理和调度的 API 在整个数据中心或云环境中运行和提供引用（例如，Hadoop，Spark，Kafaka，Elastic Search）。
- **Marathon:** Marathon是一个 Mesos 应用框架，能够支持运行长服务，比如 web 应用等。是集群的分布式Init.d，能够原样运行任何 Linux 二进制发布版本，如 Tomcat Play 等等，可以集群的多进程管理。也是一种私有的 PaaS，实现服务的发现，为部署提供提供 REST API 服务，有授权和 SSL、配置约束，通过 HAProxy 实现服务发现和负载平衡。
- **Docker:** Docker 是一个开源的应用容器引擎，让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，然后发布到任何流行的 Linux 机器上，也可以实现虚拟化。

本文档旨在利用容器（docker）部署 Mesos 集群，包括 Zookeeper 集群同样也利用 docker 部署。

### Zookeeper 集群部署

Zookeeper 集群主机环境及软件版本如下所示：

```bash
# 集群主机环境
server.1  10.70.0.10
server.2  10.70.0.11
server.3  10.70.0.12

# 集群版本
Zookeeper v3.4.12
```

在部署 zookeeper 集群前需要先创建 zookeeper 的配置文件目录和数据存储目录，可以参考如下：

```bash
mkdir -pv /opt/zookeeper/conf
mkdir -pv /opt/zookeeper/data
```

准备 Zookeeper 配置文件：

```bash
cat /opt/zookeeper/conf/zoo.cfg << EOF
dataDir=/data
clientPort=2181
initLimit=5
syncLimit=2
server.1=10.70.0.10:2888:3888
server.2=10.70.0.11:2888:3888
server.3=10.70.0.12:2888:3888
```

添加节点识别文件：

```bash
# server 1
echo 1 > /opt/zookeeper/data/myid

# server 2
echo 2 > /opt/zookeeper/data/myid

# server 3
echo 3 > /opt/zookeeper/data/myid
```

拉取 Zookeeper 镜像：

```bash
docker pull zookeeper:3.4.12
```

启动相关容器：

```bash
docker run --name zookeeper -d --net host -v /opt/zookeeper/logs:/opt/zookeeper/logs -v /opt/zookeeper/conf/zoo.cfg:/conf/zoo.cfg -v /opt/zookeeper/data:/data --restart=always  zookeeper:3.4.12
```

验证集群，了解主从情况:

```bash
echo stat | nc 10.70.0.10  2181
echo stat | nc 10.70.0.11  2181
echo stat | nc 10.70.0.12  2181   
```



### Mesos-master 集群部署

Mesos-master 集群主机环境及软件版本如下：

```bash
# 集群主机环境
mesos-master-1 10.70.0.10
mesos-master-2 10.70.0.11
mesos-master-3 10.70.0.12

# 软件版本
mesos v1.5.0
marathon v1.5.8
```

首先我们需要将本机的 IP 地址赋值个 `HOST_IP`变量，最好的方法是通过修改 `/etc/profile`文件将其写入到全局变量中。编辑 `/etc/profile`文件，写入如下内容：

```bash
export HOST_IP=`ip a|awk -F'/| '+ '/10.70.0/{print $3}'
```

验证全局变量：

```bash
echo $HOST_IP
```

**mesos-1 主机部署 mesos 服务**

```bash
docker run --name mesos-master-01 -d --net=host --restart=always  -e MESOS_PORT=5050  -e "MESOS_HOSTNAME=${HOST_IP}"   -e "MESOS_IP=${HOST_IP}"  -e MESOS_ZK=zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos  -e MESOS_QUORUM=2   -e MESOS_REGISTRY=in_memory   -e MESOS_LOG_DIR=/var/log/mesos   -e MESOS_WORK_DIR=/var/tmp/mesos   -v "$(pwd)/log/mesos:/var/log/mesos"   -v "$(pwd)/tmp/mesos:/var/tmp/mesos"  mesosphere/mesos-master:1.5.0
```

**mesos-2 主机部署 mesos 服务**

```bash
docker run --name mesos-master-02 -d --net=host --restart=always  -e MESOS_PORT=5050  -e "MESOS_HOSTNAME=${HOST_IP}"   -e "MESOS_IP=${HOST_IP}"  -e MESOS_ZK=zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos  -e MESOS_QUORUM=2   -e MESOS_REGISTRY=in_memory   -e MESOS_LOG_DIR=/var/log/mesos   -e MESOS_WORK_DIR=/var/tmp/mesos   -v "$(pwd)/log/mesos:/var/log/mesos"   -v "$(pwd)/tmp/mesos:/var/tmp/mesos"  mesosphere/mesos-master:1.5.0
```

**mesos-3 主机部署 mesos 服务**

```bash
docker run --name mesos-master-03 -d --net=host --restart=always  -e MESOS_PORT=5050  -e "MESOS_HOSTNAME=${HOST_IP}"   -e "MESOS_IP=${HOST_IP}"  -e MESOS_ZK=zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos  -e MESOS_QUORUM=2   -e MESOS_REGISTRY=in_memory   -e MESOS_LOG_DIR=/var/log/mesos   -e MESOS_WORK_DIR=/var/tmp/mesos   -v "$(pwd)/log/mesos:/var/log/mesos"   -v "$(pwd)/tmp/mesos:/var/tmp/mesos"  mesosphere/mesos-master:1.5.0
```

当三台主机的 mesos 服务部署完成后 mesos 集群基本就完成了，可以通过浏览器访问 `http://10.70.0.10:5050`访问 mesos 集群。

### 部署 mesos 集群 Framework Marathon 服务

当我们 mesos 集群部署完成后，该集群还不能正常工作，我们需要安装 marathon 计算框架来调度相关容器， marathon 框架是经过注册的方式接入 mesos 集群的，为了保证其高可用性，本次我们部署三个节点的服务，marathon 可以部署在单独的三台的主机上，但是为了节约系统资源，我选择将其部署在 mesos 集群的三台主机上。

marathon 的主机环境及软件版本如下所示：

```bash
# marathon 主机环境
marathon-1 10.70.0.10
marathon-2 10.70.0.11
marathon-3 10.70.0.12
```

Marathon 也是利用 zookeeper 实现高可用的。本次部署我们用上述搭建的 zookeeper 集群实现 marathon 的高可用。

**marathon-1 上部署 marathon 服务**

```bash
docker run --name marathon-1 -d --net=host --restart=always  -e MARATHON_HTTP_ADDRESS=${HOST_IP}  -e MARATHON_HOSTNAME=${HOST_IP} --master zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos  --zk  zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/marathon mesosphere/marathon:v1.5.8
```

**marathon-2 上部署 marathon 服务**

```bash
docker run --name marathon-2 -d --net=host --restart=always  -e MARATHON_HTTP_ADDRESS=${HOST_IP}  -e MARATHON_HOSTNAME=${HOST_IP} --master zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos  --zk  zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/marathon mesosphere/marathon:v1.5.8
```

**marathon-2 上部署 marathon 服务**

```bash
docker run --name marathon-3 -d --net=host --restart=always  -e MARATHON_HTTP_ADDRESS=${HOST_IP}  -e MARATHON_HOSTNAME=${HOST_IP} --master zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos  --zk  zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/marathon mesosphere/marathon:v1.5.8
```

当 marathon 集群部署完成后，正常情况下，marathon 就可以在 mesos 集群的管理页面看到注册信息及访问地址，marathon 服务默认通过 `8080`端口监听服务，我们可以利用 `http://10.70.0.10:8080`访问到 marathon 的相关界面。

### 部署 mesos-slave 节点服务

mesos 是分为 mesos-master 和 mesos-slave 节点，他们分工不同，具体如下所述：

Mesos-master 是整个系统的核心，负责管理接入mesos的各个framework（由frameworks_manager管理）和 slave（由slaves_manager管理），并将slave上的资源按照某种策略分配给framework（由独立插拔模块Allocator管 理）。

Mesos-slave 负责接收并执行来自 mesos-master 的命令、管理节点上的 mesos-task ，并为各个 task  分配资源。 mesos-slave 将自己的资源量发送给 mesos-master，由 mesos-master 中的 Allocator 模块决定将资源分配给哪个 framework，前考虑的资源有CPU和内存两种，也就是说，mesos-slave 会将CPU个数和内存量发送给mesos-master，而用 户提交作业时，需要指定每个任务需要的CPU个数和内存量，这样，当任务运行时，mesos-slave 会将任务放到包含固定资源的 linux container 中运行，以达到资源隔离的效果。很明显，master 存在单点故障问题，为此，mesos 采用了 zookeeper 解决该问题。

该部分主要是在某台主机上部署 `mesos-slave` 服务,主机环境及软件版本如下：

```bash
# mesos-salve 主机环境
mesos-salve-1 10.70.0.20

# mesos-slave 软件版本
mesos-salve  v1.5.0
```

同样的首先我们需要将本机的 IP 地址赋值个 `HOST_IP`变量，最好的方法是通过修改 `/etc/profile`文件将其写入到全局变量中。编辑 `/etc/profile`文件，写入如下内容：

```bash
export HOST_IP=`ip a|awk -F'/| '+ '/10.70.0/{print $3}'
```

验证全局变量：

```bash
echo $HOST_IP
```

**部署 mesos-slave 服务**

```bash
docker run --name mesos-slave -d --net=host --privileged --restart=always -e "MESOS_IP=${HOST_IP}"  -e "MESOS_HOSTNAME=${HOST_IP}"  -e MESOS_PORT=5051   -e MESOS_MASTER=zk://10.70.0.10:2181,10.70.0.11:2181,10.70.0.12:2181/mesos    -e MESOS_SWITCH_USER=0   -e MESOS_CONTAINERIZERS=docker,mesos   -e MESOS_LOG_DIR=/var/log/mesos   -e MESOS_WORK_DIR=/var/tmp/mesos   -v "$(pwd)/log/mesos:/var/log/mesos"   -v "$(pwd)/tmp/mesos:/var/tmp/mesos"   -v /var/run/docker.sock:/var/run/docker.sock   -v /cgroup:/cgroup   -v /sys:/sys   -e "MESOS_SYSTEMD_ENABLE_SUPPORT=false" mesosphere/mesos-slave:1.5.0
```

当 mesos-slave 部署完成后就可以通过 mesos 集群的管理页面看到注册到集群的 `mesos-agent`了，至此，整个 mesos 集群就部署完成了

> 在生产环境中，建议部署多个 agent 节点，保证应用的高可用性