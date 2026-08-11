// ThuThesis for Typst
// Released under the LaTeX Project Public License 1.3c.

#let thuthesis(..options) = {
  import "src/thuthesis-config.typ": thuthesis-config
  import "src/thuthesis-layout.typ": thuthesis-layout
  import "src/thuthesis-components.typ": thuthesis-components
  let config = (thuthesis-config.normalize)(options)
  let layout = (thuthesis-layout.instance)(config)
  let components = (thuthesis-components.instance)(config, layout)
  (
    document: layout.document,
    frontmatter: layout.frontmatter,
    mainmatter: layout.mainmatter,
    appendix: layout.appendix,
    backmatter: layout.backmatter,
    spine: layout.spine,
    ..components,
  )
}
