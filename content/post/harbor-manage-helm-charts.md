---
layout:      post
title:       "用 Harbor 管理 Helm Charts"
subtitle:    ""
description: "在 v1.6 版本的 harbor 中新增加了 helm charts 的管理功能,这样就可以利用 harbor 同时管理镜像和 helm charts 了，在部署 kubernetes 相关应用时就比较方便"
excerpt:     ""
date:        2019-01-18T10:42:37+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/wZBvPh.jpg"
published:   true
tags:        ["Harbor","Helm","Kubernetes"]
categories:  [ "TECH" ]
---

在 v1.6 版本的 harbor 中新增加了 helm charts 的管理功能,这样就可以利用 harbor 同时管理镜像和 helm charts 了，在部署 kubernetes 相关应用时就比较方便，本次尝试用 harbor 来管理 helm charts。

之前我是将公司内的 harbor 仓库做了一次升级，将 harbor 升级到了 `v1.7.1`版本，具体升级过程可以参考之前博文内容：[记一次harbor的升级之旅](https://aeric.io/post/harbor-upgrade-guide)。当然你也可以重新安装新版本的 harbor。因为本人公司 harbor 仓库用的是 https 协议来访问的，所以我们还需要相关证书，证书需要是受信的才行，这个需要根据具体情况来做取舍，这里不再赘述，具体怎么使用 harbor 来管理 helm charts 可以参考下面的内容。

## 启用 harbor 的 chart repository 服务

默认新版 harbor 不会启用 `chart repository service`，如果需要管理 `helm`，我们需要在安装时添加额外的参数，例如：

```bash
## 默认安装
$ cd /srv/harbor
$ ./install.sh

## 启动 chart repository service 服务
$ cd /srv/harbor
$ ./install.sh --with-chartmuseum
```

等待安装完成即可，安装完成后会有如下类似提示：

```
...
✔ ----Harbor has been installed and started successfully.----
...
```

之后，我们就可以用上述 harbor 来管理 helm charts 了。

## 图形界面操作

**创建相关项目：**

首先，我们需要在 harbor 上创建一个名为 `helm-repo`的项目，如下图所示：

![创建 helm-repo 项目](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/JTh3t9.jpg)

**上传 Helm Charts 包：**

单击 “上传” 按钮以打开图表上载对话框。 从文件系统中选择上传 Helm Charts。 单击 UPLOAD 按钮将其上载到 `helm-repo`存储库。

![上传 Helm Charts](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/yBdZ44.jpg)

> If the chart is signed, you can choose the corresponding provenance file from your filesystem and Click the `UPLOAD`button to upload them together at once.

Helm Charts 上传成功后，就可以显示在相关界面上，具体内容包括: chart 版本号、状态、作者、Egine、创建时间等信息，如下图所示：

![charts_version](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/ypkb5D.jpg)

当然，harbor 也支持根据每个 cahrt  的用途，为上传的 chart 包打上对应的标签，点击相关按钮即可，在打标签之前需要在 harbor 的系统设置里添加好对应标签即可，当为相应的 chart 添加好对应标签后 harbor 支持根据标签过滤 chart ,这个挺简单的，这里不再赘述。

charts 成功上传后，我们可以查看其具体信息，主要包括 `Summary`、`Dependencies`、`Values`等相关信息。也可以通过图形界面来管理上传的 charts ,包括 删除、更新等等具体操作。

## 用 Helm CLI 管理 Helm Charts

上述用 harbor 的图形界面操作 helm charts 固然简单快捷，这个在我们查看 helm 时确实简单高效，但是当我们想利用 CI 实现 helm charts 自动部署应用到 Kubernetes 集群的时候，该方法就显得比较鸡肋了，可以说图形界面根本无法实现，所以我们需要用 `Helm CLI`工具来实现。

首先，需要安装 helm 客户端工具，具体安装 helm cli 可以参考：[Install Helm](https://docs.helm.sh/using_helm/#installing-helm)，安装完成后可以通过如下命令验证安装是否完成：

```bash
helm version

#Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
#Server: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
```

### 添加 harbor helm 仓库

在使用之前，应该使用 `helm repo add` 命令将 `Harbor` 添加到存储库列表中。它支持两种不同的模式：

```
1.Add Harbor as a unified single index entry point
2.Add Harbor project as separate index entry point
```

这两种模式的具体区别如下所述：

**Add Harbor as a unified single index entry point**

- 该模式可以使 Helm 访问到不同项目中的所有图表，以及当前经过身份验证的用户可以访问的图表。

- ```bash
  helm repo add --ca-file ca.crt --cert-file server.crt --key-file server.key --username=admin --password=Passw0rd myrepo https://xx.xx.xx.xx/chartrepo
  ```

**Add Harbor project as separate index entry point**

- 该模式 helm 只能在指定项目中提取图表。

- ```bash
  helm repo add --ca-file ca.crt --cert-file server.crt --key-file server.key --username=admin --password=Passw0rd myrepo https://xx.xx.xx.xx/chartrepo/myproject
  ```

> 需要注意的是，如果用 `https`协议，这两种模式均需提供受信的证书和密钥，ca 证书可以不需要，省略

本次，我用的是第二种模式，添加完成后，如下所示：

```bash
[root@k8s-m1 ~]# helm repo list
NAME     	URL
stable   	https://kubernetes-charts.storage.googleapis.com
local    	http://127.0.0.1:8879/charts
myrepo	    https://harbor.xxx.cn/chartrepo/helm-repo
```

### 上传 Helm Charts

因为我们需要用 `helm push`命令上传，该命令是通过 `helm plugin`实现的，但是默认 helm 没有安装此插件，需要安装：

```bash
helm plugin install https://github.com/chartmuseum/helm-push
```

当我们打包好 `Helm Charts`后就可以通过命令上传至我们创建的仓库:

```bash
helm push --ca-file=ca.crt --key-file=server.key --cert-file=server.crt --username=admin --password=passw0rd chart_repo/hello-helm-0.1.0.tgz myrepo
```

> `push` command does not support pushing a prov file of a signed chart yet.

### 安装 Helm Charts

在安装之前，请确保使用命令 helm init 正确初始化helm，并且图表索引与命令 `helm repo update`同步。

```bash
helm repo update
```

搜索需要安装的 helm chart

```bash
helm search hello
```

安装 helm charts

```bash
helm install --ca-file=ca.crt --key-file=server.key --cert-file=server.crt --username=admin --password=Passw0rd --version 0.1.10 repo248/chart_repo/hello-helm
```

至此， 用 harbor 管理 helm charts 就完成了。helm 连接的 kubernetes 集群默认是和 kubectl 连接的 kubernetes 集群一致的，之后我们可以到 kubernetes 集群中查看我们新部署的 helm 相关应用

```bash
helm list
```

