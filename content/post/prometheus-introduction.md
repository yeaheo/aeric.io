---
layout:      post
title:       "Prometheus 监控入门介绍"
subtitle:    ""
description: "Prometheus 是一个开放性的监控解决方案，用户可以非常方便的安装和使用 Prometheus 并且能够非常方便的对其进行扩展，本文档先简单介绍一下 Prometheus"
excerpt:     ""
date:        2019-02-27T18:59:07+08:00
author:      Aeric
image:       "https://wx1.sinaimg.cn/large/b258d7f7ly1g0maj7m2y2j21ja0lokao.jpg"
published:   true
tags:        ["Prometheus"]
categories:  [ "TECH" ]
---

## Prometheus 系统简介

首先，Prometheus 受启发于 Google 的 Brogmon 监控系统，相似的 Kubernetes 是从 Google 的 Brog 系统演变而来，从 2012 年开始由前 Google 工程师在 Soundcloud 以开源软件的形式进行研发，并且于 2015 年早期对外发布早期版本。2016 年 5 月继 Kubernetes 之后成为第二个正式加入 CNCF 基金会的项目，同年 6 月正式发布 1.0 版本。2017 年底发布了基于全新存储层的 2.0 版本，能更好地与容器平台、云平台配合。

Prometheus 的发展简史如下图所示：

![Prometheus 简史](https://wx1.sinaimg.cn/large/b258d7f7ly1g0lwpo57jaj20o507hwfr.jpg)

作为新一代监控系统，Prometheus 可以说是彻底颠覆了传统的监控系统，作为监控系统，一般都离不开以下监控**目标**：

- **长期趋势分析：**通过对监控样本数据的持续收集和统计，对监控指标进行长期趋势分析。例如，通过对磁盘空间增长率的判断，我们可以提前预测在未来什么时间节点上需要对资源进行扩容。
- **对照分析：**两个版本的系统运行资源使用情况的差异如何？在不同容量情况下系统的并发和负载变化如何？通过监控能够方便的对系统进行跟踪和比较。
- **告警：**当系统出现或者即将出现故障时，监控系统需要迅速反应并通知管理员，从而能够对问题进行快速的处理或者提前预防问题的发生，避免出现对业务的影响。
- **故障分析与定位：**当问题发生后，需要对问题进行调查和处理。通过对不同监控监控以及历史数据的分析，能够找到并解决根源问题。
- **数据可视化：**通过可视化仪表盘能够直接获取系统的运行状态、资源使用情况、以及服务运行状态等直观的信息。

与传统监控系统相比， Prometheus 是一个开源的完整监控解决方案，其对传统监控系统的测试和告警模型进行了彻底的颠覆，形成了基于中央化的规则计算、统一分析和告警的新模型。Prometheus 具有许多独特的**优势**：

- **易于管理:** Prometheus 核心部分只有一个单独的二进制文件，不存在任何的第三方依赖(数据库，缓存等等)。唯一需要的就是本地磁盘，因此不会有潜在级联故障的风险。Prometheus 基于 Pull 模型的架构方式，可以在任何地方（本地电脑，开发环境，测试环境）搭建我们的监控系统。对于一些复杂的情况，还可以使用Prometheus 服务发现 (Service Discovery) 的能力动态管理监控目标。
- **监控服务的内部运行状态:** Pometheus 鼓励用户监控服务的内部状态，基于 Prometheus 丰富的 Client 库，用户可以轻松的在应用程序中添加对 Prometheus 的支持，从而让用户可以获取服务和应用内部真正的运行状态。
- **数据模型:** Prometheus 所有采集的监控数据均以指标 (metric) 的形式保存在内置的时间序列数据库当中(TSDB)。所有的样本除了基本的指标名称以外，还包含一组用于描述该样本特征的标签。每一条时间序列由指标名称(Metrics Name)以及一组标签(Labels)唯一标识。每条时间序列按照时间的先后顺序存储一系列的样本值。
- **查询语言PromQL:** Prometheus 内置了一个强大的数据查询语言 PromQL。 通过 PromQL 可以实现对监控数据的查询、聚合。同时 PromQL 也被应用于数据可视化(如Grafana)以及告警当中。
- **高效、可扩展、易于集成:** Prometheus 对于联邦集群的支持，可以让多个 Prometheus 实例产生一个逻辑集群，当单实例 Prometheus Server 处理的任务量过大时，通过使用功能分区(sharding)+联邦集群(federation)可以对其进行扩展。使用Prometheus可以快速搭建监控服务，并且可以非常方便地在应用程序中进行集成。
- Prometheus 还有许多特性，这里不再一一赘述，详细信息可以查阅[官方文档](https://prometheus.io/docs/introduction/overview/)

## Prometheus 核心组件

上一节中，简单介绍了 Prometheus 监控系统的由来和特性，这里我们将详细介绍一下 Prometheus 监控的核心组件和工作原理。

Prometheus 的基本架构图如下图所示：

![Prometheus 基本架构图](https://prometheus.io/assets/architecture.png)

### Prometheus Server

Prometheus Server 是 Prometheus 组件中的核心部分，负责实现对监控数据的获取，存储以及查询。 Prometheus Server 可以通过静态配置管理监控目标，也可以配合使用 Service Discovery 的方式动态管理监控目标，并从这些监控目标中获取数据。其次 Prometheus Server 需要对采集到的监控数据进行存储，Prometheus Server 本身就是一个时序数据库，将采集到的监控数据按照时间序列的方式存储在本地磁盘当中。最后 Prometheus Server 对外提供了自定义的 PromQL 语言，实现对数据的查询以及分析。

Prometheus Server 内置的 Express Browser UI，通过这个 UI 可以直接通过 PromQL 实现数据的查询以及可视化。

Prometheus Server 的联邦集群能力可以使其从其他的 Prometheus Server 实例中获取数据，因此在大规模监控的情况下，可以通过联邦集群以及功能分区的方式对 Prometheus Server 进行扩展。

### Exporters

Exporter 将监控数据采集的端点通过 HTTP 服务的形式暴露给 Prometheus Server，然后 Prometheus Server 通过访问该 Exporter 提供的 Endpoint 端点，即可获取到需要采集的监控数据。

一般来说可以将 Exporter 分为 2 类：

- **直接采集**：这一类 Exporter 直接内置了对 Prometheus 监控的支持，比如 cAdvisor，Kubernetes，Etcd，Gokit等，都直接内置了用于向 Prometheus 暴露监控数据的端点。
- **间接采集**：间接采集，原有监控目标并不直接支持 Prometheus，因此我们需要通过 Prometheus 提供的 Client Library 编写该监控目标的监控采集程序。例如: Mysql Exporter，JMX Exporter，Consul Exporter等。

### AlertManager

在 Prometheus Server 中支持基于 PromQL 创建告警规则，如果满足 PromQL 定义的规则，则会产生一条告警，而告警的后续处理流程则由 AlertManager 进行管理。在 AlertManager 中我们可以与邮件，Slack 等等内置的通知方式进行集成，也可以通过 Webhook 自定义告警处理方式。AlertManager 即 Prometheus 体系中的告警处理中心。

### PushGateway

由于 Prometheus 数据采集基于 Pull 模型进行设计，因此在网络环境的配置上必须要让 Prometheus Server 能够直接与 Exporter 进行通信。 当这种网络需求无法直接满足时，就可以利用 PushGateway 来进行中转。可以通过PushGateway 将内部网络的监控数据主动 Push 到 Gateway 当中。而 Prometheus Server 则可以采用同样 Pull 的方式从 PushGateway 中获取到监控数据。

接下来将在 Linux 系统上部署 Prometheus 监控系统，具体过程可以参考后期博文。