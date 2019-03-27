---
layout:      post
title:       "Kubernetes 1.14 更新日志"
subtitle:    ""
description: "2019年3月26日 Kubernetes1.14 版本正式发布，这是2019年发布的第一个版本，距离上个版本发布刚好又是三个月的时间。今天把该版本的主要特性说明一下"
excerpt:     ""
date:        2019-03-27T10:49:54+08:00
author:      Aeric
image:       "https://wx2.sinaimg.cn/large/b258d7f7ly1g1h6zsp170j21ja0lo77x.jpg"
published:   true
tags:        ["Kubernetes","Release"]
categories:  [ "TECH" ]
---

总的来说，本次发布的版本主要有以下几大显著特性：

- 对于管理 Windows node 的生产级支持；
- Kubectl 的说明文档经过完全重写，并启用新域名:<https://kubectl.docs.kubernetes.io>，还有了自己的 logo 和吉祥物 kubee-cuddle；
- Kubectl 与 Kustomize集成；
- Kubectl 插件机制发布稳定版本；
- 持久本地卷迎来通用版本；
- PID 限制正转向 beta 测试版本；

当然还有其他比较受关注的增强功能，具体功能可以参考[官方文档](https://kubernetes.io/blog/2019/03/25/kubernetes-1-14-release-announcement/)

### 对Windows节点的生产级支持

在此之前，Kubernetes 当中的 Windows 节点一直处于 beta 测试阶段，旨在允许众多用户以实验性方式体验Kubernetes for Windows 容器的实际价值。如今，Kubernetes 开始正式支持将 Windows 节点添加为工作节点并部署Windows 容器，从而确保庞大的 Windows 应用程序生态系统得以利用我们平台提供的强大功能。这意味着以往在Windows 应用程序与 Linux 应用程序层面投入大量资金的企业不必再寻求独立的协调器管理自身工作负载，而能够不再受到具体操作系统类型的影响提升整体部署的运营效率。

本次 Kubernetes 为 Windows 容器带来的核心功能特性包括：

- 支持将 Windows Server 2019 引入工作节点与容器；
- 支持采用 Azure-CNI、 OVN- Kubernetes 以及 Flannel 的树外网络；
- 改进了对 Pod、服务类型、工作负载控制器以及指标/配额的支持能力，以便与 Linux 容器的自有功能实现更为紧密的匹配；

### 新的Kubectl说明文档与徽标

Kubectl 工具的说明文档经过完全重写，其重点在于利用声明性 Resource Config 实现资源管理。这份文档目前以独立站点的形式发布，采用 Gitbook 风格，在新的文档站点中看到新的 kubectl 徽标与吉祥物 kubee-cuddle 的外观，具体可以访问 https://kubectl.docs.kubernetes.io 查看。

### Kubectl 与 Kustomize集成

Kustomize 的声明性 Resource Config 创作功能现在可以通过 `-k` 标记，适用于 apply 及 get 等命令，同时 Kustomize 子命令可以在 kubectl 中获取。

Kustomize 旨在帮助用户创作及复用包含 Kubernetes 各原生概念的 Resource Config。用户现在能够利用 `kubectl apply -k dir/` 将拥有 `kustomization.yaml` 的目录适用于集群。此外，用户也可以将定制化 Resource Config 发送至stdout，而无需通过 `kubectl kustomize dir/` 加以应用。这些新的功能被记录在新的说明文档当中，具体请参阅https://kubectl.docs.kubernetes.io

继续通过 Kubernetes 的 kustomize repo 对 Kustomize 子命令进行开发。最新的 Kustomize 功能将以独立的Kustomize 二进制文件（发布至 kustomize repo）的形式更为频率地发布，且在每一轮 Kubernetes 发布之前在kubectl 中得以更新。

### Kubectl 插件机制发布稳定版本

kubectl 插件机制允许开发人员将自己的定制化 kubectl 子命令以独立二进制文件的形式发布出来。这些成果将可帮助 kubectl 与附加 porcelain（例如添加 set-ns 命令）实现更多新的高级功能。

各插件必须采用 `kubectl-` 作为命名前缀，并保存在用户的 `$PATH` 当中。在通用版本中，插件机制已经迎来大幅简化，目前其整体效果类似于 Git 插件系统。

### 持久本地卷迎来通用版本

这项功能正逐渐稳定，允许用户将本地连接存储作为持久卷来源。

考虑到实际性能与成本要求，分布式文件系统与数据库往往成为持久性本地存储的主要用例。与云服务供应商相比较，本地 SSD 一般可提供超越远程磁盘的性能水平。而与裸机方案相比，除了性能之外，本地存储通常成本更低，亦是配置分布式文件系统的一项必要条件。

### PID 限制正转向 beta 测试版本

进程 ID（PID）属于 Linux 主机上的一种基本资源。毫无疑问，我们无法接受在未出现任何其它资源限制的情况下，因为进程 ID 不足而影响任务运行，甚至导致主机稳定性降低。管理员需要相关机制以确保用户 Pod 中的 PID 不会被耗尽，否则各类主机守护程序（包括运行时与 kubelet 等）都将受到影响。此外，管理员还需要确保在各Pod 之间限制 PID，从而保证其不致影响到运行在节点上的其它工作负载。

作为 beta 功能，管理员可以通过将每个 Pod 的 PID 数量设定默认值，以提供 pod-to-pod PID隔离。此外，作为alpha 功能，管理员可以通过节点可分配的方式，为用户 pod 保留大量可分配的 PID，从而启用节点到 pod 的 PID隔离。该社区希望在下一版本中将此功能转为测试版。

### 其他值得注意的功能

Pod 优先级和抢占使 Kubernetes 调度程序能够首先调度更重要的 Pod，当集群资源不足时，它会删除不太重要的pod，以便为更重要的 Pod 创建空间。重要性由优先级指定。具体可以参考[[1]](https://github.com/kubernetes/enhancements/issues/564)

Pod Readiness Gates 为 pod 准备就绪提供了外部反馈的扩展点。具体可以参考[[2]](https://github.com/kubernetes/enhancements/issues/580)

强化默认的 RBAC 的 `clusterrolebingdings` 发现能力，其移除了原本默认可通过未授权访问的 API 集发现功能，旨在提升 CRD 隐私性以及默认集群的总体安全水平。具体可以参考[[3]](https://github.com/kubernetes/enhancements/issues/789)



目前 Kubernetes 1.14 已可通过 GitHub 进行下载。要开始使用 Kubernetes，建议首先查看各交互式教程。同时也可以利用 kubeadm 轻松安装本次发布的 1.14 版本。

### 参考链接

- https://github.com/kubernetes/kubernetes/releases/tag/v1.14.0

- https://kubernetes.io/docs/tutorials/

- https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

- https://mp.weixin.qq.com/s/eQRpRfMVs9G2lfdk5rdAEg

- https://kubernetes.io/blog/2019/03/25/kubernetes-1-14-release-announcement/

  