---
layout:      post
title:       "Kubernetes集群安装Metrics Server"
subtitle:    ""
description: "Kubernetes 1.8关于资源使用情况的 metrics，可以通过 Metrics API 获取到 Kubernetes 1.11 已经废弃 heapster。这里我们基于 Kubernetes 1.12 版本安装 Metrics Server"
excerpt:     ""
date:        2019-01-04T12:23:36+08:00
author:      Eric
image:       "https://wx3.sinaimg.cn/large/b258d7f7ly1fynwhhmlolj21ja0lo7aj.jpg"
published:   true
tags:        ["Kubernetes","Metrics","Docker"]
categories:  [ TECH ]
---

Kubernetes 1.8 关于资源使用情况的 metrics，可以通过 Metrics API 获取到 Kubernetes 1.11 已经废弃 heapster。这里我们基于 Kubernetes 1.12 版本安装 Metrics Server。

## Metrics Server 的安装

首先，先说明下集群环境：

```bash
👍 ~ kubectl get nodes
NAME        STATUS   ROLES    AGE   VERSION
k8s-m1      Ready    master   36d   v1.12.3
k8s-node1   Ready    <none>   36d   v1.12.3
k8s-node2   Ready    <none>   36d   v1.12.3
```

当整个集群部署完成后，`kubectl top` 命令不会返回任何内容，因为 `Heapster` 和 `metrics - server` 都没有安装，但是自 `Kubernetes 1.11`版本后 `heapster`已经被废弃了，取而代之的是更丰富的 `metrics-server`。这里基于 `Kubernetes 1.12` 版本安装 Metrics Server。

Metrics API 的  URI 是`/apis/metrics.k8s.io/`，扩展了 Kubernetes 的核心 API。

Metrics Server 详细信息可以参考：<https://github.com/kubernetes-incubator/metrics-server>

准备部署 Metrics Server 的 `yaml`文件（配置清单文件）:

```bash
👍 ~ git clone https://github.com/kubernetes-incubator/metrics-server
```

下载完成后还需要对 `metrics-server/deploy/1.8+/resource-reader.yaml`文件进行修改，需要修改的内容如下：

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  - namespaces      # 增加此行
  - nodes/stats
  verbs:
  - get
  - list
  - watch
---
...
```

修改 `metrics-server/deploy/1.8+/metrics-server-deployment.yaml`文件：

```yaml
---
(变更前)
containers:
- name: metrics-server
  image: k8s.gcr.io/metrics-server-amd64:v0.3.1
  imagePullPolicy: Always

---
(变更后)
containers:
- name: metrics-server
  image: k8s.gcr.io/metrics-server-amd64:v0.3.1
  command:
  - /metrics-server
  - --kubelet-insecure-tls
```

修改完成就可以正式部署了：

```bash
👍 ~ cd metrics-server/deploy/1.8+
👍 ~ kubectl apply -f .
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
serviceaccount/metrics-server created
deployment.extensions/metrics-server created
service/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
```

Metrics Server 相关 pod 、service 默认部署在 `kube-system`的 NAMESPACE 下：

```bash
👍 ~ kubectl get pods -n kube-system | grep metrics
metrics-server-6bbbb8f8f5-ngr9c               1/1     Running   0          115s
---
👍 ~ kubectl get svc -n kube-system | grep metrics
metrics-server            ClusterIP   10.104.82.243    <none>        443/TCP       2m46s
```

部署完成后使用如下命令查看node相关指标：

```bash
👍 ~ kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
{"kind":"NodeMetricsList","apiVersion":"metrics.k8s.io/v1beta1","metadata":{"selfLink":"/apis/metrics.k8s.io/v1beta1/nodes"},"items":[]}
```

没有获取到信息，此时查看 metric-server 容器的日志，有下面的错误：

```bash
👍 ~ kubectl logs -f -n kube-system metrics-server-6bbbb8f8f5-ngr9c
---
E1003 05:46:13.757009       1 manager.go:102] unable to fully collect metrics: [unable to fully scrape metrics from source kubelet_summary:node1: unable to fetch metrics from Kubelet node1 (node1): Get https://k8s-node1:10250/stats/summary/: dial tcp: lookup k8s-node1 on 10.96.0.10:53: no such host, unable to fully scrape metrics from source kubelet_summary:k8s-node2: unable to fetch metrics from Kubelet node2 (node2): Get https://k8s-node2:10250/stats/summary/: dial tcp: lookup node2 on 10.96.0.10:53: read udp 10.244.1.6:45288->10.96.0.10:53: i/o timeout]
```

可以看到 metrics-server 在从 kubelet 的 10250 端口获取信息时，使用的是 hostname，而因为 node1 和 node2 是一个独立的 Kubernetes 演示环境，只是修改了这两个节点系统的 `/etc/hosts` 文件，而并没有内网的 DNS 服务器，所以 metrics-server 中不认识 k8s-node1 和 k8s-node1 的名字。这里我们可以直接修改 Kubernetes 集群中的 coredns的 configmap，修改 Corefile 加入 hostnames 插件，将 Kubernetes 的各个节点的主机名加入到 hostnames 中，这样Kubernetes 集群中的所有 Pod 都可以从 CoreDNS 中解析各个节点的名字。

```bash
👍 ~ kubectl edit configmap coredns -n kube-system
---
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        hosts {                        # 增加此字段
          10.200.100.216  k8s-m1           
          10.200.100.215  k8s-node1
          10.200.100.214  k8s-node2
          fallthrough
        }
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  creationTimestamp: 2018-11-28T10:50:05Z
  name: coredns
  namespace: kube-system
  resourceVersion: "4454220"
  selfLink: /api/v1/namespaces/kube-system/configmaps/coredns
  uid: 5da15457-f2fb-11e8-affd-080027adebb7
```

> 其实除了上述方法外还有一种方法可以解决此问题，就是需要按照上面的方法修改`metrics-server-deployment.yaml`文件，添加`--kubelet-preferred-address-types=InternalIP`参数，修改后的内容如下：

```yaml
---
(变更前)
containers:
- name: metrics-server
  image: k8s.gcr.io/metrics-server-amd64:v0.3.1
  imagePullPolicy: Always

---
(变更后)
containers:
- name: metrics-server
  image: k8s.gcr.io/metrics-server-amd64:v0.3.1
  command:
  - /metrics-server
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP
```

配置修改完毕后重启集群中 coredns 和 metrics-server，确认 metrics-server 不再有错误日志。

```bash
👍 ~ kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
{"kind":"NodeMetricsList","apiVersion":"metrics.k8s.io/v1beta1","metadata":{"selfLink":"/apis/metrics.k8s.io/v1beta1/nodes"},"items":[{"metadata":{"name":"k8s-m1","selfLink":"/apis/metrics.k8s.io/v1beta1/nodes/k8s-m1","creationTimestamp":"2019-01-04T09:54:27Z"},"timestamp":"2019-01-04T09:53:46Z","window":"30s","usage":{"cpu":"93706104n","memory":"2580432Ki"}},{"metadata":{"name":"k8s-node1","selfLink":"/apis/metrics.k8s.io/v1beta1/nodes/k8s-node1","creationTimestamp":"2019-01-04T09:54:27Z"},"timestamp":"2019-01-04T09:53:42Z","window":"30s","usage":{"cpu":"310715486n","memory":"2369228Ki"}},{"metadata":{"name":"k8s-node2","selfLink":"/apis/metrics.k8s.io/v1beta1/nodes/k8s-node2","creationTimestamp":"2019-01-04T09:54:27Z"},"timestamp":"2019-01-04T09:53:46Z","window":"30s","usage":{"cpu":"304256739n","memory":"2433132Ki"}}]}
```

可以看到此时可以正常获取到数据，说明 Metrics Server 现在可以正常工作了。

## Metrics API

Metrics Server 从 Kubernetes 集群中每个 Node 上 kubelet 的 API 收集 metrics 数据。通过 Metrics API 可以获取Kubernetes 资源的 Metrics 指标，Metrics API 挂载`/apis/metrics.k8s.io/ `下。 可以使用`kubectl top`命令访问 Metrics API，例如:

```bash
👍 ~ kubectl top nodes
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-m1      91m          9%     2469Mi          66%
k8s-node1   308m         30%    2309Mi          62%
k8s-node2   326m         32%    2382Mi          64%
```

```bash
👍 ~ kubectl top pods -n kube-system
NAME                                          CPU(cores)   MEMORY(bytes)
coredns-576cbf47c7-bc9jb                      1m           17Mi
coredns-576cbf47c7-k2hpc                      2m           14Mi
etcd-k8s-m1                                   10m          308Mi
kube-apiserver-k8s-m1                         18m          597Mi
kube-controller-manager-k8s-m1                17m          68Mi
kube-flannel-ds-amd64-f56vj                   2m           15Mi
kube-flannel-ds-amd64-mwwgq                   2m           13Mi
kube-flannel-ds-amd64-qlkwh                   1m           11Mi
kube-proxy-926mk                              2m           18Mi
kube-proxy-c68mb                              2m           15Mi
kube-proxy-f8xg4                              1m           15Mi
kube-scheduler-k8s-m1                         7m           20Mi
kubernetes-dashboard-77fd78f978-cx5bn         1m           17Mi
kubernetes-dashboard-77fd78f978-jqzhq         1m           27Mi
metrics-server-6bbbb8f8f5-ngr9c               1m           14Mi
traefik-ingress-controller-5bc6d75c76-q4m5n   2m           29Mi
```

至此，Kubernetes 集群中的 Metrics Server 就配置完成了。