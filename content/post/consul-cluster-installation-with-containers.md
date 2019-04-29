---
layout:      post
title:       "容器化部署 Consul 集群"
subtitle:    ""
description: "Consul 是 HashiCorp 公司推出的开源工具，用于实现分布式系统的服务发现与配置。Consul 是分布式的、高可用的、 可横向扩展的。一般 Consul 具有服务发现、健康检查、键值存储以及多数据中心等特性。"
excerpt:     ""
date:        2019-01-27T21:09:35+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/1GodFU.jpg"
published:   true
tags:        ["Docker","Consul"]
categories:  [ "TECH" ]
---

Consul 是 HashiCorp 公司推出的开源工具，用于实现分布式系统的服务发现与配置。Consul 是分布式的、高可用的、 可横向扩展的。它具备以下特性:

- **服务发现**: Consul 提供了通过 DNS 或者 HTTP 接口的方式来注册服务和发现服务。一些外部的服务通过 Consul很容易的找到它所依赖的服务。

- **健康检测**: Consul 的 Client 提供了健康检查的机制，可以通过用来避免流量被转发到有故障的服务上。
- **Key/Value存储**: 应用程序可以根据自己的需要使用Consul提供的Key/Value存储。 Consul提供了简单易用的HTTP接口，结合其他工具可以实现动态配置、功能标记、领袖选举等等功能。
- **多数据中心**: Consul支持开箱即用的多数据中心. 这意味着用户不需要担心需要建立额外的抽象层让业务扩展到多个区域。

Consul 各组件架构图如下图所示：

![Consul 基本架构图](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/q43egM.jpg)

Consul 官方站点：https://www.consul.io

Consul GitHub 站点：https://github.com/hashicorp/consul

Consul 官方镜像：https://hub.docker.com/r/_/consul/

Consul 官方镜像 Dockerfile 文件可以参考：[consul dockerfile](https://github.com/hashicorp/docker-consul/blob/3e9120657c15e2f208e3cf16a698f1bb3bee3cdd/0.X/Dockerfile)

本文档主要部署基于三个 server 和 一个 node 的 consul 集群，集群机器环境如下：

```
consul-server1  172.16.8.120
consul-server2  172.16.8.121
consul-server3  172.16.8.122
consul-client1  172.16.8.110
```

安装和配置 docker 这里不再赘述，具体安装过程参见官方文档：[Docker Installation](https://docs.docker.com/glossary/?term=installation)

默认 docker 拉取镜像用的是 docker hub ，在国内拉取镜像速度非常慢，建议配置 docker 镜像加速器，具体配置过程参见：https://yeaheo.com/post/docker-image-accelerator-installation

上述配置完成后，开始用 docker 部署 consul 集群，具体过程参考如下：

在所有机器上拉取相关镜像：

```bash
👍 ~ docker pull consul:latest
👍 ~ docker pull gliderlabs/registrator:latest
```

Consul 默认常用的端口如下：

```bash
dns       8600.
http      8500.
https     disabled
rpc       8400.
serf_lan  8301.
serf_wan  8302.
server    8300.
```

为了更友好的利用这些端口，建议容器的网络模式选择 `--net=host` 模式。

### 部署 consul-server1

在该主机上执行如下命令启动相关容器：

```bash
👍 ~ docker run -d --name=consul-server1 \
     --net=host \
     --restart=always \
     -h consul-server1 \
     consul agent \
     -server \
     -bind=172.16.8.120 \
     -bootstrap-expect=2 \
     -node=consul-server1 \
     -data-dir=/tmp/data-dir \
     -client 0.0.0.0 \
     -ui
```

查看容器启动日志可以参考如下命令：

```bash
👍 ~ docker logs -f consul-server1
```

> 因为使用了`-bootstrap-expect=2` 参数，所以当 `server` 数量达到 `3` 个之前 consul 是不会引导集群的，当然也不会选出某一个 `leader` 

至此，consul-server1 部署基本完成。



### 部署 consul-server2

和部署 consul-server1 类似，部署 consul-server2 时利用如下命令即可：

```bash
👍 ~ docker run -d --name=consul-server2 \
     --net=host \
     --restart=always \
     -h consul-server2 \
     consul agent \
     -server \
     -bind=172.16.8.121 \
     -join=172.16.8.120 \
     -bootstrap-expect=2 \
     -node=consul-server2 \
     -data-dir=/tmp/data-dir \
     -client 0.0.0.0 \
     -ui
```

查看容器启动日志可以参考如下命令：

```bash
👍 ~ docker logs -f consul-server1
```

至此，consul-server2 部署基本完成。



### 部署 consul-server3

和部署 consul-server1 类似，部署 consul-server3 时利用如下命令即可：

```bash
👍 ~ docker run -d --name=consul-server3 \
     --net=host \
     --restart=always \
     -h consul-server3 \
     consul agent \
     -server \
     -bind=172.16.8.122 \
     -join=172.16.8.120 \
     -bootstrap-expect=2 \
     -node=consul-server3 \
     -data-dir=/tmp/data-dir \
     -client 0.0.0.0 \
     -ui
```

查看容器启动日志可以参考如下命令：

```bash
👍 ~ docker logs -f consul-server1
```

至此，consul-server3 部署基本完成。 

当三个 server 主机启动后， consul 就可以引导整个集群了，并且三个 server 之间通过 GRAF 机制选举出一个 leader 角色用来维护整个集群功能。集体选举过程可以通过日志查看到。

日志实例可以参考下面内容：

```bash
  ...
  2018/10/29 04:03:09 [ERR] agent: Coordinate update error: No cluster leader
  2018/10/29 04:03:18 [ERR] agent: failed to sync remote state: No cluster leader
  2018/10/29 04:03:38 [ERR] agent: Coordinate update error: No cluster leader
  2018/10/29 04:03:40 [INFO] serf: EventMemberJoin: consul-server3 10.200.100.218
  2018/10/29 04:03:40 [INFO] consul: Adding LAN server consul-server3 (Addr: tcp/10.200.100.218:8300) (DC: dc1)
  2018/10/29 04:03:40 [INFO] consul: Existing Raft peers reported by consul-server3, disabling bootstrap mode
  2018/10/29 04:03:40 [INFO] serf: EventMemberJoin: consul-server3.dc1 172.16.8.122
  2018/10/29 04:03:40 [INFO] consul: Handled member-join event for server "consul-server3.dc1" in area "wan"
  2018/10/29 04:03:48 [DEBUG] raft-net: 10.200.100.231:8300 accepted connection from: 10.200.100.218:37071
  2018/10/29 04:03:48 [WARN] raft: Failed to get previous log: 1 log not found (last: 0)
  2018/10/29 04:03:48 [INFO] consul: New leader elected: consul-server3
  2018/10/29 04:03:48 [INFO] agent: Synced node info
  ...
```



### 部署 consul-client1

其实，部署 client 和部署 server 类似，都是通过 `consul agent` 来部署，只是他们在 consul 层面扮演的角色不同而已。

部署 consul-client 用如下命令即可：

```bash
👍 ~ docker run -d --name=consul-client1 \
     --net=host \
     --restart=always \
     -h consul-client1 \
     consul agent \
     -bind=172.16.8.110 \
     -retry-join=172.16.8.120 \
     -node=consul-client1 \
     -client 0.0.0.0 \
     -ui
```

查看 clinet 日志参考：

```bash
👍 ~ docker logs -f consul-client1
```

至此，consul 集群也就部署完成了，3 个 server 和 1 个 client。



### 查看集群状态

我们可以用如下命令查看集群状态和成员：

```bash
👍 ~ docker exec consul-server1 consul members
Node            Address            Status  Type    Build  Protocol  DC   Segment
consul-server1  172.16.8.120:8301  alive   server  1.3.0  2         dc1  <all>
consul-server2  172.16.8.121:8301  alive   server  1.3.0  2         dc1  <all>
consul-server3  172.16.8.122:8301  alive   server  1.3.0  2         dc1  <all>
consul-client1  172.16.8.110:8301  alive   client  1.3.0  2         dc1  <default>
```

我们也可以通过 http 接口查看集群状态信息：

```bash
# 查看集群 leader
👍 ~ curl http://172.16.8.110:8500/v1/status/leader
"172.16.8.120:8300"

# 查看集群成员
👍 ~ curl http://172.16.8.110:8500/v1/status/peers
["172.16.8.120:8300","172.16.8.121:8300","172.16.8.122:8300"]

# 查看某个服务
👍 ~ curl http://172.16.8.110:8500/v1/catalog/service/redis

# 查看某个服务的健康状态
👍 ~ curl http://172.16.8.110:8500/v1/health/service/nginx?passing
```

当然，我们也可以通过 consul 自带的 ui 界面查看集群信息，默人 ui 访问地址：http://172.16.8.120:8500 ，具体页面参考如下：

![consul web ui](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/9ETA0M.jpg)

至此，整个 consul 集群部署完成。如果需要其他方式部署 consul 集群可以查阅 consul 官方文档：https://www.consul.io/docs/install/index.html

> 如果 consul 集群用在生产环境需要认真考虑数据持久性

之后我们还需要用到 `registrator` 配合 `consul` 来实现服务自动注册和发现。