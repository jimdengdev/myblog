#!/bin/bash
echo "创建博客：$1";
# 默认情况下, 所有文章和页面均作为草稿创建. 如果想要渲染这些页面, 请从元数据中删除属性 draft: true, 设置属性 draft: false 或者为 hugo 命令添加 -D/--buildDrafts 参数.
# hugo new posts/$1.md;
# hugo new posts/$1.en.md;
hugo new --kind gallery content/gallery/$1.md;
hugo new --kind gallery_en content/gallery/$1.en.md;
