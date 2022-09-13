---
uuid: 88501be0-3313-11ed-89cc-1381c123a077
title: kaggle top player notes
date: 2022-09-13 11:24:10
tags:
mathjax: true
---
记录一些kaggle top player 的笔记
## [Dieter](https://www.kaggle.com/christofhenkel): Deep Learning Data Scientist at Nvidia
1. Ensemble, bag of models
Dieter 使用了7个模型，集合albumentations的图像放缩
    - 2x seresnext101 - SmallMaxSize(512) -> RandomCrop(448,448)
    - 1x seresnext101 - Resize(686,686) -> RandomCrop(568,568)
    - 1x b3 - LongestMaxSize(512) -> PadIfNeeded -> RandomCrop(448,448)
    - 1x b3 - LongestMaxSize(664) -> PadIfNeeded -> RandomCrop(600,600)
    - 1x resnet152 - Resize(544,672) -> RandomCrop(512,512)
    - 1x res2net101 - Resize(544,672) -> RandomCrop(512,512)
2. 使用imagenet dataset的 mean 和 std 正则化输入图像
3. 使用了GeM pooling
GeM pooling 中包含一个网络参数p，随着学习过程使得网络自适应学习选择偏重平均池化或是最大池化，p=1时gem为平均池化, $p \rightarrow + \infty$ 时为最大池化，P越大越关注局部越小越关注全局
    - 最大池化更多的保留的纹理特征，局部特征。
    - 平均池化更多保留的背景信息，全局特征。
4. 学习率： warmup + cosine annealing scheduler 