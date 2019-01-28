---
layout:      post
title:       "使用PASS密码管理器管理密码"
subtitle:    ""
description: "PASS 是 Linux 上的一个简单的命令行密码管理器，它将密码存储在一个 gpg 加密后的文件里。这些加密后的文件很好地组织按目录结构存放，方便我们对密码进行管理。"
excerpt:     ""
date:        2018-07-29T14:59:56+08:00
author:      Aeric
image:       "https://wx1.sinaimg.cn/large/b258d7f7ly1fz7287krjcj21ja0loqbb.jpg"
published:   true
tags:        ["Pass"]
categories:  [ "TOOLS" ]
---

## 关于 PASS 工具 

PASS 是 Linux 上的一个简单的命令行密码管理器，它将密码存储在一个 gpg 加密后的文件里。这些加密后的文件很好地组织按目录结构存放，现在密码管理器还是比较普遍的，其实这些密码管理器一般分为两种，一种是基于GUI，另一种是基于CLI的，而pass这款是基于CLI的密码管理器。
pass安装完成后，所有密码都存在于 `~/.password-store` 中，它提供了添加、编辑、生成和检索密码等简单命令。它是一个非常简短和简单的 shell 脚本。 它能够临时将密码放在剪贴板上，并使用 git 跟踪密码的修改。它是一个很小的 shell 脚本，它还使用了少量的默认工具比如 gnupg、tree 和 git，同时还有活跃的社区为它提供 GUI 和扩展。

## 安装 PASS 工具

本次我们选择的安装环境是CentOS7，其他系统的安装方法类似，这里不再详细说明。
对于基于 RHEL/CentOS 的操作系统, 使用 yum 包管理器命令来安装它:

```bash
[root@ns1 ~]# yum -y install epel-release
[root@ns1 ~]# yum -y install pass
```

安装好 pass 后，就可以开始使用和配置它了。首先，由于 pass 依赖于 gpg 来对我们的密码进行加密并以安全的方式进行存储，我们必须准备好一个 gpg 密钥对。如果没有 gpg 密钥对，可以在终端输入以下命令进行创建:

```bash
[root@ns1 ~]# gpg --gen-key
```

具体过程如下:

```bash
[root@ns1 ~]# gpg --gen-key
gpg (GnuPG) 2.0.22; Copyright (C) 2013 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 
Key does not expire at all
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: cxnicxncx
Email address: xxxx@gmail.com
Comment: abc
You selected this USER-ID:
    "cxnicxncx (abc) <xxxx@gmail.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
You need a Passphrase to protect your secret key.

We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: key D9F7BEE7 marked as ultimately trusted
public and secret key created and signed.

gpg: checking the trustdb
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
pub   4096R/D9F7BEE7 2018-03-07
      Key fingerprint = 5524 E87F D75E E4A0 4BCD  EFE3 474B E193 D9F7 BEE7
uid                  cxnicxncx (abc) <xxxx@gmail.com>
sub   4096R/76250E20 2018-03-07
```

查看生成的密钥对：

```bash
[root@ns1 ~]# gpg --list-key
/root/.gnupg/pubring.gpg
------------------------
pub   4096R/D9F7BEE7 2018-03-07
uid                  cxnicxncx (abc) <xxxx@gmail.com>
sub   4096R/76250E20 2018-03-07
```

## 初始化 PASS

如果你已经有了 GPG 密钥对，请通过运行以下命令初始化本地密码存储，你可以使用 email-id 或 gpg-id 初始化。
查看gpg密钥对可以参考：

```bash
[root@ns1 ~]# gpg --list-key
/root/.gnupg/pubring.gpg
------------------------
pub   4096R/D9F7BEE7 2018-03-07
uid                  cxnicxncx (abc) <yeah6066@gmail.com>
sub   4096R/76250E20 2018-03-07
```

**初始化密码仓库:**

```bash
[root@ns1 ~]# pass init cxnicxncx  # cxnicxncx为gpg-id 
Password store initialized for cxnicxncx
```

上述命令将在 ~/.password-store 目录下创建一个密码存储区。
pass 命令提供了简单的语法来管理密码。 我们一个个来看，如何添加、编辑、生成和检索密码。

```bash
[root@ns1 ~]# pass ls
Password Store
└── yeah
或：
[root@ns1 ~]# pass show
Password Store
└── yeah
或：
[root@ns1 ~]# pass
Password Store
└── yeah
```

## 储存密码

```bash
[root@ns1 ~]# pass edit abc
这会打开默认文本编辑器，我么只需要输入密码就可以了。输入的内容会用 gpg 加密并存储为密码仓库目录中的 abc.gpg 文件。
[root@ns1 ~]# pass
Password Store
├── abc
└── yeah
```

其实我们也可以通过以分组的形式储存密码，例如将邮箱账号放到email文件夹内，将ssh账号放到ssh目录下：

```bash
[root@ns1 ~]# pass insert email/abcd@gmail.com
mkdir: created directory ‘/root/.password-store/email’
Enter password for email/abcd@gmail.com: 
Retype password for email/abcd@gmail.com: 
[root@ns1 ~]# pass insert email/abcd@live.com
Enter password for email/abcd@live.com: 
Retype password for email/abcd@live.com: 
[root@ns1 ~]# pass insert 124-ssh/dev
mkdir: created directory ‘/root/.password-store/124-ssh’
Enter password for 124-ssh/dev: 
Retype password for 124-ssh/dev: 
```

查看：

```bash
[root@ns1 ~]# pass
Password Store
├── 124-ssh
│   └── dev
├── abc
├── email
│   ├── abcd@gmail.com
│   └── abcd@live.com
└── yeah
```

## 查看密码

```bash
[root@ns1 ~]# pass abc
Lv_000abc%2018
[root@ns1 ~]# pass email/abcd@gmail.com
abc
```

需要注意的是当要查看密码时需要输入创建gpg密钥对时的密码。
**复制密码到剪切板**

```bash
[root@ns1 ~]# pass -c abc
Copied abc to clipboard. Will clear in 45 seconds.
```

## 密码相关操作

**创建新密码**

如果你想生成一些比较难以猜测的密码用于代替原有的奇怪密码，可以通过其内部的 pwgen功能来实现。

```bash
[root@ns1 ~]# pass generate abc 15
An entry already exists for abc. Overwrite it? [y/N] y
The generated password to abc is:
T%a2G~L^dPb:dg'
```

若希望密码只包含字母和数字则可以是使用 `--no-symbols` 选项。生成的密码会显示在屏幕上。也可以通过 `--clip` 或 `-c` 选项让 pass 把密码直接拷贝到剪切板中。

```bash
[root@ns1 ~]# pass generate -n abc 15 
An entry already exists for abc. Overwrite it? [y/N] y
The generated password to abc is:
MTrCm54wPO3H6Mp
```

**编辑现有的密码**

```bash
[root@ns1 ~]# pass edit yeah
```

**移除密码**

```bash
[root@ns1 ~]# pass rm abc
Are you sure you would like to delete abc? [y/N] y
removed ‘/root/.password-store/abc.gpg’
```

**保存详细信息**

```bash
[root@ns1 ~]# pass insert abc -m
Enter contents of abc and press Ctrl+D when finished:

chxiuhcnxikcnx     
name: echo.lv
info: ssh

[root@ns1 ~]# pass abc
chxiuhcnxikcnx
name: echo.lv
info: ssh
```

参考链接：<https://linux.cn/article-9407-1.html>