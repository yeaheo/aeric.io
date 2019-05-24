---
layout:      post
title:       "探究 Kubernetes 的亲和性调度"
subtitle:    ""
description: "之前一直没有时间总结和梳理 kubernetes 的亲和性调度相关内容，这次利用空闲时间将 kubernetes 的亲和性调度梳理一下，并借助官方文档的例子进行实际演示，"
excerpt:     ""
date:        2019-05-23T21:23:59+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/nigss233.jpg"
published:   true
tags:        ["Kubernetes"]
categories:  [ "TECH" ]
---

我们在使用 Kubernetes 集群调度应用 POD 的时候，一般情况下我们都是用集群的自动调度机制选择某个节点，默认情况 Kubernetes 集群一般分为预选和优选两种调度策略，计算得分来进行调度，得分高的节点优先被调度。

默认情况下调度器考虑的是资源充足并且负载尽量平均，但是有时候我们需要将特定 POD 运行在我们指定的节点上，或者说我们不希望对外的一些服务和内部的服务跑在同一个节点上，因为内部服务对外部的服务可能产生某些不可预知的影响。有的时候我们某两个服务直接交流比较频繁，又希望能够将这两个服务的 POD 调度到同样的节点上，这个时候 Kubernetes 集群的亲和性相关概念就可以实现上述目的。

在 Kubernetes 集群中亲和性（Affinity）一般分为节点亲和性（nodeAffinity）和 pod 亲和性（podAffinity）两类。

这里我们针对亲和性相关概念主要说明一下 `nodeSelector`、`nodeAffinity`、`podAffinity`、`Taints` 以及`Tolerations` 的相关内容。

# 将 Pod 分配给节点

您可以将 [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod/) 限制为只能在特定 [节点](https://kubernetes.io/docs/concepts/architecture/nodes/) 上运行或者更喜欢在特定节点上运行，这里主要有以下几种方式：

- nodeSelector
- Affinity and anti-affinity
- nodeName

## nodeSelector

`nodeSelector` 其实是最简单的一种节点约束形式，它依赖 Kubernetes 集群中的 label 属性，我们知道`label`是`kubernetes`中一个非常重要的概念，用户可以非常灵活的利用 label 来管理集群中的资源，比如最常见的一个就是 service 通过匹配 label 去选择 POD 的。而 POD 的调度也可以根据节点的 label 进行特定的部署。

集群现状：

```bash
➜ ~ kubectl get nodes
NAME                                STATUS   ROLES    AGE   VERSION
cn-beijing.i-2zeigrq970614g1spzpu   Ready    <none>   30d   v1.12.6-aliyun.1
cn-beijing.i-2zeigrq970614g1spzpv   Ready    <none>   30d   v1.12.6-aliyun.1
```

如果需要查看 node 节点的 label 可以使用如下命令：

```bash
➜ ~ kubectl get nodes --show-labels
或者
➜ ~ kubectl describe nodes <node-name>
```

首先需要为节点打上标签，参考如下命令：

```bash
➜ ~ kubectl label nodes <node-name> <label-key>=<label-value>
```

这里我为 `cn-beijing.i-2zeigrq970614g1spzpv` 这个节点加一个 `source=yeaheo`的标签：

```bash
➜ ~ kubectl label nodes cn-beijing.i-2zeigrq970614g1spzpv source=yeaheo
node/cn-beijing.i-2zeigrq970614g1spzpv labeled
```

当 node 被打上了相关标签后，在调度的时候就可以使用这些标签了，只需要在 POD 的 spec 字段中添加`nodeSelector`字段，里面是我们需要被调度的节点的 label，本次我们用官方文档的 pod 模板：

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx:alpine 
```

在 `spec`字段添加 `nodeSelector`后完整的 yaml 文件如下所示：

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    imagePullPolicy: IfNotPresent
  nodeSelector:
    source: yeaheo
```

部署该文件：

```bash
➜ ~ kubectl apply -f pod-nginx.yaml
```

部署完成后，可以通过查看该 pod 确实调度到了指定节点上：

```bash
➜ affinity kubectl get pods -n default -o wide
NAME    READY   STATUS    RESTARTS   AGE     IP             NODE                                NOMINATED NODE
nginx   1/1     Running   0          2m46s   172.16.0.205   cn-beijing.i-2zeigrq970614g1spzpv   <none>
```

## Affinity and anti-affinity

`nodeSelector`提供了一种非常简单的方法来将pod限制为具有特定标签的节点。而 `Affinity`相比 `nodeSelector`更加的强大，官方文档这样比较两者的：

```bash
1、the language is more expressive (not just “AND of exact match”)
2、you can indicate that the rule is “soft”/“preference” rather than a hard requirement, so if the scheduler can’t satisfy it, the pod will still be scheduled
3、you can constrain against labels on other pods running on the node (or other topological domain), rather than against labels on the node itself, which allows rules about which pods can and cannot be co-located
```

亲和特征由两种类型的亲和力组成，“节点亲和力”和“节点间亲和力/反亲和力”。节点亲和力就像现有的`nodeSelector`（但具有上面列出的前两个好处），而pod间亲和/反亲和力限制 pod 标签而不是节点标签，如上面列出的第三个项目中所述，除了拥有第一个和上面列出的第二个属性。

### nodeAffinity

`nodeAffinity`就是节点亲和性，相对应的是`Anti-Affinity`，就是反亲和性，这种方法比上面的`nodeSelector`更加灵活，它可以进行一些简单的逻辑组合了，不只是简单的相等匹配。 调度可以分成软策略和硬策略两种方式，软策略就是如果你没有满足调度要求的节点的话，POD 就会忽略这条规则，继续完成调度过程，说白了就是**满足条件最好了，没有的话也无所谓了**的策略；而硬策略就比较强硬了，如果没有满足条件的节点的话，就不断重试直到满足条件为止，简单说就是**你必须满足我的要求，不然我就不干**的策略。

 `nodeAffinity`就有两上面两种策略：`preferredDuringSchedulingIgnoredDuringExecution`和`requiredDuringSchedulingIgnoredDuringExecution`，前面的就是软策略，后面的就是硬策略。

如下 `pod-with-node-affinity.yaml` 配置清单文件定义的亲和性：

```bash
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/e2e-az-name
            operator: In
            values:
            - e2e-az1
            - e2e-az2
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
  containers:
  - name: with-node-affinity
    image: k8s.gcr.io/pause:2.0
```

此节点关联性规则表示，该pod只能放置在一个标签上，该标签的键是`kubernetes.io/e2e-az-name`，其值为`e2e-az1`或者`e2e-az2`。此外，在满足该标准的节点中，具有其键`another-node-label-key`和值的标签的节点`another-node-label-value`应该是首选的。

现在`Kubernetes`提供的操作符有下面的几种：

- In：label 的值在某个列表中
- NotIn：label 的值不在某个列表中
- Gt：label 的值大于某个值
- Lt：label 的值小于某个值
- Exists：某个 label 存在
- DoesNotExist：某个 label 不存在

> 如果同时指定了`nodeSelector` 和 `nodeAffinity`,那么必须同时满足才可以被调度；如果`nodeSelectorTerms`下面有多个选项的话，满足任何一个条件就可以了；如果`matchExpressions`有多个选项的话，则必须同时满足这些条件才能正常调度 POD。如果删除或更改计划容器的节点的标签，则不会删除该容器。换句话说，亲和度选择仅在调度pod时起作用。

### podAffinity

上面两种方式都是让 POD 去选择节点的，有的时候我们也希望能够根据 POD 之间的关系进行调度，`Kubernetes`在1.4版本引入的`podAffinity`概念就可以实现我们这个需求。

和`nodeAffinity`类似，`podAffinity`也有`requiredDuringSchedulingIgnoredDuringExecution`和 `preferredDuringSchedulingIgnoredDuringExecution`两种调度策略，唯一不同的是如果要使用互斥性，我们需要使用`podAntiAffinity`字段。 如下例子所示，我们希望`with-pod-affinity`和`busybox-pod`能够就近部署，而不希望和`node-affinity-pod`部署在同一个拓扑域下面：

```bash
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
  labels:
    app: pod-affinity-pod
spec:
  containers:
  - name: with-pod-affinity
    image: nginx
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - busybox-pod
        topologyKey: kubernetes.io/hostname
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - node-affinity-pod
          topologyKey: kubernetes.io/hostname
```

上面这个例子中的 POD 需要调度到某个指定的主机上，至少有一个节点上运行了这样的 POD：这个 POD 有一个`app=busybox-pod`的 label。`podAntiAffinity`则是希望最好不要调度到这样的节点：这个节点上运行了某个 POD，而这个 POD 有`app=node-affinity-pod`的 label。

需要注意的是：

>在`labelSelector`和 `topologyKey`的同级，还可以定义 namespaces 列表，表示匹配哪些 namespace 里面的 pod，默认情况下，会匹配定义的 pod 所在的 namespace；如果定义了这个字段，但是它的值为空，则匹配所有的 namespaces。

## nodeName

`nodeName`是最简单的节点选择约束形式，但由于其局限性，通常不使用它。这里简单举个例子：

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  nodeName: kube-01
```

# 污点和容忍度

对于`nodeAffinity`无论是硬策略还是软策略方式，都是调度 POD 到预期节点上，而`Taints`恰好与之相反，如果一个节点标记为 Taints ，除非 POD 也被标识为可以容忍污点节点，否则该 Taints 节点不会被调度pod。

taint 标记节点举例如下：

```bash
kubectl taint nodes node1 key=value:NoSchedule
```

如果需要取消此污点可以参考下面命令：

```bash
kubectl taint nodes node1 key:NoSchedule-
```

当需要将某些 pod 调度到带有污点的节点上，必须在 pod 的 spec 字段中指定容忍度，这里有个例子可以参考：

```bash
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
  
或者

tolerations:
- key: "key"
  operator: "Exists"
  effect: "NoSchedule"

# 如果 operator 未指定，默认为 Equal
```

这里有两种特殊情况，如下：

An empty `key` with operator `Exists` matches all keys, values and effects which means this will tolerate everything.

```bash
tolerations:
- operator: "Exists"
```

An empty `effect` matches all effects with key `key`

```bash
tolerations:
- key: "key"
  operator: "Exists"
```

effect 共有三个可选项，可按实际需求进行设置：

- `NoSchedule`：POD 不会被调度到标记为 taints 节点。

- `PreferNoSchedule`：NoSchedule 的软策略版本。

- `NoExecute`：该选项意味着一旦 Taint 生效，如该节点内正在运行的 POD 没有对应 Tolerate 设置，会直接被逐出。

# 参考资料

- <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/>
- <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/>