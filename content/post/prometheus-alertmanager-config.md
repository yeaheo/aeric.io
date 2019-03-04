---
layout:      post
title:       "Prometheus Alertmanager 基本配置"
subtitle:    ""
description: "Alertmanager 作为一个独立的组件，负责接收并处理来自 Prometheus Server 的告警信息,本次我们主要介绍如何安装 Alertmanager 并且测试 Email、wechat 和 slack 等告警方式"
excerpt:     ""
date:        2019-03-01T18:06:59+08:00
author:      Aeric
image:       "https://wx1.sinaimg.cn/large/b258d7f7ly1g0ngh3n88tj21ja0lo7dk.jpg"
published:   true
tags:        ["Prometheus"]
categories:  [ "TECH" ]
---

在 Prometheus Server 中支持基于 PromQL 创建告警规则，如果满足 PromQL 定义的规则，则会产生一条告警，而告警的后续处理流程则由 AlertManager 进行管理。在 AlertManager 中我们可以与邮件，Slack 等等内置的通知方式进行集成，也可以通过 Webhook 自定义告警处理方式。AlertManager 即 Prometheus 体系中的告警处理中心。

## 安装配置 Alertmanager

告警能力在 Prometheus 的架构中被划分成两个独立的部分。如下所示，通过在 Prometheus 中定义 AlertRule（告警规则），Prometheus 会周期性的对告警规则进行计算，如果满足告警触发条件就会向 Alertmanager 发送告警信息。

![prometheus告警图](https://ws1.sinaimg.cn/large/006tKfTcly1g0e112xcb9j31io0g276b.jpg)

首先我们需要从[Alertmanager下载页](https://github.com/prometheus/alertmanager/releases)下载我们需要安装的版本，这里我们选择则安装的prometheus版本是 v0.16.1的最新版本。

```bash
$ wget https://github.com/prometheus/alertmanager/releases/download/v0.16.1/alertmanager-0.16.1.linux-amd64.tar.gz
```

解压并安装 alertmanager 服务：

```bash
$ tar xf alertmanager-0.16.1.linux-amd64.tar.gz -C /srv/
$ cd /srv/
$ mv alertmanager-0.16.1.linux-amd64/ alertmanager
$ mkdir -pv /srv/alertmanager/data
$ chown -R prometheus.prometheus /srv/alertmanager
```

创建 alertmanager 系统服务启动文件: `/usr/lib/systemd/system/alertmanager.service`

```bash
[Unit]
Description=Alertmanager
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/srv/alertmanager/alertmanager \
  --config.file=/srv/alertmanager/alertmanager.yml \
  --storage.path=/srv/alertmanager/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

完整服务启动文件参见[alertmanager.service](https://github.com/yeaheo/prometheus-huang/blob/master/service/alertmanager.service)

准备 alertmanager 配置文件：`/srv/alertmanager/alertmanager.yml`

```bash
global:
  smtp_smarthost: 'smtp.163.com:25'
  smtp_from: 'xx@163.com'
  smtp_auth_username: 'xx@163.com'
  smtp_auth_password: 'xx'
  smtp_require_tls: false

templates:
  - '/srv/alertmanager/template/*.tmpl'

route:
  group_by: ['alertname','cluster','service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 10m
  receiver: 'default-receiver'

receivers:
- name: 'default-receiver'
  email_configs:
  - to: 'xx@qq.com'
    html: '{{ template "alert.html" . }}'
    headers: { Subject: "Prometheus 告警测试邮件" }
```

> 该文件只是一个邮件报警的示例文件，不影响正常业务的使用，如果需要对业务进行调整可以根据实际情况做修改

完整 Alertmanager 配置文件参见[alertmanager.yml](https://github.com/yeaheo/prometheus-huang/blob/master/config/alertmanager/alertmanager.yml)

启动 alertmanager 服务：

```bash
$ systemctl daemon-reload
$ systemctl enable alertmanager.service
$ systemctl start alertmanager.service
$ systemctl status alertmanager.service
```

安装完成后可以访问 alertmanager 的UI界面：http://localhost:9030

配置 Prometheus 集成 Alertmanager，需要修改 prometheus 的配置文件，增加 Alertmanager 的相关配置，具体内容如下所示：

```bash
...
alerting:
  alertmanagers:
  - static_configs:
    - targets: ["localhost:9093"]
...
```

修改完成后重启 prometheus 服务即可。

## Alertmanager 集成邮件告警

Alertmanager 集成邮件告警首先需要准备好邮件的相关模板，这里我们选择用[官方默认的模板](https://github.com/prometheus/alertmanager/blob/master/template/default.tmpl),直接下载下来就能使用，不用做任何的修改。因为之前我们在配置 Alertmanager 的时候配置了模板的具体存放位置，这里直接将该模板下载到此目录下即可,目录不存在需要手动创建该目录：

```bash
$ mkdir -pv /srv/alertmanager/template/
$ cd /srv/alertmanager/template/
$ wget https://raw.githubusercontent.com/prometheus/alertmanager/master/template/default.tmpl
$ chown -R prometheus.prometheus /srv/alertmanager
```

之前 Alertmanager 的配置文件中已经贴出了针对邮件的相关配置，具体如下：

```bash
global:
  smtp_smarthost: 'smtp.163.com:25'
  smtp_from: 'xx@163.com'
  smtp_auth_username: 'xx@163.com'
  smtp_auth_password: 'xx'
  smtp_require_tls: false

templates:
  - '/srv/alertmanager/template/*.tmpl'

route:
  group_by: ['alertname','cluster','service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 10m
  receiver: 'default-receiver'
  
receivers:
- name: 'default-receiver'
  email_configs:
  - to: 'xx@qq.com'
    html: '{{ template "alert.html" . }}'
    headers: { Subject: "Prometheus 告警测试邮件" }
```

配置文件准备好后，还需要创建报警规则文件，这个是在 prometheus 里配置的，例如我们写一个关于 node_exporter 的告警规则，如下：

```bash
groups:
- name: hostStatsAlert
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: page
    annotations:
      summary: "Instance {{$labels.instance}} down"
      description: "{{$labels.instance}} of job {{$labels.job}} has been down for more than 5 minutes."
```

同时我们还是可以自定义告警规则的，我这里有几个关于主机相关指标的告警规则，可以参见[node-stats-alert.rules](https://github.com/yeaheo/prometheus-huang/blob/master/alert-rules/node-stats-alert.rules)，告警规则准备好后需要在 prometheus 里指定规则相关文件，如下所示（只做参考）：

```bash
rule_files:
  - "alert.rules"
```

配置文件修改完成后，需要重新启动 alertmanager 和 prometheus 服务，之后就可以尝试停掉 node_exporter 服务查看是否可以实现邮件告警。

## Alertmanager 集成企业微信告警

Alertmanager 的企业微信告警和邮件告警配置类似，在配置微信告警前需要准备一个微信企业号，创建自己的告警应用，并准备一些参数，配置企业微信告警需要准备的参数具体如下：

```bash
wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'(默认)
to_party: '部门id'
agent_id: '应用id'
corp_id: '维信企业号ID'
api_secret: '自己创建应用的 secret'
```

准备维信告警模板：

```bash
{{ define "wechat.default.message" }}
{{ if gt (len .Alerts.Firing) 0 -}}
Alerts Firing:
{{ range .Alerts}}
告警级别: {{ .Labels.severity }}
告警类型: {{ .Labels.alertname }}
故障主机: {{ .Labels.instance }}
告警主题: {{ .Annotations.summary }}
告警详情: {{ .Annotations.description }}
触发时间: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
{{- end }}
{{- end }}
{{ if gt (len .Alerts.Resolved) 0 -}}
Alerts Resolved:
{{ range .Alerts}}
告警级别: {{ .Labels.severity }}
告警类型: {{ .Labels.alertname }}
故障主机: {{ .Labels.instance }}
告警主题: {{ .Annotations.summary }}
触发时间: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
恢复时间: {{ .EndsAt.Format "2006-01-02 15:04:05" }}
{{- end }}
{{- end }}
{{- end }}
```

具体模板文件参见[wechat.tmpl](https://github.com/yeaheo/prometheus-huang/blob/master/alertmanager-tmpl/wechat.tmpl)

> 需要说明的是之前下载的官方模板文件已经包含了微信企业的相关配置，但是输出信息不是很友好，建议按照上面的内容对其进行修改即可

模板文件准备完成后还需要修改 alertmanager 的配置文件，增加对企业微信告警的支持：

```bash
global:
  wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
...
receivers:
- name: 'wechat'
  wechat_configs:
  - send_resolved: true
    to_party: 'xx'
    agent_id: 'xx'
    corp_id: 'xx'
    api_secret: 'xx'
```

配置文件修改后重启 prometheus 和 alertmanager 服务即可。

## Alertmanager 集成 Slack 告警

Alertmanager 的 Slack 告警和微信告警配置类似，在配置 slack 告警前需要注册一个 slack 账号和对应的频道，具体怎么搞，超出了本文档的范围，还请自行百度或者谷歌吧。

准备 slack 告警模板：

```bash
{{ define "__single_message_title" }}{{ range .Alerts.Firing }}{{ .Labels.alertname }} @ {{ .Annotations.identifier }}{{ end }}{{ range .Alerts.Resolved }}{{ .Labels.alertname }} @ {{ .Annotations.identifier }}{{ end }}{{ end }}
{{ define "custom_title" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ if or (and (eq (len .Alerts.Firing) 1) (eq (len .Alerts.Resolved) 0)) (and (eq (len .Alerts.Firing) 0) (eq (len .Alerts.Resolved) 1)) }}{{ template "__single_message_title" . }}{{ end }}{{ end }}
{{ define "custom_slack_message" }}
{{ if or (and (eq (len .Alerts.Firing) 1) (eq (len .Alerts.Resolved) 0)) (and (eq (len .Alerts.Firing) 0) (eq (len .Alerts.Resolved) 1)) }}
{{ range .Alerts.Firing }}{{ .Annotations.description }}{{ end }}{{ range .Alerts.Resolved }}{{ .Annotations.description }}{{ end }}
{{ else }}
{{ if gt (len .Alerts.Firing) 0 }}
*Alerts Firing:*
{{ range .Alerts.Firing }}- {{ .Annotations.identifier }}: {{ .Annotations.description }}
{{ end }}{{ end }}
{{ if gt (len .Alerts.Resolved) 0 }}
*Alerts Resolved:*
{{ range .Alerts.Resolved }}- {{ .Annotations.identifier }}: {{ .Annotations.description }}
{{ end }}{{ end }}
{{ end }}
{{ end }}
```

完整 salck 模板文件参见[slack.tmpl](https://github.com/yeaheo/prometheus-huang/blob/master/alertmanager-tmpl/slack.tmpl)

> 需要说明的是之前下载的官方模板文件已经包含了salck的相关配置，但是输出信息不是很友好，建议直接下载上面模板文件并将其放在模板目录下

配置 salck 告警：

```bash
...
receivers:
- name: 'slack-channel'
  slack_configs:
  - channel: #xx  (频道)
    api_url: 'https://hooks.slack.com/services/TGGQZ8GPN/BGGRF1XNG/xx'
    icon_url: 'https://avatars3.githubusercontent.com/u/3380462'
    send_resolved: true
    title: '{{ template "custom_title" . }}'
    text: '{{ template "custom_slack_message" . }}'
```

配置文件修改后重启 prometheus 和 alertmanager 服务即可。

cheers!!!

