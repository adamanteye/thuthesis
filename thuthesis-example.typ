#import "data/config.typ": thesis

#show: thesis.document

// 学位论文指导小组、公开评阅人和答辩委员会名单。
#include "data/committee.typ"

// 使用授权说明。签字扫描件可改为：
// #(thesis.authorization)(file: read("figures/scan-copyright.pdf", encoding: none))
#(thesis.authorization)()

#(thesis.frontmatter)[
  #include "data/abstract.typ"

  #(thesis.table-of-contents)()

  #(thesis.list-of-figures)()
  #(thesis.list-of-tables)()
  // 也可以用 #(thesis.list-of-figures-and-tables)() 生成合并清单。

  #include "data/denotation.typ"
]

#(thesis.mainmatter)[
  #include "data/chap01.typ"
  #include "data/chap02.typ"
  #include "data/chap03.typ"
  #include "data/chap04.typ"

  #(thesis.bibliography-thu)(
    read("ref/refs.bib", encoding: none),
    full: true,
  )
]

#(thesis.appendix)[
  #include "data/appendix.typ"

  // 附录引用由最近的这份参考文献表收集；`group: none` 使编号不延续正文。
  #(thesis.bibliography-thu)(
    read("ref/refs.bib", encoding: none),
    group: none,
  )

  // 部分院系仍要求本科生附外文调研报告或书面翻译：
  // #(thesis.survey)[...]
  // #(thesis.translation)[...]
]

#(thesis.backmatter)[
  #include "data/acknowledgements.typ"

  // 各类开题报告通常不需要声明。扫描件可通过 file 参数替换。
  #(thesis.statement)()

  #include "data/resume.typ"
  #include "data/comments.typ"
  #include "data/resolution.typ"

  // 本科生综合论文训练记录表：
  // #(thesis.record)(read("figures/scan-record.pdf", encoding: none))
]
