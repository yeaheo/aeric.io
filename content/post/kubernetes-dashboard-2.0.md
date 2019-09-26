---
layout:      post
title:       "Kubernetes Dashboard 2.0 尝鲜"
subtitle:    ""
description: "Kubernetes Dashboard 是 Kubernetes 集群基于 web 的 UI，通过 Dashboard 可以管理集群大部分的配置，而且也可以发布相关服务，近期官方推出了全新的 Dashboard 2.0，增加了一些新功能"
excerpt:     ""
date:        2019-09-26T12:25:56+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/Balloons.jpg"
published:   true
tags:        ["Kubernetes"]
categories:  [ "TECH" ]
---

## 新版兼容性问题

因为 Kubernetes 本身更新速度比较快，Kubernetes API 在版本之间差异也是比较大的，这就导致了某些功能在新版的 Dashboard 中不能正常展示，具体兼容性如下表所示：

| Kubernetes 版本 | v 1.9 | v 1.10 | v 1.11 | v 1.12 | v 1.13 | v 1.14 | v 1.15 |
| :-------------: | :---: | :----: | :----: | :----: | :----: | :----: | :----: |
|   版本兼容性    |   x   |   ？   |   ？   |   ？   |   ？   |   ？   |   ✓    |

- ✕ 表示不支持的版本范围;
- ✓ 表示完全支持的版本范围;
- ? 表示由于Kubernetes API版本之间的重大更改，某些功能可能无法在仪表板中正常运行;

本次部署新版 Dashboard 2.0 用的是 v1.15.3 的集群版本，具体集群规格如下：

```bash
$ kubectl get nodes
NAME                    STATUS   ROLES    AGE   VERSION
master-10.200.100.216   Ready    master   14d   v1.15.3
node-10.200.100.214     Ready    <none>   14d   v1.15.3
node-10.200.100.215     Ready    <none>   14d   v1.15.3
```

## 部署 Dashboard 2.0

Kubernetes Dashboard 的 GitHub 地址：<https://github.com/kubernetes/dashboard> ,如果后续安装过程中出现问题可以参考相关资料说明，这里不再一一赘述。

新版 Dashboard 2.0 的部署清单文件：[recommended.yaml](https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml) 可以直接进行下载再做相应修改。

> 需要说明的是旧版本的 dashboard 的命名空间默认为 `kube-system`而新版本的 dashboard 具有独立的命名空间 `kubernetes-dashboard` 我们可以提前创建

### 为 dashboard 签发证书及密钥

在新版本中，dashboard 默认会启用 https 的认证，具体认证方式有：`TLS`、`token` 和 `username/passwd`

当我们部署完成后，我们用 https 访问 dashboard 时可能会报证书的相关问题，所以还是建议大家先为 dashboard 创建自签证书再部署 dashboard，这里我用 `openssl`工具生成自签证书，具体过程如下：

```bash
$ mkdir /certs
$ openssl req -nodes -newkey rsa:2048 -keyout certs/dashboard.key -out certs/dashboard.csr -subj "/C=/ST=/L=/O=/OU=/CN=kubernetes-dashboard"
## 利用 key 和私钥生成证书
$ openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
```

也可以用集群自有 CA 签发证书：

```bash
$ openssl x509 -req -in certs/dashboard.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out certs/dashboard.crt -days 365
```

证书签发完成后，查看 `/certs` :

```bash
$ ls /certs/
dashboard.crt  dashboard.csr  dashboard.key
```

在 K8S 集群中创建 `kubernetes-dashboard` 命名空间并创建相应的 `secret`

```bash
$ kubectl create ns kubernetes-dashboard
$ kubectl create secret generic kubernetes-dashboard-certs --from-file=/certs -n kubernetes-dashboard
```

### 准备 dashboard 配置清单部署文件

上述 [recommended.yaml](https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml)文件是一个整体，里面定义了新版 dashboard 2.0 的所有配置，但是我还是建议将其拆分开来，一是为了美观大方，条理清楚；二是为了便于维护。我将其整理了一下放在了 [GitHub](https://github.com/yeaheo/kubernetes-dashboard/tree/master/deploy) 上，有兴趣的同学可以做参考。

这里我基本没有做什么修改，只是做了拆分，要说修改就是将 dashboard 的 service 的类型改为了 `NodePort`类型，方便进行测试：

```bash
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
```

配置文件修改完成后直接部署即可：

```bash
$ git clone https://github.com/yeaheo/kubernetes-dashboard.git
$ cd kubernetes-dashboard/deploy
$ kubectl apply -f .
deployment.apps/kubernetes-dashboard configured
ingress.extensions/kubernetes-dashboard-ingress configured
deployment.apps/kubernetes-metrics-scraper configured
service/dashboard-metrics-scraper configured
serviceaccount/kubernetes-dashboard configured
role.rbac.authorization.k8s.io/kubernetes-dashboard configured
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard configured
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard configured
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard configured
secret/kubernetes-dashboard-certs configured
secret/kubernetes-dashboard-csrf configured
secret/kubernetes-dashboard-key-holder configured
configmap/kubernetes-dashboard-settings configured
service/kubernetes-dashboard configured
```

>  在 kubernetes 1.11 版本之后，Heapster 被 Metrics Server 替换后，dashboard 无法从 Heapster 获取集群 Metrics，转而使用 Metrics Server 获取集群 Metrics，而 Dashboard 2.0 为此多了一个 `dashboard-metrics-scraper` 容器专门用来获取这些指标

## 创建访问 Dashboard 的用户

Kubernetes Dashboard 2.0 配置完成后默认采用 HTTPS 方式访问，并配合 kubeconfig 文件或者 token 进行登录的，所以，接下来需要搞一个具有权限的用户登录 dashboard。

具有集群权限的用户清单文件(dashboard-admin-user.yaml)：

```bash
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin-sa
  namespace: kubernetes-dashboard
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin-sa
  namespace: kubernetes-dashboard
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin-sa
  namespace: kubernetes-dashboard
```

执行该文件：

```bash
$ kubectl apply -f dashboard-admin-user.yaml
```

获取该用户 token：

```bash
kubectl -n kubernetes-dashboard get secret -o jsonpath='{range .items[?(@.metadata.annotations.kubernetes\.io/service-account\.name=="dashboard-admin-sa")].data}{.token}{end}' | base64 -d
```

用上述输出的字符就可以登录 dashboard 了，这里配置的是管理员权限。

新版 dashboard 的 UI 如下图所示，看起来清爽了许多：

常规模式：

 ![web-1](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/dfd947fb.png)

暗黑模式：

![web-2](https://aericio.oss-cn-beijing.aliyuncs.com/images/blog/997c5528.png)

新版 Dashboard 2.0 的功能和以前版本功能几乎没什么区别，但是 UI 变的更加清爽了，而且速度也快了。欢迎各位喜欢搞事的同学尝鲜，嘿嘿。

> 在部署完成后，用 NodePort 方式在 Chrome 浏览器访问时总是提示证书错误，其他浏览器没问题，这个可能和新版 Dashboard 机制有关，然后改用 Ingress 代理后端 https 服务就没问题了，所以还是建议用 Ingress 暴露该服务

