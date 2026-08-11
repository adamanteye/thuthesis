#import "../lib.typ" as thu

#let degree = sys.inputs.at("degree")
#let language = sys.inputs.at("language")
#let output = sys.inputs.at("output")
#let degree-type = sys.inputs.at("degree-type")
#let thesis-type = sys.inputs.at("thesis-type")
#let style-override = sys.inputs.at("style-override")

#let thesis = thu.thuthesis(
  degree: degree,
  language: language,
  output: output,
  degree-type: degree-type,
  thesis-type: thesis-type,
  style-override: style-override,
  font-profile: "fandol",
  info: (
    title: [论文模板视觉对比],
    title-en: [Visual Comparison of Thesis Templates],
    degree-category: [工学学位],
    degree-category-en: [Degree of Engineering],
    department: [计算机科学与技术系],
    discipline: [计算机科学与技术],
    discipline-en: [Computer Science and Technology],
    professional-field: [计算机技术],
    professional-field-en: [Computer Technology],
    author: [测试作者],
    author-en: [Test Author],
    student-id: [2026000000],
    supervisor: (name: [测试导师], title: [教授]),
    supervisor-en: (name: [Test Supervisor], title: [Professor]),
    date: datetime(year: 2026, month: 8, day: 8),
    clc: [TP3],
    udc: [004],
    id: [2026-01],
    discipline-level-1: [计算机科学与技术],
    discipline-level-2: [计算机系统结构],
    start-date: datetime(year: 2024, month: 8, day: 1),
    end-date: datetime(year: 2026, month: 7, day: 31),
  ),
)

#show: thesis.document

#(thesis.frontmatter)[
  #(thesis.abstract-zh)(keywords: ([模板], [对比]))[
    本文用于比较 LaTeX 与 Typst 模板在不同论文配置下的版式。
  ]
  #(thesis.abstract-en)(keywords: ([template], [comparison]))[
    This document compares the LaTeX and Typst layouts under different thesis configurations.
  ]
  #(thesis.table-of-contents)()
]

#(thesis.mainmatter)[
  = 比较章节

  这是用于检查正文、页眉、页码和章节编号的示例文字。

  == 图表与公式

  #figure(rect(width: 3cm, height: 1cm), caption: [示例图])

  $ E = m c^2 $
]

#(thesis.appendix)[
  = 附录测试

  这是用于检查附录编号和页眉的示例文字。
]
