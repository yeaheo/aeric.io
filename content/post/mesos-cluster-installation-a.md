---
layout:      post
title:       "Mesos集群二进制方式部署一"
subtitle:    ""
description: "现有公司一套基础架构主要由 Mesos 集群组成，配合 Marathon 实现容器编排，并利用 Zookeeper 实现 Mesos 和 Marathon 集群的高可用，本文档主要介绍集群中各组件功能"
excerpt:     ""
date:        2019-01-12T20:43:44+08:00
author:      Eric
image:       "https://wx2.sinaimg.cn/large/b258d7f7ly1fz2tcw2doyj21ja0lowqa.jpg"
published:   true
tags:        ["Docker","Mesos","Marathon"]
categories:  [ "TECH" ]
---

私有化 PaaS 平台主要由 Zookeeper、Mesos、Marathon 和 Docker 几个组件构成，各组件用途及扮演的角色信息如下所示：

- **Zookeeper:** Zookeeper 是一个分布式的，开放源码的分布式应用程序协调服务，是 Google 的 Chubby 一个开源的实现，是 Hadoop 和 Hbase 的重要组件。它是一个为分布式应用提供一致性服务的软件，提供的功能包括：配置维护、名字服务、分布式同步、组服务等。
- **Mesos:** Mesos 采用与 Linux kernerl 相同的机制，只是运行在不同的抽象层次上。Mesos kernel 利用资源管理和调度的 API 在整个数据中心或云环境中运行和提供引用（例如，Hadoop，Spark，Kafaka，Elastic Search）。
- **Marathon:** Marathon是一个 Mesos 应用框架，能够支持运行长服务，比如 web 应用等。是集群的分布式Init.d，能够原样运行任何 Linux 二进制发布版本，如 Tomcat Play 等等，可以集群的多进程管理。也是一种私有的 PaaS，实现服务的发现，为部署提供提供 REST API 服务，有授权和 SSL、配置约束，通过 HAProxy 实现服务发现和负载平衡。
- **Docker:** Docker 是一个开源的应用容器引擎，让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，然后发布到任何流行的 Linux 机器上，也可以实现虚拟化。

为了更好的使用上述组件，需要熟悉上述各组件的具体工作原理，下面分别介绍：

### Zookeeper 相关

ZooKeeper 是用来给集群服务维护配置信息，域名服务，提供分布式同步和提供组服务。所有这些类型的服务都使用某种形式的分布式应用程序。ZooKeeper 是一个分布式的，开放源码的协调服务，是的 Chubby 一个的实现，是Hadoop 和 Hbase 的重要组件。

#### Zookeeper 角色

领导者（leader）：领导者负责投票发起和决议，更新系统状态

跟随者（follwoer）：follower用于接收客户请求并向客户端返回结果，在选主过程中参与投票

观察者：ObServer可以接受客户端连接，将写请求转发给leader节点，但ObServer不参加投票过程，只同步leader的状态，ObServer的目的是为了拓展系统，提高读取速度。

客户端：请求发起方

#### Zookeeper 的工作原理

Zookeeper 的核心是原子广播，这个机制保证了各个Server之间的同步。实现这个机制的协议叫做Zab协议。Zab协议有两种模式，它们分别是恢复模式（选主）和广播模式（同步）。当服务启动或者在领导者崩溃后，Zab就进入了恢复模式，当领导者被选举出来，且大多数Server完成了和leader的状态同步以后，恢复模式就结束了。状态同步保证了leader和Server具有相同的系统状态。
为了保证事务的顺序一致性，zookeeper采用了递增的事务``id``号（zxid）来标识事务。所有的提议（proposal）都在被提出的时候加上了zxid。实现中zxid是一个64位的数字，它高32位是epoch用来标识leader关系是否改变，每次一个leader被选出来，它都会有一个新的epoch，标识当前属于那个leader的统治时期。低32位用于递增计数。
每个Server在工作过程中有三种状态：
1）LOOKING：当前Server不知道leader是谁，正在搜寻
2）LEADING：当前Server即为选举出来的leader
3）FOLLOWING：leader已经选举出来，当前Server与之同步



### Mesos 相关

Mesos 是Apache 下的开源分布式资源管理框架，它被称为是分布式系统的内核。Mesos 能够在同样的集群机器上运行多种分布式系统类型，更加动态有效率低共享资源。提供失败侦测，任务发布，任务跟踪，任务监控，低层次资源管理和细粒度的资源共享，可以扩展伸缩到数千个节点。Mesos 已经被 Twitter 用来管理它们的数据中心。

#### Mesos 基本组件说明

Mesos-master：主要负责管理各个 framework 和 slave，并将slave上的资源分配给各个 framework
Mesos-slave：负责管理本节点上的各个 mesos-task，比如：为各个 executor 分配资源
Framework：计算框架，如：Hadoop，Spark等，通过 MesosSchedulerDiver 接入 Mesos
Executor：执行器，安装到 mesos-slave 上，用于启动计算框架中的 task。

- Mesos-master 是整个系统的核心，负责管理接入mesos的各个framework（由frameworks_manager管理）和 slave（由slaves_manager管理），并将slave上的资源按照某种策略分配给framework（由独立插拔模块Allocator管 理）。
- Mesos-slave负责接收并执行来自mesos-master的命令、管理节点上的mesos-task，并为各个task分配资源。 mesos-slave将自己的资源量发送给mesos-master，由mesos-master中的Allocator模块决定将资源分配给哪个 framework，前考虑的资源有CPU和内存两种，也就是说，mesos-slave会将CPU个数和内存量发送给mesos-master，而用 户提交作业时，需要指定每个任务需要的CPU个数和内存量，这样，当任务运行时，mesos-slave会将任务放到包含固定资源的linux container中运行，以达到资源隔离的效果。很明显，master存在单点故障问题，为此，mesos采用了zookeeper解决该问题。
- Framework是指外部的计算框架，如Hadoop，Mesos等，这些计算框架可通过注册的方式接入mesos，以便mesos进行统一管理 和资源分配。Mesos要求可接入的框架必须有一个调度器模块，该调度器负责框架内部的任务调度。当一个framework想要接入mesos时，需要修 改自己的调度器，以便向mesos注册，并获取mesos分配给自己的资源， 这样再由自己的调度器将这些资源分配给框架中的任务，也就是说，整个mesos系统采用了双层调度框架：第一层，由mesos将资源分配给框架；第二层， 框架自己的调度器将资源分配给自己内部的任务。当前Mesos支持三种语言编写的调度器，分别是C++，java和python，为了向各种调度器提供统 一的接入方式，Mesos内部采用C++实现了一个MesosSchedulerDriver（调度器驱动器），framework的调度器可调用该 driver中的接口与Mesos-master交互，完成一系列功能（如注册，资源分配等）。
- Executor主要用于启动框架内部的task。由于不同的框架，启动task的接口或者方式不同，当一个新的框架要接入mesos时，需要编写 一个executor，告诉mesos如何启动该框架中的task。为了向各种框架提供统一的执行器编写方式，Mesos内部采用C++实现了一个 MesosExecutorDiver（执行器驱动器），framework可通过该驱动器的相关接口告诉mesos启动task的方法。

### Marathon 相关

Marathon是一个成熟的，轻量级的，扩展性很强的Apache Mesos的容器编排框架，它主要用来调度和运行常驻服务（long-running service），提供了友好的界面和Rest API来创建和管理应用。marathon是一个mesos框架，能够支持运行长服务，比如web应用等，它是集群的分布式Init.d，能够原样运行任何Linux二进制发布版本，如Tomcat Play等等，可以集群的多进程管理。也是一种私有的Pass，实现服务的发现，为部署提供提供REST API服务，有授权和SSL、配置约束，通过HAProxy实现服务发现和负载平衡

#### Marathon中重要的概念介绍

1）Application是Marathon中一个重要的核心概念，它代表了一个长服务。

2）Application definition表示一个长服务的定义，规定了一个Application启动和运行时的所有行为。Marathon提供了两种方式让你来定义你的长服务，第一种通过Portal来定义，它方便终端用户的理解和使用，另一种是通过JSON格式的文件来定义，并通过RestAPI的方式来创建和管理这个Application，这种方式方便和第三方的系统进行集成，提供了再次的可编程接口。

3）Application instance表示一个Application的实例，也称作Mesos的一个task。Marathon可以为一个Application创建和管理多个实例，并可以动态的增大和减小某个Application实例的个数，并且通过Marathon-lb实现服务发现和负载均衡。

4）Application Group：Marathon可以把多个Application组织成一棵树的结构，Group称为这个树的树枝，Application称为这个树的叶子。同一个Group中的Application可以被Marathon统一管理。

5）Deployments:对Application或者Group的definition的一次修改的提交称为一次deployment。它包括创建，销毁，扩容缩容Application或者Group等。多个deployments可以同时进行，但是对于一个应用的deployments必须是串行的，如果前一个deployment没有结束就执行下一个deployment，那么它将会被拒绝。