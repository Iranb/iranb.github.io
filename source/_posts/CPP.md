---
uuid: 9a235830-3da1-11ed-988a-b737c2931d1a
title: C++ Guide
date: 2022-09-26 21:46:20
tags:
---
1. CMakeLists.txt
包含**CMak**命令
    - minimum version `cmake_minimum_required(VERSION 3.5)`
    - 指定项目名称 `project (hello_cmake)`
    - 指定输出二进制文件对应的c++文件`add_executable(hello_cmake main.cpp)`
可以通过环境变量`CMAKE_BINARY_DIR`设置二进制文件的输出位置
    - 执行`cmake .`或 `cmake ..` 命令会自动寻找路径下的CmakeLists.txt 文件，并执行其中的内容
    - 执行 `make` 可以输出二进制文件，且可以指定参数如`make VERBOSE=1`会进入debug模式，终端会输出更多细节。
    - 引入外部的 include 文件夹, 
        - *PRIVATE* 表示文件夹会被加入到targets对应的include文件夹下
        - *INTERFACE* 表示目录会被添加到任意引用这个文件的include 文件夹内部
        - *PUBLIC* 会同时包括*PRIVATE*和*INTERFACE*的功能，同时任意的target也可以链接到这个库内
```
target_include_directories(target
    PRIVATE
        ${PROJECT_SOURCE_DIR}/include
)
```

    - `.a`文件表示静态库文件，由以下函数生成

```
add_library(hello_library STATIC
    src/Hello.cpp
)
```











## 0XFF Reference
【1】https://github.com/ttroy50/cmake-examples