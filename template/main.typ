#import "@preview/thuthesis:0.1.0" as thu

#let thesis = thu.thuthesis(
  degree: "master",
  degree-type: "academic",
  language: "chinese",
  output: "electronic",
  info: (
    title: [清华大学学位论文 Typst 模板使用示例],
    title-en: [An Introduction to the Typst Thesis Template of Tsinghua
      University],
    metadata-title: "清华大学学位论文 Typst 模板使用示例",
    degree-category: [工学硕士],
    degree-category-en: [Master of Science],
    department: [计算机科学与技术系],
    discipline: [计算机科学与技术],
    discipline-en: [Computer Science and Technology],
    author: [示例作者],
    author-en: [Example Author],
    supervisor: (name: [示例导师], title: [教授]),
    supervisor-en: (name: [Example Supervisor], title: [Professor]),
    associate-supervisor: (name: [示例副导师], title: [副教授]),
    associate-supervisor-en: (name: [Example Associate], title: [Associate Professor]),
    date: datetime(year: 2026, month: 8, day: 8),
  ),
)

#show: thesis.document

#let subheading(title) = heading(level: 2, numbering: none, outlined: false, title)
#let roster(title, columns, cells) = [
  #subheading(title)
  #align(center, table(columns: columns, align: center, stroke: none, ..cells))
]

#(thesis.committee)[
  #roster([指导小组名单], (3cm, 3cm, 1fr), ([张某], [教授], [清华大学]))
  #roster([公开评阅人名单], (3cm, 3cm, 1fr), ([李某], [教授], [某大学]))
  #roster([答辩委员会名单], (2cm, 3cm, 3cm, 1fr), (
    [主席], [王某], [教授], [清华大学],
    [委员], [李某], [教授], [某大学],
    [秘书], [赵某], [助理研究员], [清华大学],
  ))
]

#(thesis.authorization)()

#(thesis.frontmatter)[
  #(thesis.abstract-zh)(
    keywords: ([Typst], [学位论文], [清华大学]),
  )[
    本文展示 thuthesis Typst
    模板的基本用法。模板负责封面、页面、标题、目录、图表和参考文献等学校规定的论文版式。
  ]

  #(thesis.abstract-en)(
    keywords: ([Typst], [thesis], [Tsinghua University]),
  )[
    This document demonstrates the basic usage of the thuthesis template for
    Typst.
  ]

  #(thesis.table-of-contents)()
  #(thesis.list-of-figures-and-tables)()
  #(thesis.denotation)(((
    [AI], [人工智能],
  ), (
    $E$, [能量],
  )))
]

#(thesis.mainmatter)[
  #include "content/chapter.typ"

  #(thesis.bibliography-thu)(read("refs.bib", encoding: none))
]

#(thesis.appendix)[
  = 补充材料

  这里是附录内容。

  // 若附录中有引用，可在这里生成独立编号的参考文献表：
  // #(thesis.bibliography-thu)(read("refs.bib", encoding: none), group: none)
]

#(thesis.backmatter)[
  #(thesis.acknowledgements)[
    感谢所有为本文提供帮助的人。
  ]

  #(thesis.statement)()

  #(thesis.resume)[
    #subheading([个人简历])
    示例作者，2026 年于清华大学攻读硕士学位。

    #subheading([在学期间完成的相关学术成果])
    #(thesis.achievements)(([示例作者. 示例论文题目[J]. 示例期刊, 2026.],))
  ]

  #(thesis.comments)[指导教师评语。]
  #(thesis.resolution)[答辩委员会决议。]
]
