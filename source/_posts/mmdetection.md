---
uuid: f9ebbe00-d1cd-11ec-8c1a-6f2de37cae84
title: mmdetection
date: 2022-05-12 16:31:53
tags: pytorch
---

总结一些mmdetection 中常用代码及学习技巧

1. 外部引用保持代码结构整洁

在mmdetection中的config可以直接引用自定义文件夹中的代码，因此可以做到代码重用，保持目录的整洁。当前github上复用mmdetection代码开发实现的相关代码仓库中大多引用了不必要的代码，因此考虑从结构上简化。其中 *allow_failed_imports=False* 会在impoort的文件不存在的时候throw error。

{% codeblock mmdetection/config/solo.py lang:python line_number:false %}
custom_imports = dict(
    imports=[
        "custommd.models.detectors.single_stage_ins",
        "custommd.models.detectors.solov2",
        "custommd.models.solov2.mask_feat_head",
        "custommd.models.solov2.solov2_head",
    ],
    allow_failed_imports=False)
{% endcodeblock %}

2. 使用Wandb监控实验

mmdetection框架中的wandb日志实现策略在[github](https://github.com/open-mmlab/mmcv/blob/83df7c4b00197b40c3debdb7f388a256640e13b4/mmcv/runner/hooks/logger/wandb.py)中能够找到,关于wandb的初始化参数可以参考[这里](https://docs.wandb.ai/ref/python/init), 配置文件中可以在*wandb_init_kwargs*中定义wandb的初始化参数。
{% codeblock mmdetection/config/model_config.py lang:python line_number:false %}
import wandb

...

log_config = dict(
            interval=10,
            hooks=[
                dict(type='WandbLogger',
                     wandb_init_kwargs={
                         'entity': WANDB_ENTITY,
                         'project': WANDB_PROJECT_NAME
                     },
                     logging_interval=10,
                     log_checkpoint=True,
                     log_checkpoint_metadata=True,
                     num_eval_images=100)
            ])
{% endcodeblock %}

3. 使用timm中预训练的backbone

mmdetection 中可以使用部分timm模型作为特征提取器，但是使用有所限制。使用timm库中的特征提取器需要指定使用的backbone类型。TIMMBackbone类型的具体定义在*mmcls.models*中。有两种方式可以实现，第一种是安装mmcls包后，使用其对TIMMBackbone的定义方式，显示的在config中的backbone部分制定，另一部分则是将[basebackbone.py](https://raw.githubusercontent.com/open-mmlab/mmclassification/master/mmcls/models/backbones/base_backbone.py)文件和[timm_backbone.py](https://github.com/open-mmlab/mmclassification/blob/master/mmcls/models/backbones/timm_backbone.py)稍作修改，主要是对其中的get_root_logger()函数修改为修改为`from mmdet.utils import get_root_logger`,通过这两种引用方式可以实现在mmdetection中使用timm库中的预训练模型。默认情况下不使用预训练的权重，需要显式指定。支持更改权重所在的位置，可以使用在image21-k上预训练的模型权重。具体代码如下：

{% codeblock mmdetection/config/model_config.py lang:python line_number:false %}
custom_imports = dict(imports=['mmcls.models'], allow_failed_imports=False)
"""
custom_imports = dict(imports=[
    'mmdet.model.backbone.timm_backbone'
    ], allow_failed_imports=False)
"""


model = dict(
    backbone=dict(
        _delete_=True,
        type='mmcls.TIMMBackbone',
        model_name='tv_resnet50',  # ResNet-50 with torchvision weights
        features_only=True,
        pretrained=True,
        checkpoint_path='',
        out_indices=(1, 2, 3, 4)))
{% endcodeblock %}
