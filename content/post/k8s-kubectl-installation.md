---
layout:      post
title:       "Kubernetes集群安装kubectl工具"
subtitle:    ""
description: "在kubernetes集群中kubectl是个非常重要的命令行工具，它的作用相当于docker的相关命令，可以通过自己定义的yaml文件启动相关pod及service相关资源"
excerpt:     ""
date:        2018-11-30T14:25:24+08:00
author:      Aeric
image:       "https://wx3.sinaimg.cn/large/b258d7f7ly1fxx45xtuqpj21ja0lowu2.jpg"
published:   true
tags:        ["Kubernetes","Docker"]
categories:  [ "TECH" ]
---

其实 kubernetes 的 server 软件包基本涵盖了 kubernetes 几乎所有的工具，所以我们只需要下载 kubernetes 的 server 软件包即可。

kubernetes 源码下载地址： <https://github.com/kubernetes/kubernetes/releases/>

本文档是基于 v1.9.6 版本部署 kubernetes 集群，其他版本基本类似，相较老版本（v1.6）参数会有变化，我会在对应位置注明。

### 下载并准备 kubectl 工具

```bash
wget https://dl.k8s.io/v1.9.6/kubernetes-server-linux-amd64.tar.gz
tar -xzvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes
tar -xzvf  kubernetes-src.tar.gz
cd server/bin
将二进制文件拷贝到指定路径
cp kubectl /usr/local/bin
```

### 创建 kubectl kubeconfig 文件

```bash
export KUBE_APISERVER="https://192.168.8.66:6443"
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER}
# 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem
# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin
# 设置默认上下文
kubectl config use-context kubernetes
```
参数说明：

- `admin.pem` 证书 OU 字段值为 `system:masters`；
- `kube-apiserver` 预定义的 RoleBinding cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该 Role 授予了调用 kube-apiserver 相关 API 的权限；

生成的 `kubeconfig` 被保存到 `~/.kube/config` 文件中，如下所示：

```bash
[root@k8s-master1 ~]# ls /root/.kube/
cache  config  schema
```

现在基本可以使用 kubectl 工具了。

### 配置 kubectl 命令自动补全

成功部署了 kubernetes 集群后，我们通常是通过 kubectl 这个命令行工具进行操作，默认该工具不能自动补全命令，但是我们可以进行一系列配置来实现其自动补全的功能，kubectl 命令行工具本身就支持 complication ，只需要简单的设置下就可以了。

以下是linux系统的设置命令：

```bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```
然后就可以自动补全了。

如果是普通用户上述命令依旧可用，复制执行即可！

如果发现不能自动补全，可以尝试安装 `bash-completion` 软件包，然后刷新即可！

```bash
yum -y install bash-completion
```