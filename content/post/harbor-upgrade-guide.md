---
layout:      post
title:       "记一次harbor的升级之旅"
subtitle:    ""
description: "之前安装的harbor版本是v1.6的版本，由于在v1.7版本中新增加了对helm的支持，所以为了更充分的利用harbor镜像仓库，我们将进行一次升级，将harbor升级到目前最新的v1.7.1版本"
excerpt:     ""
date:        2019-01-10T14:37:01+08:00
author:      Eric
image:       "https://wx3.sinaimg.cn/large/b258d7f7ly1fz0o7p0lbyj21ja0lok3g.jpg"
published:   true
tags:        ["Docker","Docker-compose","Harbor"]
categories:  [ TECH ]
---

之前安装的 `harbor`版本是 `v1.6`的版本，由于在 `v1.7`版本中新增加了对 `helm`的支持，所以为了更充分的利用 harbor 镜像仓库，我们将进行一次升级，将 harbor 升级到目前最新的 `v1.7.1`版本。

`v1.7`版本的 harbor 增加了许多新特性，具体如下：

- Support deploy Harbor with Helm Chart, enables the user to have high availability of Harbor services, refer to the [Installation and Configuration Guide](https://github.com/goharbor/harbor/blob/release-1.7.0/docs/installation_guide.md).
- Support on-demand Garbage Collection, enables the admin to configure run docker registry garbage collection manually or automatically with a cron schedule.
- Support Image Retag, enables the user to tag image to different repositories and projects, this is particularly useful in cases when images need to be retagged programmatically in a CI pipeline.
- Support Image Build History, makes it easy to see the contents of a container image, refer to the User Guide.
- Support Logger customization, enables the user to customize STDOUT / STDERR / FILE / DB logger of running jobs.
- Improve user experience of Helm Chart Repository:
  - Chart searching included in the global search results
  - Show chart versions total number in the chart list
  - Mark labels to helm charts
  - The latest version can be downloaded as default one on the chart list view
  - The chart can be deleted by deleting all the versions under it

 Harbor 的升级有几方面需要注意：

- 在升级之前需要先进行相关数据的备份工作
- 本博客内容只适用于从v1.6.0迁移到当前版本，如果要从早期版本升级，请参阅发行版分支中的迁移指南以升级到v1.6.0，并按照本文档升级到更高版本
- 从v1.6.0起，Harbor会在启动时自动尝试迁移数据库模式，因此如果从v1.6.0或更高版本升级，则无需调用迁移器工具来迁移数据
- 从v1.6.0起，Harbor将数据库从MariaDB迁移到PostgreSQL，并将Harbor，Notary和Clair DB合并为一个
- 有关数据库架构的更改，请参阅[更改日志](https://github.com/goharbor/harbor/blob/master/tools/migration/db/changelog.md)

## 升级 Harbor

一些目录说明：

- 备份文件目录： `/srv`
- 旧版本备份目录：`/srv/harbor_older`
- 旧版本数据备份目录：`/srv/database`
- 新版本软件下载目录：`/opt/soft`

首先，关闭现在运行的 Harbor 服务：

```bash
$ cd /srv/harbor
$ docker-compose down
Stopping harbor-jobservice  ... done
Stopping nginx              ... done
Stopping harbor-ui          ... done
Stopping redis              ... done
Stopping harbor-db          ... done
Stopping harbor-adminserver ... done
Stopping registry           ... done
Stopping harbor-log         ... done
Removing harbor-jobservice  ... done
Removing nginx              ... done
Removing harbor-ui          ... done
Removing redis              ... done
Removing harbor-db          ... done
Removing harbor-adminserver ... done
Removing registry           ... done
Removing harbor-log         ... done
Removing network harbor_harbor
```

升级之前需要先进行原版本的备份，避免升级失败可以自由回滚到旧版本：

```bash
$ mv harbor /srv/harbor_older
```

备份Harbor数据，Harbor 的数据目录默认为 `/data/database`：

```bash
$ cp -a /data/database /srv/database
```

从 [Harbor版本下载页]([https://github.com/goharbor/harbor/releases](https://github.com/goharbor/harbor/releases))下载最新版 Harbor 文件，这里我们直接下载离线安装包进行升级：

```bash
$ cd /opt/soft
$ wget https://storage.googleapis.com/harbor-releases/release-1.7.0/harbor-offline-installer-v1.7.1.tgz
```

在升级 Harbor 之前，先要进行迁移。迁移工具作为 docker 镜像提供，因此我们应该从 docker hub 中提取图像。在以下命令中将 [tag] 替换为需要升级的 Harbor 发行版本（例如v1.5.0）,这里我们用 `v1.7.1`版本的镜像：

```bash
$ docker pull goharbor/harbor-migrator:[tag]
$ docker pull goharbor/harbor-migrator:v1.7.1
```

更新配置文件`harbor.cfg`

```bash
$ docker run -it --rm -v ${harbor_cfg}:/harbor-migration/harbor-cfg/harbor.cfg goharbor/harbor-migrator:v1.7.1 --cfg up
```

> 这里的 `${harbor_cfg}`指的是我们之前安装的 harbor 的配置文件全路径，例如之前 harbor 版本的安装路径为 `/srv/harbor`，那么这里的 `${harbor_cfg}`指的就是 `/srv/harbor/harbor.cfg`

以下是我的具体执行步骤，请参考：

```bash
# 备份harbor
$ mv /srv/harbor /srv/harbor_older
$ cd /srv/harbor_older

# 备份harbor配置文件
$ cp harbor.cfg harbor.cfg.bak

$ docker run -it --rm -v /srv/harbor_older/harbor.cfg:/harbor-migration/harbor-cfg/harbor.cfg goharbor/harbor-migrator:v1.7.1 --cfg up
Please backup before upgrade,
Enter y to continue updating or n to abort: y
The path of the migrated harbor.cfg is not set, the input file will be overwritten.
input version: 1.6.0, migrator chain: ['1.7.0']
migrating to version 1.7.0
Written new values to /harbor-migration/harbor-cfg/harbor.cfg
```

执行完上述步骤后会生成一个新的 `harbor.cfg`文件，我们需要将此文件复制到新的 harbor 版本目录下：

```bash
$ tar xf /opt/soft/harbor-offline-installer-v1.7.1.tgz -C /srv/
$ cp -f /srv/harbor_older/harbor.cfg /srv/harbor/
```

配置文件更新完成后，就可以升级了，需要注意的是默认新版 harbor 不会启用 `chart repository service`，如果需要管理 `helm`，我们需要在安装时添加额外的参数，例如：

```bash
## 默认安装
$ cd /srv/harbor
$ ./install.sh

## 启动 chart repository service 服务
$ cd /srv/harbor
$ ./install.sh --with-chartmuseum
```

等待安装完成即可，安装完成后会有如下类似提示：

```bash
...
✔ ----Harbor has been installed and started successfully.----
...
```

## 回滚到旧版本

如果升级失败，我们可以按照如下过程回滚到旧版本：

```bash
$ cd /srv/harbor
$ docker-compose down
$ cd ..
$ rm -rf harbor
$ mv harbor_older harbor
$ cp -a /srv/database /data/
$ cd /srv/harbor
$ ./install.sh
```



