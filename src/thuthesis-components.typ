#let thuthesis-components = {
  import "thuthesis-config.typ": thuthesis-config
  import "thuthesis-chapters.typ": thuthesis-chapters
  import "thuthesis-runtime.typ": thuthesis-runtime
  import "thuthesis-text.typ": thuthesis-text
  import "thuthesis-pages.typ": thuthesis-pages
  let chapter-names = thuthesis-config.chapter-names
  let chinese = thuthesis-config.chinese
  let info-at = thuthesis-config.info-at
  let is-graduate = thuthesis-config.is-graduate
  let sans-fonts = thuthesis-config.sans-fonts
  let serif-fonts = thuthesis-config.serif-fonts
  let chapter-label = thuthesis-chapters.chapter-label
  let render-title = thuthesis-chapters.render-title
  let bp = thuthesis-text.bp
  let line-height = thuthesis-text.line-height
  let tex-pt = thuthesis-text.tex-pt
  let tex-vlist-boundary = thuthesis-text.tex-vlist-boundary
  let clear-double-page = thuthesis-pages.clear-double-page
  let clear-page = thuthesis-pages.clear-page

  let _inside(env, render) = {
    (thuthesis-runtime.require-active)()
    render(env.config)
  }

  let _once(name, body) = (thuthesis-runtime.once)(name, body)

  let _page-at(location) = {
    let matter = (thuthesis-runtime.matter-at)(location)
    let value = counter(page).at(location).first()
    numbering(if matter == "front" { "I" } else { "1" }, value)
  }

  // TeX's `titlerule*[4bp]{.}` advances by an invariant 4bp cell. Repeating
  // a bare period plus a gap makes the pitch depend on the font's period
  // advance and on Typst's justification of the leftover width.
  let _dot-leader-cell = box(width: bp(4), align(right, [.]))
  let _dot-leader = repeat(
    _dot-leader-cell,
    gap: 0pt,
    justify: false,
  )

  // LaTeX holds each fixed-baseline line open with a strut whose height/depth
  // are 70%/30% of `baselineskip`. The page margin already contains TeX's
  // `topskip` for ordinary 12bp text, so keep that portion as weak `above`
  // spacing: it contributes in normal flow and disappears at a page boundary.
  let _fixed-line-block(
    body,
    size: bp(12),
    baseline: bp(20),
    before: 0pt,
  ) = {
    let page-top-skip = tex-pt(12) - 0.8 * size
    let top-inset = 0.7 * baseline - tex-pt(12)
    let bottom-inset = 0.3 * baseline - 0.2 * size
    block(
      above: page-top-skip + before,
      below: 0pt,
      width: 100%,
      breakable: false,
      inset: (top: top-inset, bottom: bottom-inset),
      body,
    )
  }

  // The first child of an outline has no preceding sibling, so its weak
  // `above` spacing is discarded even though the outline itself follows a
  // heading. Supply that portion once at the outline boundary.
  let _fixed-line-start(size: bp(12), before: 0pt) = v(
    tex-pt(12) - 0.8 * size + before,
    weak: false,
  )

  let _front-title-outlined(config, kind) = if (
    kind in ("contents", "abstract")
  ) {
    is-graduate(config)
  } else {
    (
      is-graduate(config)
        or (config.degree == "bachelor" and config.language == "english")
    )
  }

  // ThuThesis's English graduate TOC uses `\heiti`: it changes only the CJK
  // family, while Latin text stays in the surrounding serif family.
  let _toc-chapter-fonts(config) = if (
    not chinese(config) and config.degree != "bachelor"
  ) {
    (serif-fonts(config).first(),) + sans-fonts(config).slice(1)
  } else {
    sans-fonts(config)
  }

  let _source-numbered-outline-entry(
    env,
    it,
    target,
    scope,
    separator,
    supplement: true,
  ) = context {
    let location = it.element.location()
    if (
      (thuthesis-runtime.appendix-at)(location)
        and not env.config.appendix-figure-in-list
    ) {
      none
    } else {
      let kind = it.element.fields().at("kind", default: none)
      let number-target = if kind == none {
        target
      } else {
        figure.where(kind: kind)
      }
      let number = counter(number-target).at(location).first()
      let prefix = if it.element.numbering == none {
        none
      } else {
        {
          if supplement {
            it.element.supplement
            text(" ")
          }
          (env.layout.object-number-at)(scope, separator, number, location)
        }
      }
      let inner = [#it.body()#box(width: 1fr, it.fill)#_page-at(location)]
      _fixed-line-block(
        link(location, it.indented(prefix, inner, gap: 1em)),
      )
    }
  }

  let _scanned-page-overlay(env, page-style) = {
    let config = env.config
    if page-style == "plain" {
      let width = 15cm
      if config.degree != "bachelor" {
        place(
          top + center,
          dy: 2.2cm,
          box(width: width, (env.layout.scanned-page-header)()),
        )
      }
      place(
        bottom + center,
        dy: if config.degree == "bachelor" { -1.5cm } else { -2.2cm },
        (env.layout.page-footer)(),
      )
    }
  }

  let _scanned-pages(env, file, pages: (1,), page-style: "empty") = _inside(
    env,
    config => {
      assert(
        page-style in ("plain", "empty"),
        message: "thuthesis: invalid page style",
      )
      assert(
        type(file) in (str, bytes),
        message: "thuthesis: scanned-pages file must be a path or bytes",
      )
      assert(
        type(pages) == array and pages.len() > 0,
        message: "thuthesis: scanned-pages pages must be a non-empty array",
      )
      for number in pages {
        assert(
          type(number) == int and number >= 1,
          message: "thuthesis: every scanned page number must be a positive integer",
        )
        clear-page(weak: true)
        set page(
          paper: "a4",
          margin: 0pt,
          header: none,
          footer: none,
          numbering: none,
        )
        place(top + left, image(
          file,
          page: number,
          width: 210mm,
          height: 297mm,
          fit: "contain",
        ))
        _scanned-page-overlay(env, page-style)
        clear-page()
      }
    },
  )

  let _special-chapter(
    env,
    title,
    body: none,
    outlined: true,
    outline-title: auto,
    header: auto,
    kind: "special",
  ) = _inside(env, config => {
    let outline-title = if outline-title == auto { title } else {
      outline-title
    }
    // Keep `header: auto` as a policy. Each projection is rendered later from
    // logical title content through the title renderer.
    (thuthesis-runtime.begin-special-heading)(kind, outline-title, header)
    heading(level: 1, numbering: none, outlined: outlined, title)
    (thuthesis-runtime.end-special-heading)()
    if body != none { body }
  })

  // Render keyword rows from explicit inline tokens. Whitespace in Typst
  // markup is document content, so formatting this function across source
  // lines must not silently change the distance after the label.
  let _keyword-line(config, language, keywords) = {
    let postdoc = config.degree == "postdoc"
    let indent = if postdoc { h(2em) } else { [] }
    if language == "chinese" {
      let label = if postdoc {
        strong[关键词：]
      } else {
        text(font: sans-fonts(config), [关键词：])
      }
      // `thuthesis.dtx` ends the label with `%`: no glue precedes the first
      // Chinese keyword.
      [#indent#label#keywords.join([；])]
    } else {
      // The literal space after `Keywords:` in `thuthesis.dtx` follows a
      // colon. TeX's sentence-space glue for TeX Gyre Termes is
      // fontdimen2 + fontdimen7 = 1/4em + 1/12em = 1/3em.
      [#indent#strong[Keywords:]#h(1em / 3)#keywords.join([; ])]
    }
  }

  let _abstract-zh(
    env,
    keywords: (),
    title: auto,
    header: auto,
    body,
  ) = _inside(env, config => {
    let names = chapter-names(config)
    let title = if title == auto { names.abstract-zh } else { title }
    (thuthesis-runtime.begin-special-heading)("abstract-zh", title, header)
    heading(
      level: 1,
      numbering: none,
      outlined: _front-title-outlined(config, "abstract"),
      title,
    )
    (thuthesis-runtime.end-special-heading)()
    set text(lang: "zh", region: "CN", font: serif-fonts(config))
    set par(linebreaks: "simple")
    body
    parbreak()
    v(bp(20))
    // Postdoc abstracts omit `\noindent`, retaining the 2em paragraph indent.
    block(_keyword-line(config, "chinese", keywords))
  })

  let _abstract-en(
    env,
    keywords: (),
    title: auto,
    header: auto,
    body,
  ) = _inside(env, config => {
    let names = chapter-names(config)
    let title = if title == auto { names.abstract-en } else { title }
    (env.layout.heading-style)(variant: "english-special", {
      (thuthesis-runtime.begin-special-heading)("abstract-en", title, header)
      heading(
        level: 1,
        numbering: none,
        outlined: _front-title-outlined(config, "abstract"),
        title,
      )
      (thuthesis-runtime.end-special-heading)()
    })
    if config.degree == "bachelor" { v(bp(3)) }
    set text(lang: "en", region: none, font: serif-fonts(config))
    set par(linebreaks: "optimized")
    body
    parbreak()
    v(bp(20))
    // Postdoc abstracts omit `\noindent`, retaining the 2em paragraph indent.
    block(_keyword-line(config, "english", keywords))
  })

  let _toc-number(config, it) = context {
    let element = it.element
    if element.numbering == none {
      []
    } else {
      let location = element.location()
      let appendix = (thuthesis-runtime.appendix-at)(location)
      let values = counter(heading).at(location)
      if it.level == 1 {
        let number = numbering(if appendix { "A" } else { "1" }, values.first())
        chapter-label(config, number, appendix: appendix)
      } else {
        numbering(
          if appendix { "A.1.1.1" } else { element.numbering },
          ..values,
        )
      }
    }
  }

  let _toc-gap(config) = if (
    (config.degree == "bachelor" and config.language == "chinese")
      or (config.degree != "bachelor" and config.language == "english")
  ) { text(" ") } else { h(1em) }

  let _toc-entry(env, it) = context {
    set par(first-line-indent: 0pt)
    let config = env.config
    let location = it.element.location()
    let source-matter = (thuthesis-runtime.matter-at)(location)
    if source-matter in ("appendix", "back") and it.level > 1 {
      none
    } else {
      let numbered = it.element.numbering != none
      let number = if numbered { _toc-number(config, it) } else { none }
      let indent = if not numbered {
        0pt
      } else if (
        config.degree == "bachelor" and config.language == "english"
      ) {
        (it.level - 1) * 0.5cm
      } else {
        (it.level - 1) * 1em
      }
      let chapter-entry = numbered and it.level == 1
      let chapter-before = if (
        chapter-entry
          and config.degree == "bachelor"
          and config.language == "english"
      ) { bp(6) } else { 0pt }
      let prefix = if numbered {
        let body = [#number#_toc-gap(config)]
        if chapter-entry {
          text(font: _toc-chapter-fonts(config), body)
        } else {
          body
        }
      } else { none }
      let outline-title = (thuthesis-runtime.heading-outline-at)(location)
      // Special chapters may use a distinct display and outline title.
      let title = if outline-title == auto { it.body() } else { outline-title }
      let title = if it.level == 1 {
        text(
          font: _toc-chapter-fonts(config),
          render-title(
            config,
            title,
            kind: (thuthesis-runtime.heading-kind-at)(location),
            target: "outline",
            numbered: numbered,
          ),
        )
      } else {
        title
      }
      let styled-inner = [#title#box(width: 1fr, it.fill)#text(
          font: serif-fonts(config),
          _page-at(location),
        )]
      let entry = it.indented(prefix, styled-inner, gap: 0pt)
      _fixed-line-block(
        pad(
          left: indent,
          align(left, link(location, entry)),
        ),
        before: chapter-before,
      )
    }
  }

  let _table-of-contents(env, depth: 3, title: auto, header: auto) = _inside(
    env,
    config => {
      let names = chapter-names(config)
      _special-chapter(
        env,
        if title == auto { names.contents } else { title },
        outlined: _front-title-outlined(config, "contents"),
        header: header,
        kind: "contents",
      )
      _fixed-line-start(
        before: if config.degree == "bachelor"
          and config.language == "english" { bp(6) } else { 0pt },
      )
      show outline.entry: it => _toc-entry(env, it)
      set outline.entry(fill: _dot-leader)
      outline(
        title: none,
        depth: depth,
        indent: 0pt,
      )
    },
  )

  let _object-list(
    env,
    title,
    target,
    scope,
    separator,
    outlined: auto,
    header: auto,
    supplement: true,
  ) = {
    let config = env.config
    _special-chapter(
      env,
      title,
      outlined: if outlined == auto {
        _front-title-outlined(config, "list")
      } else { outlined },
      header: header,
    )
    _fixed-line-start()
    show outline.entry: it => _source-numbered-outline-entry(
      env,
      it,
      target,
      scope,
      separator,
      supplement: supplement,
    )
    set outline.entry(fill: _dot-leader)
    outline(title: none, target: target)
  }

  let _list-of-figures(env) = _inside(env, config => _object-list(
    env,
    chapter-names(config).figures,
    figure.where(kind: image),
    config.figure-numbering,
    config.figure-number-separator,
  ))

  let _list-of-tables(env) = _inside(env, config => _object-list(
    env,
    chapter-names(config).tables,
    figure.where(kind: table),
    config.table-numbering,
    config.table-number-separator,
  ))

  let _list-of-figures-and-tables(env) = _inside(env, config => _object-list(
    env,
    chapter-names(config).figures-tables,
    figure.where(kind: image).or(figure.where(kind: table)),
    config.figure-numbering,
    config.figure-number-separator,
  ))

  let _list-of-algorithms(env) = _inside(env, config => _object-list(
    env,
    chapter-names(config).algorithms,
    figure.where(kind: "algorithm"),
    config.figure-numbering,
    config.figure-number-separator,
  ))

  let _list-of-equations(env) = _inside(env, config => _object-list(
    env,
    chapter-names(config).equations,
    math.equation.where(block: true),
    config.equation-numbering,
    config.equation-number-separator,
    supplement: false,
  ))

  let _denotation(
    env,
    entries,
    label-width: 2.5cm,
    title: auto,
    header: auto,
  ) = _inside(
    env,
    config => {
      assert(
        type(entries) == array,
        message: "thuthesis: denotation entries must be an array",
      )
      assert(
        type(label-width) == length and label-width > 0pt,
        message: "thuthesis: denotation label-width must be a positive length",
      )
      let names = chapter-names(config)
      _special-chapter(
        env,
        if title == auto { names.denotation } else { title },
        outlined: _front-title-outlined(config, "list"),
        header: header,
      )
      for entry in entries {
        assert(
          type(entry) == array and entry.len() == 2,
          message: "thuthesis: each denotation entry must be `(symbol, description)`",
        )
      }
      // TeX's global `\sloppy` and xeCJK punctuation handling let dense rows
      // trade inter-word space and hang closing punctuation before breaking.
      set par(linebreaks: "optimized")
      let cell = body => pad(bottom: bp(8), body)
      grid(
        columns: (label-width, 1fr),
        column-gutter: 0.5cm,
        row-gutter: 0pt,
        ..entries
          .map(entry => (
            cell(entry.at(0)),
            cell(entry.at(1)),
          ))
          .flatten(),
      )
    },
  )

  let _committee(
    env,
    title: [学位论文指导小组、公开评阅人和答辩委员会名单],
    file: none,
    body,
  ) = _inside(env, config => {
    if is-graduate(config) {
      _once("committee", {
        clear-double-page(config, weak: true)
        if file != none {
          _scanned-pages(env, file)
        } else {
          set page(header: none, footer: none, numbering: none)
          (env.layout.heading-style)(variant: "committee", {
            heading(level: 1, numbering: none, outlined: false, title)
            if body != none { body }
          })
          clear-page()
        }
      })
    }
  })

  // `\thu@underline` wraps TeX's primitive `\underline` in 1pt/3pt skips.
  // XITS Math defines its underline gap and thickness as 0.198em and 0.066em.
  let _signature-line(size, width, trailing: true) = {
    let thickness = 0.066 * size
    h(tex-pt(1))
    box(width: width, height: 0pt, {
      place(
        top + left,
        dy: 0.198 * size + thickness / 2,
        line(length: 100%, stroke: thickness),
      )
    })
    // TeX discards the macro's final 3pt glue at a paragraph boundary.
    if trailing { h(tex-pt(3)) }
  }

  let _authorization(config, env) = {
    set page(header: none, footer: none, numbering: none)
    if config.degree == "bachelor" {
      (env.layout.heading-style)(variant: "authorization-bachelor", {
        heading(level: 1, numbering: none, outlined: false)[
          关于论文使用授权的说明
        ]
      })
      v(bp(13))
      line-height(bp(14), bp(26))[
        本人完全了解清华大学有关保留、使用综合论文训练论文的规定，即：学校有权保留论文的复印件，允许论文被查阅和借阅；学校可以公布论文的全部或部分内容，可以采用影印、缩印或其他复制手段保存论文。
      ]
      v(
        tex-vlist-boundary(
          bp(18),
          0.2 * bp(14),
          0.8 * bp(12),
          skip: bp(71),
        ).spacing - (bp(26) - bp(14)),
      )
      pad(left: bp(42), line-height(bp(12), bp(18))[
        #set par(first-line-indent: 0pt)
        作者签名：#h(bp(118))导师签名：
        #v(bp(11))
        日#h(2em)期：#h(bp(118))日#h(2em)期：
      ])
    } else {
      (env.layout.heading-style)(variant: "authorization-graduate", {
        heading(level: 1, numbering: none, outlined: false)[
          关于学位论文使用授权的说明
        ]
      })
      v(bp(13))
      line-height(bp(14), bp(26))[
        本人完全了解清华大学有关保留、使用学位论文的规定，即：

        清华大学拥有在著作权法规定范围内学位论文的使用权，其中包括：（1）已获学位的研究生必须按学校规定提交学位论文，学校可以采用影印、缩印或其他复制手段保存研究生上交的学位论文；（2）为教学和科研目的，学校可以将公开的学位论文作为资料在图书馆、资料室等场所供校内师生阅读，或在校园网上供校内师生浏览部分内容；（3）根据《中华人民共和国学位法》及上级教育主管部门要求，报送相应的学位论文。

        本人保证遵守上述规定。
      ]
      // TeX inserts the new paragraph with its 23.4bp baselineskip after the
      // explicit 33bp skip. Remove the 14bp paragraph's existing Typst spacing
      // before converting that baseline boundary to an edge gap.
      v(
        tex-vlist-boundary(
          bp(23.4),
          0.2 * bp(14),
          0.8 * bp(12),
          skip: bp(33),
        ).spacing - (bp(26) - bp(14)),
      )
      pad(left: bp(43), line-height(bp(12), bp(23.4))[
        #set par(first-line-indent: 0pt)
        作者签名：#h(bp(4))#_signature-line(bp(12), 7em)#h(bp(47))导师签名：#h(bp(4))#_signature-line(bp(12), 7em, trailing: false)
        #v(bp(6))
        日#h(2em)期：#h(bp(4))#_signature-line(bp(12), 7em)#h(bp(47))日#h(2em)期：#h(bp(4))#_signature-line(bp(12), 7em, trailing: false)
      ])
    }
    clear-page()
  }

  let _authorization-component(env, file: none) = _inside(env, config => {
    if config.degree != "postdoc" {
      _once("authorization", {
        clear-double-page(config, weak: true)
        if file != none { _scanned-pages(env, file) } else {
          _authorization(config, env)
        }
      })
    }
  })

  let _acknowledgements(env, title: auto, header: auto, body) = _inside(
    env,
    config => {
      _special-chapter(
        env,
        if title == auto { chapter-names(config).acknowledgements } else {
          title
        },
        header: header,
        kind: "acknowledgements",
      )
      body
    },
  )

  let _statement(env, file: none, page-style: "plain") = _inside(
    env,
    config => {
      assert(
        page-style in ("plain", "empty"),
        message: "thuthesis: statement page-style must be `plain` or `empty`",
      )
      _once("statement", {
        if file != none {
          _scanned-pages(env, file, page-style: page-style)
        } else {
          set page(
            header: if page-style == "plain" {
              (env.layout.page-header)()
            } else { none },
            footer: if page-style == "plain" {
              (env.layout.page-footer)()
            } else { none },
            numbering: if page-style == "plain" { "1" } else { none },
          )
          _special-chapter(
            env,
            chapter-names(config).statement,
            kind: "statement",
          )
          if is-graduate(config) {
            v(bp(13))
            line-height(bp(12), bp(21), text(tracking: bp(0.15))[
              本人郑重声明：所呈交的学位论文，是本人在导师指导下，独立进行研究工作所取得的成果#if info-at(config, "secret-level", default: none) == none { [，不包含涉及国家秘密的内容] }。尽我所知，除文中已经注明引用的内容外，本学位论文的研究成果不包含任何他人享有著作权的内容。对本论文所涉及的研究工作做出贡献的其他个人和集体，均已在文中以明确方式标明。
            ])
            // As above, TeX applies the signature paragraph's 18bp baseline
            // after the explicit skip; Typst has already appended 9bp of
            // paragraph spacing to the preceding 12bp/21bp paragraph.
            v(
              tex-vlist-boundary(
                bp(18),
                0.2 * bp(12),
                0.8 * bp(13),
                skip: bp(78.5),
              ).spacing - (bp(21) - bp(12)),
            )
            pad(left: bp(153.5), line-height(bp(13), bp(18))[
              签#h(1em)名：#_signature-line(bp(13), bp(76))#h(-bp(3))日#h(1em)期：#_signature-line(bp(13), bp(65), trailing: false)
            ])
          } else if config.degree == "bachelor" {
            text(tracking: bp(0.1))[
              本人郑重声明：所呈交的综合论文训练论文，是本人在导师指导下，独立进行研究工作所取得的成果。尽我所知，除文中已经注明引用的内容外，本论文的研究成果不包含任何他人享有著作权的内容。对本论文所涉及的研究工作做出贡献的其他个人和集体，均已在文中以明确方式标明。
            ]
            v(bp(40))
            align(right)[
              签#h(0.5em)名：#_signature-line(bp(12), 2.75cm)#h(0.5em)日#h(0.5em)期：#_signature-line(bp(12), 2.75cm, trailing: false)
            ]
          }
        }
      })
    },
  )

  let _resume(env, title: auto, header: auto, body) = _inside(env, config => {
    _special-chapter(
      env,
      if title == auto { chapter-names(config).resume } else { title },
      header: header,
    )
    if config.degree == "bachelor" and not chinese(config) {
      set text(
        font: sans-fonts(config),
        size: bp(15),
        top-edge: 0.8em,
        bottom-edge: -0.2em,
      )
      set par(leading: bp(5), spacing: bp(5))
    }
    (thuthesis-runtime.reset-achievements)()
    (env.layout.heading-style)(body, variant: "resume")
  })

  let _achievements(env, items) = _inside(env, config => {
    let chinese-mode = chinese(config)
    let graduate-zh = chinese-mode and is-graduate(config)
    let size = if not chinese-mode and config.degree == "bachelor" {
      bp(15)
    } else { bp(12) }
    let baseline = if graduate-zh { bp(16) } else { bp(20) }
    let item-sep = if chinese-mode { bp(6) } else { 0pt }
    let label-width = if chinese-mode { 1cm } else { 1.25cm }
    let label-gap = if chinese-mode { 0pt } else { 0.5cm }
    let label-align = if chinese-mode { left } else { right }
    (thuthesis-runtime.achievements)(items.len(), start => line-height(
      size,
      baseline,
      {
        enum(
          ..items.map(it => [#it]),
          start: start,
          numbering: n => box(
            width: label-width,
            align(label-align, text(
              font: serif-fonts(config).first(),
              lang: "en",
              numbering("[1]", n),
            )),
          ),
          spacing: baseline - size + item-sep,
          indent: 0pt,
          body-indent: label-gap,
        )
        // LaTeX's list `topsep` is present on both sides. Typst collapses a
        // block's lower spacing with the following heading, so preserve this
        // source list parameter as content at the list boundary.
        if item-sep != 0pt { v(item-sep, weak: false) }
      },
    ))
  })

  let _comments(env, title: auto, header: auto, body) = _inside(env, config => {
    if is-graduate(config) {
      _special-chapter(
        env,
        if title == auto { chapter-names(config).comments } else { title },
        header: header,
      )
      body
      clear-page(weak: true)
    }
  })

  let _resolution(env, title: auto, header: auto, body) = _inside(
    env,
    config => {
      if is-graduate(config) {
        _special-chapter(
          env,
          if title == auto { chapter-names(config).resolution } else { title },
          header: header,
        )
        body
        clear-page(weak: true)
      }
    },
  )

  let _record(env, file, pages: (1,)) = _inside(env, config => {
    if config.degree == "bachelor" {
      _once("record", _scanned-pages(env, file, pages: pages))
    }
  })

  let _algorithm-figure(caption: none, body) = figure(
    kind: "algorithm",
    caption: caption,
    body,
  )

  let _chinese-content(body) = {
    set text(lang: "zh", region: "CN")
    set par(linebreaks: "simple")
    body
  }

  let _english-content(body) = {
    set text(lang: "en", region: none)
    set par(linebreaks: "optimized")
    body
  }

  let _bibliography-thu(
    env,
    sources,
    style: auto,
    title: auto,
    full: false,
    target: auto,
    group: auto,
  ) = _inside(env, config => {
    let selected = if style == auto { config.bibliography-style } else { style }
    assert(
      selected in ("numeric", "author-year", "bachelor"),
      message: "thuthesis: invalid bibliography style",
    )
    let csl = if selected == "author-year" {
      "gb-7714-2015-author-date"
    } else {
      "gb-7714-2015-numeric"
    }
    let baseline = if config.degree == "bachelor" and not chinese(config) {
      bp(17)
    } else { bp(16) }
    show bibliography: it => context {
      // LaTeX renders the main bibliography as a chapter, but an appendix's
      // independently numbered bibliography as an unnumbered section inside
      // that appendix chapter.
      let appendix = (thuthesis-runtime.appendix-at)(it.location())
      set heading(level: if appendix { 2 } else { 1 })
      set text(size: bp(10.5))
      let leading = baseline - bp(10.5)
      let item-gap = if config.degree == "bachelor" and not chinese(config) {
        bp(6)
      } else { bp(3) }
      set par(
        // Bibliography entries are narrow, multilingual paragraphs. Optimize
        // the whole entry so long names and publication data can trade space.
        linebreaks: "optimized",
        leading: leading,
        // LaTeX adds `bibitemsep` to the ordinary baseline distance.
        spacing: leading + item-gap,
      )
      it
    }
    bibliography(
      sources,
      title: if title == auto { chapter-names(config).bibliography } else {
        title
      },
      style: csl,
      full: full,
      target: target,
      group: group,
    )
  })

  // Undergraduate survey and translation components retained for LaTeX parity.
  let _survey(body) = {
    heading(level: 1, [外文资料的调研阅读报告])
    _english-content(body)
  }
  let _translation(body) = {
    heading(level: 1, [外文资料的书面翻译])
    _chinese-content(body)
  }
  let _translation-index(
    env,
    sources,
    style: "numeric",
    full: true,
  ) = _bibliography-thu(
    env,
    sources,
    style: style,
    title: [书面翻译对应的原文索引],
    full: full,
  )

  let instance(config, layout) = {
    let env = (config: config, layout: layout)
    (
      abstract-zh: (..args) => _abstract-zh(env, ..args),
      abstract-en: (..args) => _abstract-en(env, ..args),
      table-of-contents: (..args) => _table-of-contents(env, ..args),
      list-of-figures: (..args) => _list-of-figures(env, ..args),
      list-of-tables: (..args) => _list-of-tables(env, ..args),
      list-of-figures-and-tables: (..args) => _list-of-figures-and-tables(
        env,
        ..args,
      ),
      list-of-algorithms: (..args) => _list-of-algorithms(env, ..args),
      list-of-equations: (..args) => _list-of-equations(env, ..args),
      committee: (..args) => _committee(env, ..args),
      authorization: (..args) => _authorization-component(env, ..args),
      scanned-pages: (..args) => _scanned-pages(env, ..args),
      denotation: (..args) => _denotation(env, ..args),
      acknowledgements: (..args) => _acknowledgements(env, ..args),
      resume: (..args) => _resume(env, ..args),
      achievements: (..args) => _achievements(env, ..args),
      comments: (..args) => _comments(env, ..args),
      resolution: (..args) => _resolution(env, ..args),
      statement: (..args) => _statement(env, ..args),
      record: (..args) => _record(env, ..args),
      bibliography-thu: (..args) => _bibliography-thu(env, ..args),
      algorithm-figure: (..args) => _inside(
        env,
        _ => _algorithm-figure(..args),
      ),
      survey: body => _inside(env, _ => _survey(body)),
      translation: body => _inside(env, _ => _translation(body)),
      translation-index: (..args) => _translation-index(env, ..args),
    )
  }

  (instance: instance)
}
