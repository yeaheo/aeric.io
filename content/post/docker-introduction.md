---
layout:      post
title:       "容器 Docker 入门介绍"
subtitle:    ""
description: "Docker 最初是由 dotCloud 公司创始人 Solomon Hykes 发起的一个公司的内部项目，并于 2013 年实现开源，Docker 使用谷歌公司自己开发的 GO 语言实现。"
excerpt:     ""
date:        2018-07-26T21:34:07+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/ceCjdx.jpg"
published:   true
tags:        ["Docker"]
categories:  [ "TECH" ]
---

Docker 最初是由 dotCloud 公司创始人 Solomon Hykes 发起的一个公司的内部项目，并于 2013 年实现开源，主要项目代码在 [GitHub](https://github.com/moby/moby) 上维护。

Docker 使用谷歌公司自己开发的 [GO 语言](https://golang.org/) 实现的，基于 Linux 内核的 cgroup、 namespace 和 AUFS 类的 Union FS 等技术，对进程进行隔离封装，属于操作系统层面的虚拟化技术。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。

Docker 容器格式最初实现是基于 [LXC](https://linuxcontainers.org/lxc/introduction/) ，从 0.7 版本以后开始去除 LXC，转而使用自行开发的 [libcontainer](https://github.com/docker/libcontainer)，从 1.11 开始，则进一步演进为使用 [runC](https://github.com/opencontainers/runc) 和 [containerd](https://github.com/containerd/containerd)。

Docker 在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大的简化了容器的创建和维护。使得 Docker 技术比虚拟机技术更为轻便、快捷。

Docker 作为操作系统层面的虚拟化技术，它和传统的虚拟化技术相比有以下几个特点：

- **更轻便、快捷的应用**。 传统虚拟机技术是虚拟出一套硬件后，在其上运行一个完整操作系统，然后在该系统上再运行所需应用进程，而容器内的应用进程直接运行于宿主的内核，容器内没有自己的内核，而且也没有进行硬件虚拟。
- **更高效的利用系统资源**。 由于容器不需要进行硬件虚拟以及运行完整操作系统等额外开销，Docker 对系统资源的利用率更高。
- **更快速的应用启动时间**。 传统的虚拟机技术启动应用服务往往需要数分钟，而 Docker 容器应用，由于直接运行于宿主内核，无需启动完整的操作系统，因此可以做到秒级、甚至毫秒级的启动时间。
- **近乎一致的应用运行环境**。 Docker 的镜像提供了除内核外完整的运行时环境，确保了应用运行环境一致性。
- **持续交付和部署**。 使用 Docker 可以通过定制应用镜像来实现持续集成、持续交付、部署。开发人员可以通过 Dockerfile 来进行镜像构建，并结合 持续集成(Continuous Integration) 系统进行集成测试，而运维人员则可以直接在生产环境中快速部署该镜像，甚至结合 持续部署(Continuous Delivery/Deployment) 系统进行自动部署。
- **可以更快的迁移**。 由于 Docker 确保了执行环境的一致性，使得应用的迁移更加容易。可以说 Docker 可以在任何平台上运行，因为镜像的一致性也保证了运行环境的一致性，所以迁移起来更加的快速高效。
- **更轻松的维护和扩展**。 Docker 使用的分层存储以及镜像的技术，使得应用重复部分的复用更为容易，也使得应用的维护更新更加简单，基于基础镜像进一步扩展镜像也更加的容易。

- 下面的图片比较了 Docker 和传统虚拟化方式的不同：
  ![传统虚拟化技术](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/rAV6qh.jpg)
  ![docker虚拟化技术](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/2rwPVX.jpg)

