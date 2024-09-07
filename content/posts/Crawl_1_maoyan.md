---
title: "爬虫项目-猫眼TOP100爬取"
date: 2024-09-07T00:55:01+08:00
lastmod: 2024-09-07T00:55:01+08:00
author: ["Jim Deng"]
summary: "猫眼爬虫"             # 简单描述，会展示在主页，可被搜索
weight:                 # 输入1可以顶置文章
draft: false            # 是否为草稿
comments: true          # 是否开启评论
showToc: true           # 显示目录
TocOpen: true           # 自动展开目录
autonumbering: true     # 目录自动编号
hidemeta: false         # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: false      # 底部不显示分享栏
searchHidden: false     # 该页面不能被搜索到
showbreadcrumbs: true   # 顶部显示当前路径
mermaid: true           # 是否开启mermaid
cover:
    image: ""           # 封面图片
    hidden: false        # 文章页面隐藏封面图片
tags:
- 爬虫
---
# 爬取猫眼TOP100榜

## 1. 爬取流程
主要有以下四步：
1. 爬取单页内容：利利⽤用requests请求⽬目标站点，得 到单个⽹网⻚页HTML代码，返回结果。 
2. 正则表达式分析：根据HTML代码分析得到电影的 名称、主演、上映时间、评分、 图⽚片链接等信息。 
3. 保存至文件：通过⽂文件的形式将结果保存，每 一部电影一个结果一行Json字符串，图片保存成jpg格式。
4. 开启循环及多线程：对多⻚页内容遍历，开启多线程提 ⾼高抓取速度。 
<!--more--> 
## 2. 具体分析

### 1. 爬取单页内容
观察到每页的页数有offset 这个变量来控制，100条数据，10页，每页10条，所以offset从0到9。以offset作为变量，先爬取单页，然后循环爬取所有页。
```py
base_url = 'https://maoyan.com'
url = 'https://maoyan.com/board/4?offset=' + str(offset)
html = get_one_page(url)

def get_one_page(url):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.text
        else:
            return None
    except RequestException:
        return None
```
爬取部分通过requests中的get方法来实现，这是基本套路。正常情况下返回200状态码，非正常情况下返回None

### 2. 正则表达式分析

```py
def parse_one_page(base_url, html):
    pattern = re.compile('<dd>.*?<i.*?board-index.*?">(\d+)</i>.*?href="(.*?)".*?data-src="(.*?)".*?data-val=.*?>(.*?)</a>.*?star">(.*?)</p>'
                         '.*?releasetime">(.*?)</p>.*?score.*?integer">(.*?)</i>.*?fraction">(.*?)</i>.*?</dd>', re.S)
    items = re.findall(pattern, html)

    for item in items:
        yield {
            'index': item[0],
            'url': base_url + item[1],
            'image': item[2],
            'title': item[3],
            'actor': item[4].strip()[3:],
            'time': item[5].strip()[5:],
            'score': item[6] + item[7]
        }

```
这部分主要是正则表达式的书写，对于学爬虫的童鞋，正则是基本功，既基础又重要，不会的自行谷歌。虽然对于网页的解析有很多中方法，比如BeautifulSoup，PyQuery等，会一些网页前端的知识就能掌握，但是别人问你学了爬虫会正则吗，你好意思说不会吗？模式串写好了，然后通过findall方法爬取所有符合模式串的字符串，并返回给items，这是一个列表。最后通过yield生成器生成一个字典返回

### 3. 保存文件

```py
def write_to_file(content):
    with open('result.txt','a', encoding='utf-8') as f:

        # 当在下面打印出来是中文汉字，而写成的文件出现编码格式则在json转换时出问题了
        f.write(json.dumps(content, ensure_ascii=False) + '\n')  # 每行字典转换成json，再加上'\n',最后写入到文件

def download_image(url):
    print('Downloading', url)
    try:
        response = requests.get(url)
        if response.status_code == 200:
            save_image(response.content)
        return None
    except ConnectionError:
        return None

def save_image(content):
    file_path = '{0}/{1}.{2}'.format(os.getcwd() + r'/images/', md5(content).hexdigest(), 'jpg')
    print(file_path)
    if not os.path.exists(file_path):
        with open(file_path, 'wb') as f:
            f.write(content)
            f.close()

```
这部分其实是很简单，非常套路，不过要注意的是文件的编码问题，中文编码要用'utf-8'，当让还有其他编码，源码中可以找到。

### 4. 开启循环及多线程

```py
pool = Pool()
pool.map(main, [i*10 for i in range(10)])
```
就是开一进程池，然后用调用map方法，写上循环次数搞定。

```py
import requests
from requests.exceptions import RequestException
import re
import json
from multiprocessing import Pool  # 通过进程池实现多进程抓取
import os
from hashlib import md5


def get_one_page(url):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.text
        else:
            return None
    except RequestException:
        return None

def parse_one_page(base_url, html):
    pattern = re.compile('<dd>.*?<i.*?board-index.*?">(\d+)</i>.*?href="(.*?)".*?data-src="(.*?)".*?data-val=.*?>(.*?)</a>.*?star">(.*?)</p>'
                         '.*?releasetime">(.*?)</p>.*?score.*?integer">(.*?)</i>.*?fraction">(.*?)</i>.*?</dd>', re.S)
    items = re.findall(pattern, html)

    for item in items:
        yield {
            'index': item[0],
            'url': base_url + item[1],
            'image': item[2],
            'title': item[3],
            'actor': item[4].strip()[3:],
            'time': item[5].strip()[5:],
            'score': item[6] + item[7]
        }

def write_to_file(content):
    with open('result.txt','a', encoding='utf-8') as f:

        # 当在下面打印出来是中文汉字，而写成的文件出现编码格式则在json转换时出问题了
        f.write(json.dumps(content, ensure_ascii=False) + '\n')  # 每行字典转换成json，再加上'\n',最后写入到文件

def download_image(url):
    print('Downloading', url)
    try:
        response = requests.get(url)
        if response.status_code == 200:
            save_image(response.content)
        return None
    except ConnectionError:
        return None


def save_image(content):
    file_path = '{0}/{1}.{2}'.format(os.getcwd() + r'/images/', md5(content).hexdigest(), 'jpg')
    print(file_path)
    if not os.path.exists(file_path):
        with open(file_path, 'wb') as f:
            f.write(content)
            f.close()


def main(offset):
    base_url = 'https://maoyan.com'
    url = 'https://maoyan.com/board/4?offset=' + str(offset)
    html = get_one_page(url)
    # print(html)
    for item in parse_one_page(base_url, html):
        print(item)
        write_to_file(item)
        download_image(item['image'])


if __name__ == '__main__':
    # for i in range(10):
    #     main(i*10)

    # 先构造一个进程池，然后使用map方法，让进程进入进程池
    pool = Pool()
    pool.map(main, [i*10 for i in range(10)])
```