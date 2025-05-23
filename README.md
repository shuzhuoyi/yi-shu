# 模板 App

## 项目简介

0基础，使用ai开发一款影视app模板，写的很乱，望大家不喷。

## 功能特点

- **视频分类浏览**：按不同艺术类别组织视频内容
- **推荐系统**：基于用户兴趣智能推荐相关视频
- **搜索功能**：快速查找感兴趣的艺术内容
- **用户中心**：个人收藏、观看历史记录
- **离线观看**：支持视频下载功能
- **社区互动**：用户评论和分享功能

## 技术栈

- **前端框架**：Flutter
- **编程语言**：Dart
- **状态管理**：Provider
- **平台支持**：iOS 和 Android

## 安装和使用

1. 确保已安装Flutter环境
2. 克隆本仓库：`git clone https://github.com/shuzhuoyi/yi-shu.git`
3. 进入项目目录：`cd yi-shu/iaapp`
4. 安装依赖：`flutter pub get`
5. 运行项目：`flutter run`

### 安装包下载

- **iOS**: 
  - [下载iOS安装包(IPA)](https://github.com/shuzhuoyi/yi-shu/raw/main/iaapp/build-packages/AppRelease-iOS.ipa) (需要自行签名后安装)
  - [下载iOS安装包(ZIP)](https://github.com/shuzhuoyi/yi-shu/raw/main/iaapp/build-packages/AppRelease-iOS.zip) (备用下载)
- **Android**: 暂未提供，需要在本地构建

## 项目结构

- **lib/screens/**: 应用的各个页面
- **lib/widgets/**: 可复用的UI组件
- **lib/models/**: 数据模型
- **lib/providers/**: 状态管理
- **lib/services/**: API服务和其他服务
- **lib/constants/**: 常量定义

## 截图展示

### 首页
首页提供分类导航和热门推荐内容，包括电影、连续剧、综艺和动漫等多种类别。用户可以通过顶部的搜索框快速查找内容。

![首页截图](https://raw.githubusercontent.com/shuzhuoyi/yi-shu/main/iaapp/screenshots/home.jpg)

### 视频详情页
视频详情页展示了影片的基本信息、播放源选择和剧集选择。用户可以收藏、分享或下载视频，还可以查看相关推荐。

![详情页截图](https://raw.githubusercontent.com/shuzhuoyi/yi-shu/main/iaapp/screenshots/detail.jpg)

### 排行榜
排行榜页面展示了热播榜、电影榜、剧集榜和综艺榜等多种分类的排名，帮助用户发现热门内容。

![排行榜截图](https://raw.githubusercontent.com/shuzhuoyi/yi-shu/main/iaapp/screenshots/ranking.jpg)

### 用户中心
用户中心包含观看历史、收藏内容、下载管理等功能，还提供应用分享、清理缓存和设置等选项。

![用户中心截图](https://raw.githubusercontent.com/shuzhuoyi/yi-shu/main/iaapp/screenshots/profile.jpg)

## 贡献指南

欢迎对项目进行贡献！如有问题或建议，请提交issue或pull request。

## 联系方式

如有任何问题，请联系项目维护者。

## 免责声明

图片如有侵权的内容，请联系zhong1231212@163.com，我会在24小时内删除！

## 许可证

本项目采用MIT许可证。 