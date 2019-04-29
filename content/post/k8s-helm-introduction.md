---
layout:      post
title:       "K8S 包管理工具 Helm - 介绍"
subtitle:    ""
description: "Helm 是 Kubernetes 生态系统中的一个软件包管理工具，Helm是由 Deis 发起的一个开源工具，有助于简化部署和管理 Kubernetes 应用。 它有点类似于 Ubuntu 中的 APT 或 CentOS 中的 YUM"
excerpt:     ""
date:        2019-01-15T17:41:40+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/xJunGR.jpg"
published:   true
tags:        ["Helm","Kubernetes"]
categories:  [ "TECH" ]
---

[Helm](https://helm.sh) 是 Kubernetes 生态系统中的一个软件包管理工具，Helm 是由 [Deis](https://deis.com/) 发起的一个开源工具，有助于简化部署和管理 Kubernetes 应用。 它有点类似于 Ubuntu 中的 APT 或 CentOS 中的 YUM

Helm 官方网站：<https://helm.sh>

Helm GitHub 地址: <https://github.com/helm/helm>

## Helm 基本概念

Helm 可以理解为 Kubernetes 的包管理工具，可以方便地发现、共享和使用为 Kubernetes 构建的应用，它包含几个基本概念 

- **Helm :**  一个命令行下的客户端工具。主要用于 Kubernetes 应用程序 Chart 的创建、打包、发布以及创建和管理本地和远程的 Chart 仓库。 
- **Tiller :**  Helm 的服务端，部署在 Kubernetes 集群中。Tiller 用于接收 Helm 的请求，并根据 Chart 生成 Kubernetes 的部署文件（ Helm 称为 Release ），然后提交给 Kubernetes 创建应用。Tiller 还提供了 Release 的升级、删除、回滚等一系列功能。 

- **Chart :**  一个 Helm 包，其中包含了运行一个应用所需要的镜像、依赖和资源定义等，还可能包含 Kubernetes 集群中的服务定义，类似 Homebrew 中的 formula，APT 的 dpkg 或者 Yum 的 rpm 文件。

- **Release :**   在 Kubernetes 集群上运行的 Chart 的一个实例。在同一个集群上，一个 Chart 可以安装很多次。每次安装都会创建一个新的 release。例如一个 MySQL Chart，如果想在服务器上运行两个数据库，就可以把这个 Chart 安装两次。每次安装都会生成自己的 Release，会有自己的 Release 名称。

- **Repository ：** 用于发布和存储 Chart 的仓库。


## Helm 基本组件

Helm 采用客户端/服务器架构，有如下基本组件组成：

-  **Helm CLI** 是 Helm 客户端，可以在本地执行。
-  **Tiller** 是服务器端组件，在 Kubernetes 群集上运行，并管理 Kubernetes 应用程序的生命周期。
-  **Repository** 是 Chart 仓库，Helm客户端通过HTTP协议来访问仓库中Chart的索引文件和压缩包。

Helm 各个基本组件之间的关系如下图所示：

![Helm 各个基本组件之间的关系](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/6KF0TE.jpg)



## Helm 的工作原理

上面列出了 Helm 的基本组件及其用途，而 Helm 的工作过程和这些组件的功能用途是分不开的， Helm 依赖这些组件来完成整个工作流程，下面列出几个重要的工作过程，包括应用的安装、更新、回滚等流程。具体内容如下所述：

**应用安装（chart install）**

- Helm 从指定的目录或者 TAR 文件中解析出 Chart 结构信息。

- Helm 将指定的 Chart 结构和 Values 信息通过 gRPC 传递给 Tiller。

- Tiller 根据 Chart 和 Values 生成一个 Release。

- Tiller 将 Release 发送给 Kubernetes 用于生成 Release。


**应用更新（chart update）**

- Helm 从指定的目录或者 TAR 文件中解析出 Chart 结构信息。
- Helm 将需要更新的 Release 的名称、Chart 结构和 Values 信息传递给 Tiller。
- Tiller 生成 Release 并更新指定名称的 Release 的 History。
- Tiller 将 Release 发送给 Kubernetes 用于更新 Release。

**应用回滚（chart rollback）**

- Helm 将要回滚的 Release 的名称传递给 Tiller。
- Tiller 根据 Release 的名称查找 History。
- Tiller 从 History 中获取上一个 Release。
- Tiller 将上一个 Release 发送给 Kubernetes 用于替换当前 Release。

**Chart 处理依赖说明**：

Tiller 在处理 Chart 时，直接将 Chart 以及其依赖的所有 Charts 合并为一个 Release，同时传递给 Kubernetes。因此 Tiller 并不负责管理依赖之间的启动顺序。Chart 中的应用需要能够自行处理依赖关系。 