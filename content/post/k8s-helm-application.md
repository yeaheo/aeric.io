---
layout:      post
title:       "K8S 包管理工具 Helm - 应用"
subtitle:    ""
description: "之前已经在 kubernetes 集群中安装了 Helm 和 Tiller，那么接下来需要熟悉一下 Helm 的基本应用，主要包括利用 Helm 创建、打包、分发到本地仓库等等基本操作。"
excerpt:     ""
date:        2019-01-15T17:43:22+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/DoMTwF.jpg"
published:   true
tags:        ["Helm","Kubernetes"]
categories:  [ "TECH" ]
---

之前在 kubernetes 集群中已经安装了 Helm 和 Tiller，那么接下来我们需要熟悉一下 Helm 的基本应用，主要包括利用 Helm 创建、打包、分发、安装、升级及回滚 kubernetes 应用。

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

mychart 目录会被打包为一个 `mychart-0.1.0.tgz`  格式的压缩包，该压缩包默认会被放到当前目录下，并同时被保存到了 Helm 的本地缺省仓库目录中。

如果打包时需要自定义压缩包的存放位置可以在打包时增加 `-d`参数，例如：

```bash
$ helm package -d /opt/ mychart/
Successfully packaged chart and saved it to: /opt/mychart-0.1.0.tgz
```

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

其实我们还可以将我们自己打包的 Charts 文件上传至我们的私有 helm 仓库，helm 私有仓库可以用 harbor 实现，具体用 harbor 怎样来管理 helm charts 可以参考：[用 Harbor 管理 Helm Charts](https://aeric.io/post/harbor-manage-helm-charts)

 当我们设置完 Chart 配置并将其发布到 Repositry 后就可以使用 `helm install` 命令将应用发布到 Kubernetes 集群中，发布完成后还可以用 Helm 管理对应的 Kubernetes 应用，可以进行版本的升级和回滚等操作。

## 检查配置和模板是否有效

当使用 `helm install` 命令部署应用时，实际上就是将 templates 目录下的模板文件渲染成 Kubernetes 能够识别的 YAML 格式。

当我们修改好 Chart 文件后，可以用如下命令检查配置和模板是否有效：

```bash
helm install --dry-run --debug <chart_dir> --name <release_name>
```

上述命令输出中包含了模板的变量配置与最终渲染的 YAML 文件，例如:

```
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



## 部署应用到 Kubernetes 集群

验证完成没有问题后，我们就可以使用以下命令将其部署到 Kubernetes 上了:

```bash
# 部署时需指定 Chart 名及 Release（部署的实例）名。
$ helm install local/mychart --name helm-test
NAME:   helm-test
LAST DEPLOYED: Mon Aug 27 11:28:28 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME               TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)  AGE
helm-test-mychart  ClusterIP  10.254.128.14  <none>       80/TCP   3s

==> v1beta2/Deployment
NAME               DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
helm-test-mychart  1        0        0           0          3s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=mychart,release=helm-test" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

> 上述命令也可以在`mychart`目录下执行 `helm install .`将 nginx 部署到 kubernetes 集群上

现在 nginx 已经部署到 kubernetes 集群上，本地执行提示中的命令在本地主机上访问到 nginx 实例：

```bash
$ export POD_NAME=$(kubectl get pods --namespace default -l "app=mychart,release=helm-test" -o jsonpath="{.items[0].metadata.name}")
$ echo "Visit http://127.0.0.1:8080 to use your application"
$ kubectl port-forward $POD_NAME 8080:80
```

具体访问效果如下图所示：

```html
$ curl -s http://127.0.0.1:8090
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```



## 管理部署的 Release

当部署 Release 到 Kubernetes 集群后，可以使用下面的命令列出的所有已部署的 Release 以及其对应的 Chart：

```bash
$ helm list
NAME     	REVISION	UPDATED                 	STATUS  	CHART        	NAMESPACE
helm-test	1       	Mon Aug 27 11:28:28 2018	DEPLOYED	mychart-0.2.0	default  
```

不仅如此，我们还可以用下面命令查看某个 Release 的具体状态：

```bash
$ helm status helm-test
LAST DEPLOYED: Mon Aug 27 11:28:28 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME               TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)  AGE
helm-test-mychart  ClusterIP  10.254.128.14  <none>       80/TCP   11m

==> v1beta2/Deployment
NAME               DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
helm-test-mychart  1        1        1           1          11m

==> v1/Pod(related)
NAME                                READY  STATUS   RESTARTS  AGE
helm-test-mychart-6cdfc4d97c-vbwx5  1/1    Running  0         11m


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=mychart,release=helm-test" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

也可以用如下命令查看已部署应用的详细信息：

```bash
$ helm get helm-test
```



### 升级 Release

从上面 `helm list` 输出的结果中我们可以看到有一个 Revision（更改历史）字段，该字段用于表示某一个 Release 被更新的次数，我们可以用该特性对已部署的 Release 进行更新。

**模拟应用升级**

首先，需要修改 `Chart.yaml` 文件，将应用版本从 `0.2.0` 修改为 `0.3.0` ，然后使用 `helm package` 命令打包并发布到本地仓库：

```bash
$ cd mychart/
$ cat Chart.yaml 
apiVersion: v1
appVersion: "1.0"
description: A Helm chart for Kubernetes
name: mychart
version: 0.3.0

$ helm package mychart
Successfully packaged chart and saved it to: /opt/workspace/mychart-0.3.0.tgz
```

查询本地仓库版本：

```bash
$ helm search mychart -l
NAME         	CHART VERSION	APP VERSION	DESCRIPTION                
local/mychart	0.3.0        	1.0        	A Helm chart for Kubernetes
local/mychart	0.2.0        	1.0        	A Helm chart for Kubernetes
local/mychart	0.1.0        	1.0        	A Helm chart for Kubernetes
```

升级应用

用 `helm upgrade` 命令将已部署的 helm-test 升级到新版本:

```bash
$ helm upgrade helm-test local/mychart
Release "helm-test" has been upgraded. Happy Helming!
```

> 你可以通过 `--version` 参数指定需要升级的版本号，如果没有指定版本号，则默认使用最新版本

升级完成后再次查看，注意观察 `Revision` 字段：

```bash
$ helm list
NAME     	REVISION	UPDATED                 	STATUS  	CHART        	NAMESPACE
helm-test	2       	Mon Aug 27 11:58:10 2018	DEPLOYED	mychart-0.3.0	default  
```

可以看到 `Revision` 字段由原来的 1 变成了 2，`Chart` 字段也由 `mychart-0.2.0` 升级到了 `mychart-0.3.0` ,表示升级完成。



### 回滚 Release

如果更新后的程序运行有问题，需要回退到旧版本的应用。当遇到这种问题后我们可以使用 `helm history` 命令查看一个 Release 的所有变更记录：

```bash
$ helm history helm-test
REVISION	UPDATED                 	STATUS    	CHART        	DESCRIPTION     
1       	Mon Aug 27 11:28:28 2018	SUPERSEDED	mychart-0.2.0	Install complete
2       	Mon Aug 27 11:58:10 2018	DEPLOYED  	mychart-0.3.0	Upgrade complete
```

当我们知道了应用的变更记录后，我们可以选择回退应用到指定版本：

```bash
$ helm rollback helm-test 1
Rollback was a success! Happy Helming!
```

> 其中的参数 1 是 helm history 查看到 Release 的历史记录中 REVISION 对应的值

再次查看 Release 的变更记录：

```bash
$ helm history helm-test
REVISION	UPDATED                 	STATUS    	CHART        	DESCRIPTION     
1       	Mon Aug 27 11:28:28 2018	SUPERSEDED	mychart-0.2.0	Install complete
2       	Mon Aug 27 11:58:10 2018	SUPERSEDED	mychart-0.3.0	Upgrade complete
3       	Mon Aug 27 12:06:26 2018	DEPLOYED  	mychart-0.2.0	Rollback to 1   
```

再次查看现有 Release ：

```bash
$ helm list
NAME     	REVISION	UPDATED                 	STATUS  	CHART        	NAMESPACE
helm-test	3       	Mon Aug 27 12:06:26 2018	DEPLOYED	mychart-0.2.0	default  
```

可以看到 `Revision` 字段由原来的 2 变成了 3，`Chart` 字段也由 `mychart-0.3.0` 回退到了 `mychart-0.2.0` ,表示回退应用完成。



### 删除 Release

删除应用比较方便，如果需要删除一个已部署的 Release，可以利用 `helm delete` 命令来完成删除：

```bash
$ helm delete helm-test
release "helm-test" deleted
$ helm list
```

当我们删除应用后我们可以使用如下命令查看被删除应用的状态：

```bash
$ helm list -a
NAME     	REVISION	UPDATED                 	STATUS 	CHART        	NAMESPACE
helm-test	3       	Mon Aug 27 12:06:26 2018	DELETED	mychart-0.2.0	default  
```

由上述内容可知被删除的应用已经被标记为 `DELETED` 状态。

也可以使用 `--deleted` 参数来列出已经删除的 Release ：

```bash
$ helm list --deleted 
NAME     	REVISION	UPDATED                 	STATUS 	CHART        	NAMESPACE
helm-test	3       	Mon Aug 27 12:06:26 2018	DELETED	mychart-0.2.0	default  
```

查看被删除应用的历史变更记录：

```bash
$ helm history helm-test
REVISION	UPDATED                 	STATUS    	CHART        	DESCRIPTION      
1       	Mon Aug 27 11:28:28 2018	SUPERSEDED	mychart-0.2.0	Install complete 
2       	Mon Aug 27 11:58:10 2018	SUPERSEDED	mychart-0.3.0	Upgrade complete 
3       	Mon Aug 27 12:06:26 2018	DELETED   	mychart-0.2.0	Deletion complete
```

有时候我们需要移除指定 Release 所有相关的 Kubernetes 资源和 Release 的历史记录，我们可以利用如下命令：

```bash
$ helm delete --purge helm-test
release "helm-test" deleted

$ helm history helm-test
Error: release: "helm-test" not found
```

