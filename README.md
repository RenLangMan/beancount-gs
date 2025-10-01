# beancount-gs

![license](https://img.shields.io/github/license/BaoXuebin/beancount-gs)
[![docker image size](https://img.shields.io/docker/image-size/xdbin/beancount-gs/latest?label=docker-image)](https://hub.docker.com/repository/docker/xdbin/beancount-gs/general)
[![docker pulls](https://img.shields.io/docker/pulls/xdbin/beancount-gs)](https://hub.docker.com/repository/docker/xdbin/beancount-gs/general)

[前端项目地址](https://github.com/BaoXuebin/beancount-web)
[演示地址](https://beancount.xdbin.com/)
[使用文档](https://www.yuque.com/chuyi-ble7p/beancount-gs)

## 介绍

[beancount](https://github.com/beancount/) 是一个优秀的开源复式记账工具，因为其基于文本记录的特性，难以拓展到移动端；本项目旨在将常见的记账行为封装为 RESTful API。

本仓库使用 `Golang` 进行文本的读写和接口服务支持，利用 `bean-query` 获取内容并解析，以 Json 格式返回。并基于已实现的接口内置实现了前端页面（适配移动端）。

![snapshot](./snapshot.png)

## 特性

- [X] 私有部署
- [X] 多账本
- [X] 账户，资产管理
- [X] 统计图表
- [X] 多币种
- [X] 标签
- [X] 投资管理(FIFO)
- [X] 第三方账单导入(支付宝，微信，工商银行，农业银行)
- [X] 分期记账
- [X] 事件

## API 文档

### 系统配置

- `GET /api/version` - 查询服务版本
- `POST /api/check` - 检查beancount环境
- `GET /api/config` - 查询服务器配置
- `POST /api/config` - 更新服务器配置

### 账本管理

- `GET /api/ledger` - 查询账本列表
- `POST /api/ledger` - 打开/创建账本
- `GET /api/auth/ledger/check` - 检查账本
- `DELETE /api/auth/ledger` - 删除账本

### 账户管理

- `GET /api/auth/account/valid` - 查询有效账户
- `GET /api/auth/account/all` - 查询所有账户
- `GET /api/auth/account/type` - 查询账户类型
- `POST /api/auth/account` - 添加账户
- `POST /api/auth/account/type` - 添加账户类型
- `POST /api/auth/account/close` - 关闭账户
- `POST /api/auth/account/icon` - 修改账户图标
- `POST /api/auth/account/balance` - 账户余额调整
- `POST /api/auth/account/refresh` - 刷新账户缓存

### 交易管理

- `GET /api/auth/transaction` - 查询交易记录
- `POST /api/auth/transaction` - 添加交易
- `POST /api/auth/transaction/raw` - 更新交易原始文本
- `DELETE /api/auth/transaction` - 删除交易
- `POST /api/auth/transaction/batch` - 批量添加交易
- `GET /api/auth/transaction/detail` - 查询交易详情
- `GET /api/auth/transaction/raw` - 查询交易原始文本
- `GET /api/auth/transaction/payee` - 查询交易对方列表
- `GET /api/auth/transaction/template` - 查询交易模板
- `POST /api/auth/transaction/template` - 添加交易模板
- `DELETE /api/auth/transaction/template` - 删除交易模板

### 统计分析

- `GET /api/auth/stats/months` - 查询有交易的月份列表
- `GET /api/auth/stats/total` - 统计总额
- `GET /api/auth/stats/payee` - 统计交易对方
- `GET /api/auth/stats/account/percent` - 账户占比统计
- `GET /api/auth/stats/account/trend` - 账户趋势统计
- `GET /api/auth/stats/account/balance` - 账户余额统计
- `GET /api/auth/stats/account/flow` - 账户资金流动图
- `GET /api/auth/stats/month/total` - 月度总额统计
- `GET /api/auth/stats/month/calendar` - 月度日历统计
- `GET /api/auth/stats/commodity/price` - 商品价格统计

### 文件管理

- `GET /api/auth/file/dir` - 查询账本源文件目录
- `GET /api/auth/file/content` - 查询账本源文件内容
- `POST /api/auth/file` - 更新账本源文件内容

### 数据导入

- `POST /api/auth/import/alipay` - 导入支付宝CSV
- `POST /api/auth/import/wx` - 导入微信支付CSV
- `POST /api/auth/import/icbc` - 导入工商银行CSV
- `POST /api/auth/import/abc` - 导入农业银行CSV

## 如何使用

**本地打包**

## 项目结构

```
/beancount-gs - 主程序可执行文件
/server.go - 主服务入口文件
/config - 服务器配置文件
  /config.yml - 主配置文件
/data - 账本数据存储目录
/service - 核心业务逻辑实现
  /account.go - 账户管理
  /ledger.go - 账本管理
  /transaction.go - 交易管理
  /stats.go - 统计分析
  /import.go - 数据导入
/public - 前端静态资源
  /index.html - 前端入口
  /assets - 前端资源文件
  /icons - 账户图标
/tests - 测试代码
/utils - 工具类
  /bean_query.go - beancount查询封装
  /file.go - 文件操作工具
  /log.go - 日志工具
/template - 模板文件
/script - 脚本文件
/logs - 日志文件
```

## 开发环境搭建

### 依赖环境

- Go 1.18+
- Beancount (Python 3.8+)
- Docker (可选)

### 本地开发

1. 克隆项目

   ```bash
   git clone https://github.com/your-repo/beancount-gs.git
   cd beancount-gs
   ```

2. 安装Go依赖

   ```bash
   go mod download
   ```

3. 安装Python依赖

   ```bash
   pip install -r requirements-beancount-v3.txt
   pip install -r requirements_dev.txt

   # 包含下列依赖
   beancount==3.2.0
   dateparser==1.2.2
   debugpy==1.8.16
   fava==1.30.6
   pytest==8.4.2
   Pygments==2.19.2
   pyzipper==0.3.6
   ```

4. 启动开发服务器

   ```bash
   ./start_dev.sh
   ```

### Docker开发

1. 构建镜像

   ```bash
   docker-compose build
   ```

2. 启动服务

   ```bash
   docker-compose up
   ```

### 测试运行

```bash
go test ./tests/...
```

## 测试说明

### 单元测试

运行所有单元测试：

```bash
go test -v ./tests/unit/...
```

### 集成测试

1. 确保服务已启动
2. 运行集成测试：

```bash
go test -v ./tests/integration/...
```

### 测试覆盖率

生成测试覆盖率报告：

```bash
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### 测试数据

测试数据存放在 `/tests/data` 目录下，包含：

- 示例账本文件
- 测试用CSV导入文件
- 测试用配置文件

1. 克隆本项目到本地
2. 根目录执行 `go build`
3. 执行 `./beancount-gs` (`-p` 指定端口号，`-secret` 指定配置密钥)

**release**

1. 下载并解压项目的 `release` 包
2. 执行根目录下的 `./beancount-gs.exe`

**docker**

```shell
docker run --name beancount-gs -dp 10000:80 \
-w /app \
-v "/data/beancount:/data/beancount" \
-v "/data/beancount/icons:/app/public/icons" \
-v "/data/beancount/config:/app/config" \
-v "/data/beancount/bak:/app/bak" \
xdbin/beancount-gs:latest
```

**docker-compose**

在指定目录创建文件 `docker-compose.yml`，然后复制下面内容到这个文件，执行 `docker-compose up -d`

```yaml
version: "3.9"
services:
  app:
    container_name: beancount-gs
    image: xdbin/beancount-gs:${tag:-latest}
    ports:
      - "10000:80"
    volumes:
      - "${dataPath:-/data/beancount}:/data/beancount"
      - "${dataPath:-/data/beancount}/icons:/app/public/icons"
      - "${dataPath:-/data/beancount}/config:/app/config"
      - "${dataPath:-/data/beancount}/bak:/app/bak"
      - "${dataPath:-/data/beancount}/logs:/app/logs"
```

默认的文件存储路径为 `/data/beancount`，如果你想更换其他路径，可以在当前目录下新建 `var.env`，然后将下面内容复制到这个文件

```properties
tag=latest
dataPath=自定义的目录
```

执行 `docker-compose --env-file ./var.env up -d` 即可

## 项目负责人

[@BaoXuebin](https://github.com/BaoXuebin)

## 开源协议

[MIT](https://github.com/BaoXuebin/beancount-gs/blob/main/License) @BaoXuebin

## 感谢️

[赞助地址](https://xdbin.com/sponsor)

感谢 **@Cabin**，**@潇** 两位朋友的赞助支持❤️
