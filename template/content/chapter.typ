= 引言

Typst
是一种现代化的标记语言。本文展示公式、图表和参考文献等论文基本元素。参考文献可以直接使用
BibLaTeX 数据库，例如@knuth1984。

== 数学公式

带编号公式可以写作：

$ E = m c^2 $ <eq:mass-energy>

如@eq:mass-energy 所示，公式编号按章组织。

== 图表

#figure(
  rect(width: 60%, height: 3cm, fill: luma(235), stroke: 0.6pt),
  caption: [示意图],
) <fig:demo>

#figure(
  table(
    columns: 2,
    align: center,
    table.header([项目], [数值]),
    [示例], [1],
  ),
  caption: [示例表格],
) <tab:demo>

@fig:demo 和 @tab:demo 展示了默认题注样式。
