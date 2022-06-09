---
uuid: 137500a0-d5b3-11ec-8fdb-3db4a824d9de
title: reveal-md
date: 2022-05-17 15:29:24
tags: ppt
toc: true
---

*Reveal-md*经常用于组会汇报和一些非正式场景的PPT实现中，生成的PPT或是展示用结果由markdown组成，并且具有默认的布局样式和一些功能丰富的插件，大大简化了生成汇报用PPT的工作量。

其主要格式控制由两部分组成，一部分是构成其内容主体的markdown文件，另一部分是控制页面布局的css文件（一般不需要修改）。其渲染引擎使用的是*reveal.js*，通常情况下不需要对*reveal.js*进行修改（甚至基本的配置都不需要更改）。创作PPT的过程简化为了专注于内容，构建讲述逻辑，简而言之就是填充需要的内容即可。这里不过多介绍，可[参考这里](https://github.com/webpro/reveal-md)了解更多。这篇笔记的主要内容是对一些疑难问题的记录。

1. 样式控制
**Reveal-md**中的全局样式需要在命令行中指定样式文件和使用的主题，样式文件需要指定其具体位置，运行时可以使用 **--css** 和 **--theme** 指定。**-w** 表示监听文件变化，并随时刷新内容。
{% codeblock run_file lang:bash line_number:false %}
reveal-md ppt.md -w --theme simple --css styles/base.css
{% endcodeblock %}

- 字体控制
通常情况下，PPT中的中文字体使用<font face="Microsoft Yahei">**微软雅黑**</font>，英文字体使用<font face="Times New Roman">**Times NewRoman**</font>, 在**Reveal-md**中，字体样式可以由全局的样式文件控制，这里只给出一些基本的样式定义。通过对html中所有元素的字体进行设置，可以得到全局的样式文件，同时，由于添加了 **!important**，其样式不会被后续的设置覆盖。同样这种方式可以设置PPT中的默认字体大小。**reveal-md**中的默认字体对我来说有点太大了。
{% codeblock style/style.css lang:css line_number:false %}
html * {
    font-family: "Times New Roman", Times, "Microsoft Yahei" !important;
}
{% endcodeblock %}

reveal 中预定义了几种字体大小，可以根据实际需求进行修改

{% codeblock ppt.md lang:html line_number:false %}
font-size:medium|xx-small|x-small|small|large|x-large|xx-large|smaller|larger|length|initial|inherit;

<p style="font-size:xx-small">
{% endcodeblock %}

2. 图像或内容居中设置
这里有两种方式，一种是全局的图像或者文字进行样式设置进行居中，另一种是创建独立的div块，对块中的内容进行居中，这里使用css优先级可以对其中的元素进行单独更新，首先在全局文件中默认左对齐，之后根据实际需求在markdown文件中再对需要的部分进行修改即可。在**Reveal-md**中，单独的文字或段落会被渲染成<p></p>标签的形式，因此只需要对其样式进行修改即可。
{% codeblock style/style.css lang:css line_number:false %}
p.left {
    text-align: left;
    width: 100%;
}
{% endcodeblock %}
关于其他元素的居中设置，可以设置一个居中的div块，对块中的内容进行居中即可。实现方式如下：
{% codeblock style/style.css lang:css line_number:false %}
.center-div {
    text-align: center;
    /*让div内部文字居中*/
    width: 700px;
    height: 200px;
    margin: auto;
}
{% endcodeblock %}