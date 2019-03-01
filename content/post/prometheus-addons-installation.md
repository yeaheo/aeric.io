---
layout:      post
title:       "Prometheus 安装和基本配置"
subtitle:    ""
description: "之前简单介绍了 Prometheus 的工作模式和工作原理，本次主要是通过部署 Prometheus Server 和 node_exporter 并集成 grafana 可视化来更进一步了解 Prometheus 是怎样获取节点监控指标"
excerpt:     ""
date:        2019-03-01T10:12:14+08:00
author:      Aeric
image:       "https://wx3.sinaimg.cn/large/b258d7f7ly1g0maj74zkkj21ja0loqmw.jpg"
published:   true
tags:        ["Prometheus"]
categories:  [ "TECH" ]
---

Prometheus 是一个开放性的监控解决方案，用户可以非常方便的安装和使用 Prometheus 并且能够非常方便的对其进行扩展。为了能够更加直观的了解 Prometheus Server，接下来我们将在本地部署并运行一个 Prometheus Server实例，通过 Node Exporter 采集当前主机的系统资源使用情况。 并通过 Grafana 创建一个简单的可视化仪表盘。

Prometheus 基于 Golang 编写，编译后的软件包，不依赖于任何的第三方依赖。用户只需要下载对应平台的二进制包，解压并且添加基本的配置即可正常启动 Prometheus Server。具体安装过程可以参考如下内容。

## 安装配置 Prometheus Server

本次我们选择在 CentOS7 上安装 prometheus ,其他系统安装过程类似，这里不再一一赘述。

系统环境如下：

```bash
$ cat /etc/redhat-release
CentOS Linux release 7.5.1804 (Core)
$ uname -r
3.10.0-862.el7.x86_64
```

为了安全，我们这里不用 root 用户启动相关服务，而是用我们自建的 prometheus 用户启动服务，首先需要创建一个用户:

```bash
$ groupadd prometheus
$ useradd -g prometheus -M -s /sbin/nologin prometheus
```

我们需要从 [prometheus下载页](https://github.com/prometheus/prometheus/releases) 下载我们需要安装的版本，这里我们选择则安装的 prometheus 版本是 v2.7.1 的最新版本。

```bash
$ wget https://github.com/prometheus/prometheus/releases/download/v2.7.1/prometheus-2.7.1.linux-amd64.tar.gz
```

解压并安装 prometheus 服务：

```bash
$ tar xf prometheus-2.7.1.linux-amd64.tar.gz -C /srv/
$ cd /srv/
$ mv prometheus-2.7.1.linux-amd64/ prometheus
$ mkdir -pv /srv/prometheus/data
$ chown -R prometheus.prometheus /srv/prometheus
```

创建 prometheus 系统服务启动文件 `/usr/lib/systemd/system/prometheus.service`：

```bash
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=prometheus
Restart=on-failure
ExecStart=/srv/prometheus/prometheus \
  --config.file=/srv/prometheus/prometheus.yml \
  --storage.tsdb.path=/srv/prometheus/data
ExecReload=/bin/kill -HUP $MAINPID
[Install]
WantedBy=multi-user.target
```

完整 prometheus 系统服务启动文件参见：[prometheus.service](https://github.com/yeaheo/prometheus-huang/blob/master/service/prometheus.service)

修改 prometheus 配置文件 `/srv/prometheus/prometheus.yml`：

```bash
[root@node01 ~]# grep -v '^#' /srv/prometheus/prometheus.yml
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 

alerting:
  alertmanagers:
  - static_configs:
    - targets: ["localhost:9093"]

rule_files:
  #- "alert.rules"
  
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval:     5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    scrape_interval:     10s
    static_configs:
      - targets: ['localhost:9100']
```

> 该配置文件比较完整，该节点安装了 node_exporter 以及 alertmanager 服务，可以先按照此配置文件做配置，不影响服务的启动过程

完整 prometheus 配置文件可以参见：[prometheus.yml](https://github.com/yeaheo/prometheus-huang/blob/master/config/prometheus/prometheus.yml)

启动服务：

```bash
$ systemctl daemon-reload
$ systemctl start prometheus.service
$ systemctl enable prometheus.service
$ systemctl status prometheus.service
```

Prometheus 服务支持热加载配置：

```bash
$ systemctl reload prometheus.service
```

 Prometheus 服务启动完成后，可以通过[http://localhost:9090](http://localhost:9090/)访问 Prometheus 的 UI 界面。

## 安装配置 node_exporter

为监控服务器 CPU , 内存 , 磁盘 , I/O 等信息，需要在被监控机器上安装 node_exporter 服务。

首先我们需要从 [node_exporter下载页](https://github.com/prometheus/node_exporter/releases) 下载我们需要安装的版本，这里我们选择则安装的 node_exporter 版本是v0.17.0 的最新版本。

```bash
$ wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
```

解压并安装 node_exporter 服务：

```bash
$ tar xf /opt/soft/node_exporter-0.17.0.linux-amd64.tar.gz -C /srv/
$ cd /srv/
$ mv node_exporter-0.17.0.linux-amd64/ node_exporter
$ chown -R prometheus.prometheus /srv/node_exporter
```

创建 node_exporter 系统服务启动文件 `/usr/lib/systemd/system/node_exporter.service`

```bash
#Prometheus Node Exporter Upstart script
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/srv/node_exporter/node_exporter

[Install]
WantedBy=default.target
```

完整 node_exporter 系统服务启动文件参见：[node_exporter.service](https://github.com/yeaheo/prometheus-huang/blob/master/service/node_exporter.service)

启动 node_exporter 服务：

```bash
$ systemctl daemon-reload
$ systemctl enable node_exporter
$ systemctl start node_exporter
$ systemctl status node_exporter
```

服务启动后可以用 http://localhost:9100/metrics 测试 node_exporter 是否获取到节点的监控指标。

如果可以正常获取到节点的指标后，我们可以将 node_exporter 整合到 prometheus 中，具体如下：

修改 prometheus 的配置文件`/srv/prometheus/prometheus.yml`，增加如下内容：

```bash
scrape_configs:
...
- job_name: 'node'
    scrape_interval:     10s
    static_configs:
      - targets: ['localhost:9100']
```

> 之前的 prometheus 配置文件已经做过修改了，这里只是提及一下

重启 Prometheus 服务：

```bash
$ systemctl reload prometheus.service
```

之后就可以通过 Prometheus 服务获取该主机的相关资源了

## 安装 Grafana 展示工具

Grafana 我们主要用它来展示 Prometheus 的监控指标的，这样可以直观查看各节点或者服务的状态，本次安装 grafana 我们直接用 yum 安装即可，具体操作也可以参考[官方文档](http://docs.grafana.org/installation/rpm/)

首先，需要准备 grafana 的 repo 源，手动添加 `/etc/yum.repos.d/grafana.repo`文件：

```bash
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
```

然后就可以用 yum 安装 grafana 了：

```bash
$ yum makecache
$ yum -y install grafana
```

等待安装完成后就可以启动服务了：

```bash
$ service grafana-server start
```

服务启动后 grafana 默认监听在 3000 端口 ，可以通过 `http://localhost:3000` 访问 grafana 的 ui 界面，默认登录账号密码为 `admin/admin` ，第一次登录需要我们重置密码。

当 grafana 的页面可以正常访问后，我们就可以添加数据源了，具体操作流程如下：

"Configration"---"Data Sources" 然后可以按照下图所示进行配置，需要注意的是 prometheus 的地址需要根据实际情况做修改。

![grafana 设置数据源](https://wx4.sinaimg.cn/large/b258d7f7ly1g0nc7qknkvj20i90nrdj6.jpg)

grafana 的数据源配置完成后，可以导入一个 dashboard 模板文件，建议节点模板使用 [node_exporter 展示面板模板](https://grafana.com/dashboards/8919)

导入成功后完整的监控面板如下所示：

![node_exporter 监控面板](https://wx4.sinaimg.cn/large/b258d7f7ly1g0nclvl010j21ef0o7ai3.jpg)

