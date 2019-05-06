---
layout:      post
title:       "Nginx Ingress 配置 HTTPS"
subtitle:    ""
description: "Nginx Ingress 默认并没有启用 https，如果我们需要实现 Ingress 的 https 方式访问，还需要我们配置 annotation 或者 configmap，这里主要说明一下 Ingress 如何通过 annotation 配置 https"
excerpt:     ""
date:        2019-05-06T17:35:43+08:00
author:      Aeric
image:       "https://aericio.oss-cn-beijing.aliyuncs.com/images/bg/gdd40dqv.jpg"
published:   true
tags:        ["Kubernetes","Ingress"]
categories:  [ "TECH" ]
---

对于 Nginx Ingress 的 TLS 配置，[官方文档](<https://kubernetes.github.io/ingress-nginx/user-guide/tls/>)已经写得很清楚了，只是有的地方只是点了一下，并没有做出详细的说明，可以说还是有点坑的，哈哈。这里我实际从头开始操作一下，希望可以帮到大家，少走弯路。

Nginx Ingress 的安装部署，可以参照[官方文档](<https://kubernetes.github.io/ingress-nginx/deploy/>)进行安装，安装其实很简单，按照官方文档一步步安装就行了。这里我就不搞了，本次 Kubernetes 集群我用的是阿里云的集群，Nginx Ingress 已经安装完成了。

Nginx Ingress 配置 TLS 支持 HTTPS 方式访问一般就分为三个步骤：**1.制作证书；2.创建证书的 secret；3.在 Ingress 开启证书**

> 证书这一块我们可以自签证书（不受信任），也可以使用正规机构颁发的证书

### 创建证书

首先我们使用我们自签的证书：

```bash
# 生成 CA 自签证书
mkdir cert && cd cert
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

# 编辑 openssl 配置
cp /etc/pki/tls/openssl.cnf .
vim openssl.cnf

# 主要修改如下
[req]
req_extensions = v3_req # 这行默认注释关着的 把注释删掉
# 下面配置是新增的
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = saas-delta.xx.com

# 生成证书
openssl genrsa -out ingress-key.pem 2048
openssl req -new -key ingress-key.pem -out ingress.csr -subj "/CN=kube-ingress" -config openssl.cnf
openssl x509 -req -in ingress.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ingress.pem -days 365 -extensions v3_req -extfile openssl.cnf
```

自签证书生成后就可以用证书和证书密钥创建 secret 了，这里为了方便，我用的是正规机构颁发的证书，如下所示：

```bash
👍 ls
1_xx.cn_bundle.crt 2_xx.cn.key
```

### 创建 secret

创建 secret 用如下命令创建即可：

```bash
kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}
```

我实际操作的指令：

```bash
kubectl create secret tls ingress-secret --key 2_xx.cn.key --cert 1_xx.cn_bundle.crt -n saas-delta
```

> 创建 secret 时尽量要和 ingress 实例在一个 namespace，这里我的是 saas-delta 命名空间

创建 secret 后可以通过集群查看：

```bash
👍 kubectl get secrets -n saas-delta
NAME                  TYPE                                  DATA   AGE
default-token-dppr2   kubernetes.io/service-account-token   3      27h
ingress-secret        kubernetes.io/tls                     2      83m
```

### 配置 Ingress 开启 TLS

创建 secret 后，我们需要修改 ingress 的定义文件，添加 `tls` 相关内容：

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: saas-app-nginx
  namespace: saas-delta
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - saas-delta.xx.cn
    secretName: ingress-secret
  rules:
  - host: saas-delta.xx.cn
    http:
      paths:
      - path: /
        backend:
          serviceName: saas-app-nginx
          servicePort: 80
```

这里有个小问题，http 跳转到 https 官方文档上是这样写的：“By default the controller redirects HTTP clients to the HTTPS port 443 using a 308 Permanent Redirect response if TLS is enabled for that Ingress.” 大概意思就是 “默认情况下，如果为该Ingress启用了TLS，则控制器会使用308永久重定向响应将HTTP客户端重定向到HTTPS端口443。” 但是在我这个阿里云的集群上好像并不好使，需要将`nginx.ingress.kubernetes.io/ssl-redirect`设置为 `true`才可以。

修改完 ingress 配置文件后直接使用即可：

```bash
kubectl apply -f app-ingress.yaml
```

一个 Ingress 只能使用一个 secret，也就是说只能用一个证书,或者说如果你在一个 Ingress 中配置了多个域名，那么使用 TLS 的话必须保证证书支持该 Ingress 下所有域名；并且这个 secretName 一定要放在上面域名列表最后位置，否则会报错 `did not find expected key` 无法创建；同时上面的 hosts 段下域名必须跟下面的 rules 中完全匹配

Kubernetes Ingress 默认情况下，当不配置证书时，会默认提供一个 TLS 证书，也就是说你 Ingress 中配置错了，比如写了 2 个 `secretName`、或者 `hosts` 段中缺了某个域名，那么对于写了多个 `secretName` 的情况，所有域名全会走默认证书，对于 `hosts` 缺了某个域名的情况，缺失的域名将会走默认证书，部署时一定要验证一下证，更新 Ingress 证书可能需要等一段时间才会生效

### 测试

配置完成后就可以进行测试了，这里我用的是 DNS 解析的方式将 hosts 解析到了 ingress 的公网IP上：

```bash
👍 curl -I http://saas-delta.xx.cn
HTTP/1.1 308 Permanent Redirect
Date: Mon, 06 May 2019 10:49:13 GMT
Content-Type: text/html
Content-Length: 164
Connection: keep-alive
Location: https://saas-delta.xx.cn/
```

由上述结果可知该配置生效。