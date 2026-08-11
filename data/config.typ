#import "../lib.typ" as thu

// Keep the configured thesis instance in a standalone module. Typst evaluates
// included files in their own scope, so both the document assembly and special
// pages import this binding explicitly.
#let thesis = thu.thuthesis(
  degree: "master",
  info: (
    title: [清华大学学位论文 Typst 模板#linebreak()使用示例文档 v0.1.0],
    title-en: [An Introduction to Typst Thesis Template of Tsinghua University
      v0.1.0],
    metadata-title: "清华大学学位论文 Typst 模板使用示例文档",
    degree-category: [工学硕士],
    degree-category-en: [Master of Science],
    department: [计算机科学与技术系],
    discipline: [计算机科学与技术],
    discipline-en: [Computer Science and Technology],
    author: [薛瑞尼],
    author-en: [Xue Ruini],
    supervisor: (name: [郑纬民], title: [教授]),
    supervisor-en: (name: [Zheng Weimin], title: [Professor]),
    associate-supervisor: (name: [陈文光], title: [教授]),
    associate-supervisor-en: (name: [Chen Wenguang], title: [Professor]),
    date: datetime(year: 2026, month: 8, day: 8),
  ),
)
