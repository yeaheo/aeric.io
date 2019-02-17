---
layout:      post
title:       "二进制方式部署Kubernetes集群"
subtitle:    ""
description: "Kubernetes集群的安装方式有很多种，这里我们为了更深入的了解Kubernetes集群中各组件的工作方式，本次部署集群采用纯手动二进制方式部署，也是对很早之前文档的一个总结"
excerpt:     ""
date:        2018-12-01T15:35:14+08:00
author:      Aeric
image:       "https://wx3.sinaimg.cn/large/b258d7f7ly1fxx45xa3xzj21ja0loajs.jpg"
published:   true
tags:        ["Kubernetes"]
categories:  [ "TECH" ]
---

在之前的博客中也写到过如何纯手工搭建自己的 Kubernetes 集群，本文档主要是对之前文档的一个总结，具体过程可以参考如下安装流程：

- [Kubernetes-创建 TLS 证书及密钥](../k8s-create-tls-and-keys/)
- [Kubernetes-安装 kubectl 命令行工具](../k8s-kubectl-installation)
- [Kubernetes-创建 kubeconfig 文件](../k8s-create-kubeconfig)
- [Kubernetes-创建高可用 etcd 集群](../k8s-etcd-cluster-installation)
- [Kubernetes-部署 master 节点相关服务](../k8s-master-installation)
- [Kubernetes-安装配置 flanneld 及 docker 服务](../k8s-flannel-and-docker-config)
- [Kubernetes-部署 nodes 节点相关服务](../k8s-nodes-installation)
- [Kubernetes-部署 kube-dns 插件](../k8s-dns-addons-installation)

> 本文档安装流程是之前博客相关文档总结，版本较现在版本比较老，建议安装版本`v1.10`及之前版本，`v1.10`之后版本建议采用官方推荐工具`kubeadm`初始化 Kubernetes 集群，相关文档后续会补充，敬请期待