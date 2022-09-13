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

4. 自定义**Pipeline**
mmdetection中Pipeline决定了数据加载到送入模型前的数据处理过程，同时，Pipeline本身具有一定的灵活性，这里推荐结合 [albumentations](https://github.com/albumentations-team/albumentations) 进行数据预处理，包含对bbox 的处理过程，保证增强后的图片和标签的一致性。各种增强方法图像变换前后的对比可以[参考这里](https://albumentations-demo.herokuapp.com/)
{% codeblock mmdetection/custom_models/albumentations.py lang:python line_number:false %}
import random
from mmcls.datasets import PIPELINES
import albumentations as A

@PIPELINES.register_module()
class RandomAlbumentationsV2(object):
    def __init__(self, p=0.6) -> None:
        self.p = p
        self.transform = A.Compose([
            A.RandomGridShuffle(always_apply=False, p=self.p, grid=(2, 2)),
            A.CoarseDropout(
                always_apply=False, p=1,
                max_holes=16,
                max_height=8,
                max_width=8,
            ),
            A.Downscale(
                always_apply=False, p=self.p,
                scale_min=0.25, scale_max=0.25, interpolation=0
            ),

            A.ISONoise(
                always_apply=False, p=0.9,
                intensity=(0.0, 0.5),
                color_shift=(0.0, 0.5),
            ),
             A.JpegCompression(
                always_apply=False, p=self.p,
                quality_lower=80,
                quality_upper=100
            ),
            A.MotionBlur(
                always_apply=False, p=self.p, 
                blur_limit=(3, 10),
            ),
            A.MultiplicativeNoise(
                always_apply=False, p=1.0, multiplier=(0.1, 2.0),
                per_channel=True,
                elementwise=True
            )

        ])
    def __call__(self, results):
        img = results['img']
        transformed = self.transform(image=img)
        results['img'] = transformed["image"]
        return results

{% endcodeblock %}
Pipeline 定义完成后，在config相应数据处理config片段中加入定义好的预处理方法即可
{% codeblock mmdetection/config/custom_config.py lang:python line_number:false %}
train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='Resize',size=224),
    dict(type='RandomAlbumentationsV2'), # 这里为自定义pipeline的名称，可在dict内添加对应的参数
    dict(type='RandomNoise'),
    dict(type='RandomFlip'),
    dict(type='Normalize', **img_norm_cfg),
    dict(type='ImageToTensor', keys=['img']),
    dict(type='ToTensor', keys=['gt_label']),
    dict(type='Collect', keys=['img', 'gt_label'])
]
{% endcodeblock %}

5. 自动保存最好的ckpt文件
mmdetection中在evaluation epoch中可按照相应的结果保存相应指标最好的权重文件，且可设置训练多少epoch时开始保存。其自带的权重保存机制支持限制保存文件的最大数量。对应代码如下：
{% codeblock mmdetection/config/custom_config.py lang:python line_number:false %}
checkpoint_config = dict(interval=50, max_keep_ckpts=2) # 每50 epoch 保存一次，保存目录中最多存在两个权重文件，evaluation生成文件不包含在限制内
evaluation = dict(       # evaluation hook 的配置
    interval=4,          # 验证期间的间隔，单位为 epoch 或者 iter， 取决于 runner 类型。
    metric='accuracy',
    save_best='auto',
    start=50
    )   # 验证期间使用的指标。
{% endcodeblock %}

6. 梯度累计
训练真实使用的batchsize为 samples_per_gpu * cumulative_iters，此项设置会影响模型训练的流程，最好不使用。
{% codeblock mmdetection/config/custom_config.py lang:python line_number:false %}
optimizer_config = dict(
    type="GradientCumulativeOptimizerHook", # 累积倍数
    cumulative_iters=4,
)
data =dict(
    samples_per_gpu=64, # 基础batchsize
）
{% endcodeblock %}

7. 学习率调节和可视化
mmdetection中有几种内置的学习速率调节策略，基本通用型为使用CosineAnnealing且随epoch不断变化的学习速率设置。如下代码，target_ratio决定了最大和最小两次的学习率倍数，这里设置学习率随着epoch不断变化。
{% codeblock mmdetection/config/custom_config.py lang:python line_number:false %}
lr_config = dict(
    policy='cyclic',
    target_ratio= (2e3, 1e-2), # 决定了最大学习率倍数，实际最大值为 target_ratio[0] * lr
    cyclic_times= 5, # 训练开始到训练结束共调整五次
    step_ratio_up= 0.4, # real lr = warmup_ratio * initial lr
)

optimizer = dict(
    type='AdamW',
    lr=5e-4 * 128 * 4 / 512 * 1e-4, # 决定了 baselr
    weight_decay=0.0001,
    eps=1e-8,
    betas=(0.9, 0.999),)
{% endcodeblock %}
mmdetection中自带学习率可视化工具，可以根据config文件对学习率可视化，方便调整。
{% codeblock mmdetection/config/custom_config.py lang:bash line_number:false %}
# python tools/visualizations/vis_lr.py [config_path] --save-path [output_path]
{% endcodeblock %}
