---
layout:      post
title:       "K8S 包管理工具 Helm - 应用"
subtitle:    ""
description: "之前已经在 kubernetes 集群中已经安装了 Helm 和 Tiller，那么接下来需要熟悉一下 Helm 的基本应用，主要包括借助 Helm 创建、打包、分发到本地仓库等等基本操作。"
excerpt:     ""
date:        2019-01-15T17:43:22+08:00
author:      Aeric
image:       "https://wx3.sinaimg.cn/large/b258d7f7ly1fz72891rp0j21ja0loncv.jpg"
published:   true
tags:        ["Helm","Kubernetes"]
categories:  [ "TECH" ]
---

之前已经在 kubernetes 集群中已经安装了 Helm 和 Tiller，那么接下来我们需要熟悉一下 Helm 的基本应用，主要包括借助 Helm 创建、打包、分发、安装、升级及回滚 kubernetes 应用。

## 创建 Helm Chart

首先我们需要创建一个 Chart，以后的基本操作都基于这个 Chart ：

```bash
$ helm create mychart
Creating mychart
```

当执行上述命令创建了 Chart 后，会在当前目录下生成相应的 `mychart` 目录，该目录结构如下所示：

```bash
$ tree mychart/
mychart/
├── charts
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── ingress.yaml
│   ├── NOTES.txt
│   └── service.yaml
└── values.yaml

2 directories, 7 files
```

> 对于上述目录下的文件，我们主要关注的是 `Chart.yaml` 、`values.yaml` 、`NOTES.txt`  以及 `templates` 目录

这几个文件的主要用途如下描述：

```bash
Chart.yaml   # 用于描述这个 Chart 的相关信息，包括名字、描述信息以及版本等;
values.yaml  # 用于存储 templates 目录中模板文件中用到变量的值;
NOTES.txt    # 用于说明 Chart 部署后的一些信息，例如：如何使用这个 Chart、列出缺省的设置等;
Templates    # 目录下是 YAML 文件的模板，该模板文件遵循 Go template 语法;
```

我们需要注意的是：

> templates 目录下 YAML 文件模板的值默认都是在 `values.yaml` 里定义的，例如，在 `deployment.yaml` 中定义的容器镜像 `image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"` 其中的 `.Values.image.repository` 的值就是在  `values.yaml` 里定义的 nginx，`.Values.image.tag` 的值就是 stable

YAML 文件内容如下：

```bash
$ cat values.yaml | grep -E "repository|tag"
repository: nginx
tag: stable
```

以上两个变量值是在 `create chart` 的时候自动生成的默认值，我们可以根据实际情况进行修改。

## 完善应用的基本信息

由上述内容我们可以知道 `Chart.yaml` 文件是用来描述应用的相关信息的，所以我们需要修改这个文件的内容，该文件缺省内容如下：

```bash
$ cat Chart.yaml 
apiVersion: v1
appVersion: "1.0"
description: A Helm chart for Kubernetes
name: mychart
version: 0.1.0
```

官方还有比较完整的文件示例：

```
apiVersion: The chart API version, always "v1" (required)
name: The name of the chart (required)
version: A SemVer 2 version (required)
kubeVersion: A SemVer range of compatible Kubernetes versions (optional)
description: A single-sentence description of this project (optional)
keywords:
  - A list of keywords about this project (optional)
home: The URL of this project's home page (optional)
sources:
  - A list of URLs to source code for this project (optional)
maintainers: # (optional)
  - name: The maintainer's name (required for each maintainer)
    email: The maintainer's email (optional for each maintainer)
    url: A URL for the maintainer (optional for each maintainer)
engine: gotpl # The name of the template engine (optional, defaults to gotpl)
icon: A URL to an SVG or PNG image to be used as an icon (optional).
appVersion: The version of the app that this contains (optional). This needn't be SemVer.
deprecated: Whether this chart is deprecated (optional, boolean)
tillerVersion: The version of Tiller that this chart requires. This should be expressed as a SemVer range: ">2.0.0" (optional)
```

我们只需要根据我们的需求对其进行相关更改即可。

### 完善应用具体部署信息

编辑 `values.yaml`，当 Chart 创建后默认会在 Kubernetes 部署一个 Nginx。 mychart 应用的 `values.yaml` 文件的具体内容如下：

```
$ cat values.yaml 
# Default values for mychart.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: nginx
  tag: stable
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  path: /
  hosts:
    - chart-example.local
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #  cpu: 100m
  #  memory: 128Mi
  # requests:
  #  cpu: 100m
  #  memory: 128Mi

nodeSelector: {}

tolerations: []

affinity: {}
```

当我们修改好 `valuse.yaml` 文件后，我们可以用如下命令检查依赖和模板配置是否正确：

```bash
$ helm lint mychart/
==> Linting mychart/
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

> 如果文件格式错误，可以根据提示进行修改

我们也可以使用`helm install --dry-run --debug <chart_dir>`命令来验证chart配置。该输出中包含了模板的变量配置与最终渲染的 yaml 文件。

```bash
$ helm install --dry-run --debug mychart
[debug] Created tunnel using local port: '36589'

[debug] SERVER: "127.0.0.1:36589"

[debug] Original chart version: ""
[debug] CHART PATH: /opt/workspace/mychart

NAME:   youngling-flee
REVISION: 1
RELEASED: Mon Aug 27 10:56:07 2018
CHART: mychart-0.1.0
USER-SUPPLIED VALUES:
{}

COMPUTED VALUES:
affinity: {}
image:
  pullPolicy: IfNotPresent
  repository: nginx
  tag: stable
ingress:
  annotations: {}
  enabled: false
  hosts:
  - chart-example.local
  path: /
  tls: []
nodeSelector: {}
replicaCount: 1
resources: {}
service:
  port: 80
  type: ClusterIP
tolerations: []

HOOKS:
MANIFEST:

---
# Source: mychart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: youngling-flee-mychart
  labels:
    app: mychart
    chart: mychart-0.1.0
    release: youngling-flee
    heritage: Tiller
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: mychart
    release: youngling-flee
---
# Source: mychart/templates/deployment.yaml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: youngling-flee-mychart
  labels:
    app: mychart
    chart: mychart-0.1.0
    release: youngling-flee
    heritage: Tiller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mychart
      release: youngling-flee
  template:
    metadata:
      labels:
        app: mychart
        release: youngling-flee
    spec:
      containers:
        - name: mychart
          image: "nginx:stable"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {}

```

我们可以看到 Deployment 和 Service 的名字前半截由两个随机的单词组成，最后才是我们在`values.yaml`中配置的值。

## 打包应用

当我们修改完相关 YAML 文件的相关配置项后，下一步就是将该应用打包，具体打包操作如下所示：

```bash
$ helm package mychart/
Successfully packaged chart and saved it to: /opt/workspace/mychart-0.1.0.tgz
```

mychart 目录会被打包为一个 `mychart-0.1.0.tgz`  格式的压缩包，该压缩包会被放到当前目录下，并同时被保存到了 Helm 的本地缺省仓库目录中。

如果需要查看已打包的应用的具体地址，可以在打包的时候加上 `--debug` 参数，具体输出内容如下：

```bash
$ helm package mychart/ --debug
Successfully packaged chart and saved it to: /opt/workspace/mychart-0.1.0.tgz
[debug] Successfully saved /opt/workspace/mychart-0.1.0.tgz to /root/.helm/repository/local
```

## 将打包应用发布到 Repository

我们已经打包了 Chart 并发布到了 Helm 的本地目录中，但通过 `helm search` 命令查找，并不能找不到刚才生成的 mychart 包:

```bash
$ helm search mychart
No results found
```

这是因为 Repository 目录中的 Chart 包还没有被 Helm 管理。通过 `helm repo list`命令可以看到目前 Helm 中已配置的 Repository 的信息。

```bash
$ helm repo list
NAME    URL
stable  https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```

在比较新的版本上，当我们安装 Tiller 的时候会自动创建一个名为 `local` 本地仓库,但是有时候我们在搜索 Chart 的时候会报错，这个是因为没有启动本地仓库而已，我们需要手动启动本地仓库：

```bash
$ helm serve &
Now serving you on 127.0.0.1:8879
```

当启动本地仓库后我们再次搜索 chart 就会显示出来，例如：

```bash
$ helm search mychart -l
NAME         	CHART VERSION	APP VERSION	DESCRIPTION                
local/mychart	0.2.0        	1.0        	A Helm chart for Kubernetes
local/mychart	0.1.0        	1.0        	A Helm chart for Kubernetes
# -l 参数是显示所有历史版本，默认只显示最新版本
$ helm search mychart
NAME         	CHART VERSION	APP VERSION	DESCRIPTION                
local/mychart	0.2.0        	1.0        	A Helm chart for Kubernetes
```

## 设置helm命令自动补全

为了方便 helm 命令的使用，helm 提供了自动补全功能，如果使用 zsh 请执行：

```bash
source <(helm completion zsh)
```

如果使用 bash 请执行：

```bash
source <(helm completion bash)
```

> 如果仅仅执行上述命令是不能达到我们预期的，当新开一个 bash 终端后是不能自动补全的，这就需要我们再做些配置，具体的就是将上述命令写到 `/etc/profile` 或者 `~/.bashrc` 文件下。

```bash
echo "source <(helm completion bash)" >> ~/.bashrc
```



### 其他配置项

在新版本下默认情况下，启动本地服务后，搜索 chart 是没问题的，但是有时候也会出现本地服务连接失效的问题，当出现此问题后我们可以尝试按如下步骤操作，有些步骤是可以不做的，例如，更改存储路径等。

默认情况下该服务只监听 127.0.0.1，如果你要绑定到其它网络接口，可使用以下命令：

```bash
$ helm serve --address $yourIP:8879 &
```

如果你想使用指定目录来做为 Helm Repository 的存储目录，可以加上 `--repo-path` 参数：

```bash
$ helm serve --address $yourIP:8879 --repo-path /data/helm/repository/ --url http://$yourIP:8879/charts/
```

同时也可以通过 `helm repo index` 命令将 Chart 的 Metadata 记录更新在 index.yaml 文件中:

```bash
# 更新 Helm Repository 的索引文件
$ cd /home/k8s/.helm/repository/local
$ helm repo index --url=http://$yourIP:8879 .
```

完成启动本地 Helm Repository Server 后，就可以将本地 Repository 加入 Helm 的 Repo 列表并更新 repo:

```bash
$ helm repo add local http://127.0.0.1:8879
"local" has been added to your repositories

$ helm repo update
```

将本地 Repository 加入 Helm 的 Repo 列表后再次搜索 chart 一般就可以得到结果了，如果还有报错，可以依据报错信息查找问题再解决问题。