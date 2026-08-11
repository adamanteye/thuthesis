# ThuThesis Typst 模板

这是与 ThuThesis LaTeX 模板并列维护的 Typst 实现，目前要求 Typst 0.15.1 或更新版本。模板自身没有第三方 Typst 包依赖；定理、术语管理和伪代码包由论文作者按需导入。

实现以仓库中的 `rule.md` 和 ThuThesis v7.7.1 为规范来源，分别建模 `bp` 与 TeX `pt`，并覆盖封面、分页、页眉页脚、章节、目录、图表公式、脚注和前后置页面的模式分支。

## 快速开始

在本仓库中直接编译示例：

```shell
make typst
```

输出位于 `build/typst/thuthesis-example.pdf`。示例入口是 `thuthesis-example.typ`，其配置、章节顺序和演示内容与 `thuthesis-example.tex` 逐项对应；正文内容放在同名的 `data/*.typ` 文件中。

运行完整组合测试：

```shell
make typst-test
```

其中包含 LaTeX/Typst 坐标回归测试；也可以单独运行 `make layout-test`。
测试按 ThuThesis `master` 分支在 TeX Live/Linux 下的 Fandol profile，使用
TeX Gyre Termes、TeX Gyre Heros、Fandol 和 XITS Math 编译两份同内容文档，
比较实际嵌入字体、页码、语义锚点坐标、字框尺寸及 20bp 基线，并拒绝已知
的 PDF 坐标拟合常量重新进入模板。

发布到 Typst Universe 后，可以使用：

```shell
typst init @preview/thuthesis:0.1.0 my-thesis
```

## 基本配置

```typst
#import "lib.typ" as thu

#let thesis = thu.thuthesis(
  degree: "master",
  degree-type: "academic",
  language: "chinese",
  output: "electronic",
  thesis-type: "thesis",
  style-override: "none",
  font-profile: "auto",
  info: (
    title: [中文标题],
    title-en: [English Title],
    degree-category: [工学硕士],
    degree-category-en: [Master of Science],
    department: [院系名称],
    discipline: [学科名称],
    discipline-en: [Discipline],
    author: [作者姓名],
    author-en: [Author Name],
    supervisor: (name: [导师姓名], title: [教授]),
    supervisor-en: (name: [Supervisor Name], title: [Professor]),
    date: datetime(year: 2026, month: 8, day: 8),
  ),
)

#show: thesis.document
```

包顶层只公开 `thuthesis`。论文组件都由 `thuthesis(...)` 返回的实例提供，并捕获该实例已经校验、归一化的配置。

配置选项：

- `degree`：`bachelor`、`master`、`doctor` 或 `postdoc`。
- `degree-type`：`academic` 或 `professional`。
- `language`：`chinese` 或 `english`。
- `output`：`print` 会插入双面打印需要的空白页，`electronic` 不插入。
- `thesis-type`：`thesis` 或 `proposal`；研究生开题报告必须提供 `student-id`。
- `style-override`：`none` 或 `schwarzman`；苏世民格式使用全局脚注、图表和公式编号。
- `font-profile`：字体 profile 字典，或预设名 `"auto"`、`"windows"`、`"mac"`、`"ubuntu"`、`"fandol"`、`"linux"`。终稿建议使用预设名 `"windows"`。
- `include-spine`：是否在封面后加入书脊页。
- `bibliography-style`：`auto`、`numeric`、`author-year` 或 `bachelor`。
- `open-right`：是否让普通章从右页开始，默认 `false`，对应 LaTeX 的 `openany`。

字体 profile 包含 `serif`、`sans`、`mono`、`fangsong`、`kaiti` 和 `math` 六个语义角色，每项可以是单个字体名或字体回退数组。用户可以直接传入自定义字典，例如：

```typst
#let my-fonts = (
  serif: ("Times New Roman", "SimSun", "KaiTi"),
  sans: ("Arial", "SimHei"),
  mono: ("Courier New", "FangSong"),
  fangsong: ("Times New Roman", "FangSong"),
  kaiti: ("Times New Roman", "KaiTi"),
  math: "XITS Math",
)

#let thesis = thu.thuthesis(font-profile: my-fonts, /* 其他配置 */)
#show: thesis.document
```

Typst 不能像 LaTeX 一样检测整套平台字体是否齐全，因此
`"auto"` 确定性地指向 TeX Live 的 Fandol profile；Windows、macOS
和 Ubuntu 用户可以显式选择对应预设。选定 profile 后模板不会静默使用系统
字体补缺，避免 PDF 意外嵌入 profile 之外的字体。

- `ragged-bottom`：当前支持规范默认值 `true`；Typst 暂无与 TeX `flushbottom` 完全等价的全局页面拉伸机制。
- `eqn-paren-style`：`auto`、`full` 或 `half`；中文默认使用全角公式括号，英文始终使用半角括号。
- `footnote-numbering`：`page`、`chapter` 或 `global`；默认按页编号。
- `footnote-style`：`circled` 或 `plain`；默认使用带圈数字。
- `figure-numbering`、`table-numbering`、`equation-numbering`：`chapter` 或 `global`。
- `number-separator`：图、表、公式共用的章号连接符，默认 `.`；三类连接符也可以分别覆盖。
- `appendix-figure-in-list`：是否将附录图表写入清单，默认 `false`。
- `spine-title`、`spine-author`、`spine-font`：书脊覆盖项；本科书脊启用时必须显式给出 `spine-font`。

专业学位使用 `professional-field` 和 `professional-field-en`；旧版工程硕士还可提供 `engineering-field`。博士后报告另外使用 `clc`、`udc`、`id`、`discipline-level-1`、`discipline-level-2`、`start-date` 和 `end-date`。`date` 为所有类型的必填完整日期；博士后起止日期也必须完整且起始日期不得晚于结束日期。导师、副导师和联合导师的中英文字段统一使用 `(name: ..., title: ...)` 字典，`title` 没有内容时写作 `none`。

简单文本标题和作者会自动写入 PDF 元数据。标题含复杂排版时，可用字符串形式的 `metadata-title` 和 `metadata-author` 单独指定元数据。

## 文档结构

```typst
#(thesis.frontmatter)[
  #(thesis.abstract-zh)(keywords: ([关键词一], [关键词二]))[中文摘要。]
  #(thesis.abstract-en)(keywords: ([keyword one], [keyword two]))[English abstract.]
  #(thesis.table-of-contents)()
]

#(thesis.mainmatter)[
  = 第一章
  正文。
]

#(thesis.appendix)[
  = 附录标题
  附录正文。
]

#(thesis.backmatter)[
  #(thesis.acknowledgements)[致谢内容。]
  #(thesis.statement)()
]
```

Typst 0.15 的字典字段若保存函数，调用时必须写为 `#(thesis.frontmatter)[...]` 或 `#(thesis.statement)()`；不能省略字段访问外侧的括号。

`frontmatter` 使用大写罗马页码，`mainmatter` 重置为阿拉伯页码，`appendix` 使用字母章号，`backmatter` 延续正文页码。

## 论文组件

- `committee`：指导小组、评阅人和答辩委员会名单，支持用 `file` 直接替换为扫描 PDF（文件模式仍以空内容块 `[]` 结尾）。
- `authorization`：论文使用授权页，支持 `file` 替换为扫描 PDF。
- `table-of-contents`、`list-of-figures`、`list-of-tables`、`list-of-figures-and-tables`、`list-of-algorithms`、`list-of-equations`。
- `denotation`：接收 `(符号, 说明)` 数组，不依赖术语包。
- `resume`、`achievements`、`comments`、`resolution`、`statement`。
- `scanned-pages`：插入 PDF 页面；`record` 是本科综合论文训练记录表的便捷接口。
- `algorithm-figure`：为任意用户提供的伪代码内容增加算法题注和编号。
- `survey`、`translation`、`translation-index`：保留的本科兼容接口。

扫描文件应先在调用文件中读取，以避免包路径歧义：

```typst
#(thesis.statement)(
  file: read("figures/scan-statement.pdf", encoding: none),
  page-style: "plain",
)
```

## 参考文献

模板使用 Typst 内建的 BibLaTeX 和 CSL 支持，不依赖第三方包：

```typst
文献引用示例 @key。

#(thesis.bibliography-thu)(
  read("refs.bib", encoding: none),
  style: "numeric",
  title: auto,
)
```

`numeric` 和 `bachelor` 当前使用 Typst 内建 GB/T 7714—2015 顺序编码样式，`author-year` 使用其著者—出版年样式。`title` 默认按论文语言和类型生成，也可传入自定义标题。

## 引擎差异

- Typst 的 `pt` 是 `1/72in`，物理上等于 TeX 的 `bp`；模板对 LaTeX 源码中真正的 TeX `pt` 单独换算。
- LaTeX `\fontsize{字号}{行距}` 的第二个参数是基线距离，而 Typst 的 `par.leading` 是两个文本框之间的净空；模板固定文本框上下边界后再用“基线距离减字号”换算，正文因此是精确的 12bp / 20bp。
- 中文正文使用 Typst 的简体中文语言与标点断行规则。字体由宋体、黑体、仿宋、楷体等语义族映射；终稿仍应选择安装了学校要求字体的环境。
- Typst 尚不能全局复刻 LaTeX `unicode-math` 的 GB/ISO/TeX 数学字形开关，也不能表达 TeX 浮动胶的 `plus`/`minus` 伸缩量。模板已复刻明确的公式括号、编号与固定间距，数学字形和极端浮动页仍可能存在引擎级差异。

## 可选生态包

模板不会自动导入定理、术语或伪代码包。用户可以在自己的文档中导入任意兼容包，并把生成的内容放入正常正文或 `algorithm-figure`：

```typst
#import "@preview/lovelace:0.3.1": pseudocode-list

#(thesis.algorithm-figure)(caption: [快速排序])[
  #pseudocode-list[
    + *Input:* array
    + *Output:* sorted array
  ]
]
```

第三方包的版本和配置由论文项目自行管理，不属于 thuthesis 的运行时依赖或公共 API。

## 测试

`make typst-test` 会编译最小论文、组件测试、本科中英文、研究生中英文、专业型论文与开题报告、两种参考文献样式、博士打印版、苏世民格式、博士后报告及包模板；同时检查错误配置会失败，并验证所有输出均为 A4。
