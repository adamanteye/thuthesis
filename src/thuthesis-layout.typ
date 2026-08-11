#let thuthesis-layout = {
  import "thuthesis-config.typ": thuthesis-config
  import "thuthesis-chapters.typ": thuthesis-chapters
  import "thuthesis-runtime.typ": thuthesis-runtime
  import "thuthesis-text.typ": thuthesis-text
  import "thuthesis-pages.typ": thuthesis-pages
  let chinese = thuthesis-config.chinese
  let localized = thuthesis-config.localized
  let math-fonts = thuthesis-config.math-fonts
  let mono-fonts = thuthesis-config.mono-fonts
  let sans-fonts = thuthesis-config.sans-fonts
  let serif-fonts = thuthesis-config.serif-fonts
  let chapter-label = thuthesis-chapters.chapter-label
  let render-title = thuthesis-chapters.render-title
  let baseline-gap = thuthesis-text.baseline-gap
  let bp = thuthesis-text.bp
  let line-height = thuthesis-text.line-height
  let tex-vlist-boundary = thuthesis-text.tex-vlist-boundary
  let tex-pt = thuthesis-text.tex-pt
  let clear-double-page = thuthesis-pages.clear-double-page
  let clear-page = thuthesis-pages.clear-page
  let spine-page = thuthesis-pages.spine-page
  let title-pages = thuthesis-pages.title-pages

  let _circled-footnotes = (
    "⓪",
    "①",
    "②",
    "③",
    "④",
    "⑤",
    "⑥",
    "⑦",
    "⑧",
    "⑨",
    "⑩",
  )

  let _body-font-size = bp(12)
  let _body-baseline = bp(20)
  // TeX positions a continuation page's first baseline with `\topskip`.
  // With ThuThesis's 12bp text and 0.8em top edge, the corresponding inset is
  // 12 TeX pt - 9.6bp. Typst otherwise starts the ink at the page body edge.
  let _body-top-skip = tex-pt(12) - 0.8 * _body-font-size
  let _header-separation = 0.3cm

  // Apply a layout correction only when an unbreakable title block lands at
  // a page boundary. In ordinary flow, the extra weak spacing and the strong
  // inner correction cancel. At a page boundary Typst discards `above`, so
  // the correction remains and moves both the title and following content.
  let _page-boundary-heading-block(above, below, correction, body) = block(
    above: above - correction,
    below: below,
    width: 100%,
    breakable: false,
    {
      v(correction, weak: false)
      block(above: 0pt, below: 0pt, width: 100%, body)
    },
  )

  // Return the first inert text run without laying out the paragraph a second
  // time. It is real source content, while measuring the paragraph itself
  // could duplicate citations, footnotes, counters, and contextual elements.
  let _first-inert-text(value) = if type(value) == str {
    text(value)
  } else if type(value) == content {
    let fields = value.fields()
    if fields.at("text", default: none) != none {
      value
    } else {
      let children = fields.at("children", default: ())
      for child in children {
        let result = _first-inert-text(child)
        if result != none { return result }
      }
      let child = fields.at("child", default: none)
      if child != none { _first-inert-text(child) }
    }
  }

  // CTEX's heading `fixskip` leaves `\prevdepth` unset. TeX therefore places
  // the following paragraph from its first real glyph ascent, whereas Typst's
  // normal paragraph frame starts at 0.8em. Comparing those two measurements
  // inherits the active font and size and introduces no coordinate constant.
  let _fixed-heading-boundary(body) = context v(
    measure(text(
      top-edge: "bounds",
      bottom-edge: "baseline",
      body,
    )).height - measure(text(
      top-edge: 0.8em,
      bottom-edge: "baseline",
      body,
    )).height,
    weak: false,
  )

  // Source-level heading declarations shared by every component. These are
  // style rules from thuthesis.dtx, not coordinates of particular content.
  let _heading-rules = (
    body: (
      chapter: (before: bp(27), after: bp(27)),
      sections: (
        (before: bp(24), after: bp(6), alignment: left),
        (before: bp(12), after: bp(6), alignment: left),
        (before: bp(12), after: bp(6), alignment: left),
      ),
    ),
    committee: (
      chapter: (before: bp(27), after: bp(49), baseline: bp(20)),
      // The LaTeX regression output records `\glue(\lineskip) 1.0` between
      // each section heading and its surrounding multi-row tabulars.
      section: (
        before: bp(26),
        after: bp(9.5),
        alignment: center,
        before-interline: "lineskip",
        after-interline: "lineskip",
      ),
    ),
    authorization-graduate: (
      chapter: (
        before: bp(40),
        after: bp(36),
        size: bp(22),
        // thuthesis.dtx uses `\erhao`, whose default line-height multiplier
        // is 1.3: 22bp * 1.3 = 28.6bp.
        baseline: bp(22) * 1.3,
      ),
    ),
    authorization-bachelor: (
      chapter: (
        before: bp(40),
        after: bp(37),
        size: bp(22),
        baseline: bp(22) * 1.3,
      ),
    ),
    english-special: (
      chapter: (
        before: bp(27),
        after: bp(27),
        size: bp(16),
        baseline: bp(20),
        weight: "bold",
      ),
    ),
  )

  let chapter-break(config, weak: true) = if (
    config.open-right and config.output == "print"
  ) {
    pagebreak(to: "odd", weak: weak)
  } else {
    pagebreak(weak: weak)
  }

  let _heading-number-at(it, appendix) = {
    let values = counter(heading).at(it.location())
    numbering(if appendix { "A" } else { "1" }, values.first())
  }

  // `thuthesis.dtx` sets `aftername = \quad` for every bachelor heading and
  // for Chinese graduate headings. Only English graduate headings use
  // `aftername = \space`. The TOC has a separate delimiter policy.
  let _heading-number-gap(config) = if (
    config.degree == "bachelor" or chinese(config)
  ) { h(1em) } else { text(" ") }

  let render-chapter-heading(
    config,
    it,
    before: auto,
    after: auto,
    baseline: auto,
    size: bp(16),
    weight: auto,
  ) = context {
    chapter-break(config)
    let numbered = it.numbering != none
    let location = it.location()
    let appendix = (thuthesis-runtime.appendix-at)(location)
    let number = if numbered { _heading-number-at(it, appendix) } else { none }
    let title = render-title(
      config,
      it.body,
      kind: (thuthesis-runtime.heading-kind-at)(location),
      target: "heading",
      numbered: numbered,
    )
    let body = {
      if numbered {
        chapter-label(config, number, appendix: appendix)
        _heading-number-gap(config)
      }
      title
    }
    let baseline = if baseline == auto {
      // The corresponding CTEX format uses bare `\sanhao`, so its 16bp size
      // retains the named-size default 1.3 line-height multiplier.
      if chinese(config) or config.degree == "bachelor" { size * 1.3 } else {
        bp(20)
      }
    } else { baseline }
    let weight = if weight == auto {
      if chinese(config) { "regular" } else { "bold" }
    } else { weight }
    let rules = _heading-rules.body.chapter
    let before = if before == auto { rules.before } else { before }
    let after = if after == auto { rules.after } else { after }
    // `block.above` is weak spacing and disappears after the chapter page break.
    // CTEX's `fixskip` retains the chapter beforeskip at the page top and
    // subtracts TeX's `\topskip`.
    v(before - _body-top-skip, weak: false)
    block(
      above: 0pt,
      below: after,
      width: 100%,
      breakable: false,
      align(center, line-height(
        size,
        baseline,
        text(
          font: sans-fonts(config),
          weight: weight,
          // A TeX heading box is bounded by its glyphs, not by the generic
          // 0.8em/0.2em body strut. This also derives the former sub-point
          // before/after-heading compensation from the selected font.
          top-edge: "bounds",
          bottom-edge: "bounds",
          body,
        ),
      )),
    )
    (thuthesis-runtime.mark-after-heading)("chapter")
  }

  let _section-heading(
    config,
    it,
    before: auto,
    after: auto,
    alignment: left,
    frame-spacing: false,
    size: auto,
    suffix: none,
    before-interline: "auto",
    after-interline: "auto",
  ) = context {
    let sizes = (bp(14), bp(13), bp(12))
    let idx = calc.min(it.level - 2, 2)
    let size = if size == auto { sizes.at(idx) } else { size }
    let rules = _heading-rules.body.sections.at(idx)
    let before = if before == auto { rules.before } else { before }
    let after = if after == auto { rules.after } else { after }
    let previous-heading = (thuthesis-runtime.after-heading-at)(it.location())
    let follows-chapter = (
      previous-heading != none and previous-heading.kind == "chapter"
    )
    let appendix = (thuthesis-runtime.appendix-at)(it.location())
    let number = if it.numbering != none {
      let values = counter(heading).at(it.location())
      numbering(if appendix { "A.1.1.1" } else { it.numbering }, ..values)
    } else { none }
    let title = if not chinese(config) and config.degree != "bachelor" {
      upper(it.body)
    } else { it.body }
    let body = {
      if number != none {
        number
        _heading-number-gap(config)
      }
      title
      if suffix != none { suffix }
    }
    let heading-text = text(
      font: sans-fonts(config),
      weight: if chinese(config) { "regular" } else { "bold" },
      body,
    )
    let framed-boundary = (
      frame-spacing
        or before-interline != "auto"
        or after-interline != "auto"
    )
    let natural-ascent = if framed-boundary {
      measure(text(
        size: size,
        top-edge: "bounds",
        bottom-edge: "baseline",
        heading-text,
      )).height
    } else { 0pt }
    let natural-depth = if framed-boundary {
      measure(text(
        size: size,
        top-edge: 0em,
        bottom-edge: "bounds",
        heading-text,
      )).height
    } else { 0pt }
    let before-boundary = if follows-chapter or not framed-boundary {
      none
    } else if before-interline == "lineskip" {
      // The neighboring box cancels out of the edge-to-edge result once TeX
      // has selected `lineskip`; zero is therefore the neutral value here.
      tex-vlist-boundary(
        _body-baseline,
        0pt,
        natural-ascent,
        skip: before,
        next-frame-height: 0.8 * size,
        mode: "lineskip",
      )
    } else {
      tex-vlist-boundary(
        _body-baseline,
        0.2 * _body-font-size,
        natural-ascent,
        skip: before,
        next-frame-height: 0.8 * size,
      )
    }
    let before = if follows-chapter {
      0pt
    } else if before-boundary != none {
      before-boundary.spacing
    } else { before }
    let source-after = after
    let after = if not framed-boundary {
      after
    } else if after-interline == "lineskip" {
      tex-vlist-boundary(
        _body-baseline,
        natural-depth,
        0pt,
        skip: after,
        previous-frame-depth: 0.2 * size,
        mode: "lineskip",
      ).spacing
    } else {
      tex-vlist-boundary(
        _body-baseline,
        natural-depth,
        0.8 * _body-font-size,
        skip: after,
        previous-frame-depth: 0.2 * size,
      ).spacing
    }
    // The page margin carries the top-skip remainder for a 12bp body line.
    // A heading that becomes the first box on a page therefore needs the
    // difference between the canonical body ascent and its own line-frame
    // ascent. Keep that correction inside the block and add its inverse to
    // the weak `above` spacing through `_page-boundary-heading-block`.
    // A section immediately following a chapter is already inside that
    // chapter's page. Applying the page-boundary cancellation there would
    // leave its inner shift behind when the two blocks' spacing collapses.
    let page-start-correction = if before-interline == "lineskip" or (
      before-boundary != none and before-boundary.uses-lineskip
    ) {
      natural-ascent - 0.8 * size
    } else if follows-chapter {
      0pt
    } else {
      0.8 * (_body-font-size - size)
    }
    _page-boundary-heading-block(
      before,
      after,
      page-start-correction,
      align(alignment, line-height(size, bp(20), heading-text)),
    )
    // TeX adds a section's afterskip and a following float's `\intextsep`.
    // Typst collapses the two block spacings, so retain the source-derived
    // difference until either a figure or an intervening paragraph appears.
    let figure-correction = if framed-boundary {
      (
        natural-depth + source-after + tex-pt(12) - 0.2 * size
          - calc.max(after, tex-pt(12))
      )
    } else { 0pt }
    (thuthesis-runtime.mark-after-heading)(
      "section",
      figure-correction: figure-correction,
    )
  }

  // Counter mutation belongs to the numbered-chapter boundary. Heading renderers
  // only read the number and semantic state at the source heading.
  let _numbered-chapter-boundary(config, it, body) = {
    if it.numbering != none {
      if config.figure-numbering == "chapter" {
        counter(figure.where(kind: image)).update(0)
      }
      if config.table-numbering == "chapter" {
        counter(figure.where(kind: table)).update(0)
      }
      if config.equation-numbering == "chapter" {
        counter(math.equation).update(0)
      }
      if config.footnote-numbering == "chapter" { counter(footnote).update(0) }
    }
    body
  }

  let _chapter-heading(config, it, ..options) = _numbered-chapter-boundary(
    config,
    it,
    render-chapter-heading(config, it, ..options),
  )

  // Central heading renderer. Components select a semantic variant; they do not
  // position individual headings.
  let heading-style(config, body, variant: "body") = {
    assert(
      variant
        in (
          "body",
          "committee",
          "authorization-graduate",
          "authorization-bachelor",
          "english-special",
          "resume",
        ),
      message: "thuthesis: invalid heading style variant",
    )
    set heading(numbering: "1.1.1.1", outlined: true)
    if variant == "committee" {
      let rules = _heading-rules.committee
      show heading.where(level: 1): it => _chapter-heading(
        config,
        it,
        ..rules.chapter,
      )
      show heading.where(level: 2): it => _section-heading(
        config,
        it,
        ..rules.section,
      )
      body
    } else if variant == "body" {
      show heading.where(level: 1): it => _chapter-heading(config, it)
      show heading.where(level: 2): it => _section-heading(
        config,
        it,
        frame-spacing: true,
      )
      show heading.where(level: 3): it => _section-heading(
        config,
        it,
        frame-spacing: true,
      )
      show heading.where(level: 4): it => _section-heading(
        config,
        it,
        frame-spacing: true,
      )
      body
    } else if variant == "resume" {
      show heading.where(level: 2): it => _section-heading(
        config,
        it,
        alignment: if config.degree == "bachelor" { left } else { center },
        frame-spacing: true,
        suffix: if config.degree == "bachelor" { [：] } else { none },
      )
      show heading.where(level: 3): it => _section-heading(
        config,
        it,
        before: if chinese(config) { bp(12) } else { 0pt },
        after: baseline-gap(
          if chinese(config) { bp(6) } else { 0pt },
          if chinese(config) { bp(14) } else { bp(13) },
          if not chinese(config) and config.degree == "bachelor" {
            bp(15)
          } else { bp(12) },
          if chinese(config) and config.degree != "bachelor" { bp(16) } else {
            bp(20)
          },
        ),
        size: if chinese(config) { bp(14) } else { auto },
        suffix: if chinese(config) { [：] } else { none },
      )
      body
    } else {
      let rules = _heading-rules.at(variant)
      show heading.where(level: 1): it => _chapter-heading(
        config,
        it,
        ..rules.chapter,
      )
      body
    }
  }

  let _header-title(config) = context {
    let current-page = here().page()
    let chapters = query(heading.where(level: 1)).filter(
      chapter => chapter.location().page() <= current-page,
    )
    if chapters.len() > 0 {
      let chapter = chapters.last()
      let location = chapter.location()
      let appendix = (thuthesis-runtime.appendix-at)(location)
      let numbered = chapter.numbering != none
      let selected = (thuthesis-runtime.heading-header-at)(location)
      if selected != none {
        let derived = selected == auto
        if numbered and derived {
          let number = _heading-number-at(chapter, appendix)
          chapter-label(config, number, appendix: appendix)
          _heading-number-gap(config)
        }
        render-title(
          config,
          if derived { chapter.body } else { selected },
          kind: (thuthesis-runtime.heading-kind-at)(location),
          target: "header",
          numbered: numbered and derived,
        )
      }
    }
  }

  let page-header(config, compensate-ascent: true) = context {
    // The header is evaluated once for each page, making it the explicit page
    // boundary for page-scoped footnotes.
    if config.footnote-numbering == "page" { counter(footnote).update(0) }
    if config.degree != "bachelor" {
      // thuthesis.dtx:3347 uses bare `\wuhao`; the named-size macro's
      // default multiplier is 1.3, so retain the source relationship here.
      let header-size = bp(10.5)
      block(width: 100%)[
        #align(center, move(
          dy: if compensate-ascent { _header-separation } else { 0pt },
          line-height(
            header-size,
            header-size * 1.3,
            text(font: serif-fonts(config), _header-title(config)),
          ),
        ))
        #v(tex-pt(3))
        #line(length: 100%, stroke: bp(0.75))
      ]
    }
  }

  let _footer-size(config) = if (
    config.degree == "bachelor" and config.language == "english"
  ) { bp(12) } else { bp(10.5) }

  let _page-numbering(..numbers) = context {
    let matter = (thuthesis-runtime.matter-at)(here())
    numbering(
      if matter == "front" { "I" } else { "1" },
      ..numbers,
    )
  }

  let page-footer(config, numbering: _page-numbering) = context {
    align(center, text(
      font: serif-fonts(config),
      size: _footer-size(config),
      counter(page).display(numbering),
    ))
  }

  let _page-set(config, body) = {
    set page(
      paper: "a4",
      // Preserve the 3cm bottom boundary, while reproducing TeX's `\topskip`
      // before the first line on continuation pages.
      margin: (top: 3cm + _body-top-skip, rest: 3cm),
      header: page-header(config),
      // The larger body inset must not move the header with it. TeX's rule is
      // a one-sided box, while Typst strokes around its path, hence half the
      // declared rule width is subtracted at this boundary.
      header-ascent: _header-separation + _body-top-skip - bp(0.75) / 2,
      footer: page-footer(config),
      // TeX's footskip addresses the footer baseline, while Typst lowers the
      // footer from the text area's bottom edge by its frame's top-to-baseline
      // distance. ThuThesis's text frame puts that baseline at 0.8em.
      footer-descent: (
        if config.degree == "bachelor" { 1.5cm } else { 0.8cm }
      )
        - 0.8 * _footer-size(config),
      numbering: _page-numbering,
    )
    body
  }

  let object-number-at(config, scope, separator, number, location) = context {
    let chapter = counter(heading).at(location).first()
    if scope == "global" or chapter == 0 {
      numbering("1", number)
    } else {
      let chapter-number = numbering(
        if (thuthesis-runtime.appendix-at)(location) { "A" } else { "1" },
        chapter,
      )
      chapter-number + separator + numbering("1", number)
    }
  }

  let _object-number(config, scope, separator, number) = context {
    object-number-at(config, scope, separator, number, here())
  }

  let _caption(config, it) = context {
    let baseline = if config.degree == "bachelor" {
      bp(15)
    } else if chinese(config) {
      bp(14.3)
    } else {
      bp(12.65)
    }
    align(center, line-height(bp(11), baseline, {
      if it.numbering != none {
        it.supplement
        text(" ")
        it.counter.display(it.numbering)
        h(1em)
      }
      it.body
    }))
  }

  let _figure-style(config, body) = {
    set figure(gap: bp(6))
    show figure: set block(
      above: tex-pt(12),
      below: tex-pt(12),
    )
    show figure: it => context {
      let boundary = (thuthesis-runtime.after-heading-at)(it.location())
      (thuthesis-runtime.clear-after-heading)()
      let styled = {
        let baseline = if chinese(config) { bp(14.3) } else { bp(12.65) }
        let array-stretch = if chinese(config) { 1.42 } else { 1.47 }
        let row-height = baseline * array-stretch
        set text(size: bp(11))
        set par(leading: baseline - bp(11))
        // LaTeX scales the 14.3bp/12.65bp strut by `arraystretch`, retaining
        // its 70% ascent and 30% depth rather than splitting the extra height.
        set table(inset: (
          x: tex-pt(6),
          top: 0.7 * row-height - 0.8 * bp(11),
          bottom: 0.3 * row-height - 0.2 * bp(11),
        ))
        it
      }
      if boundary != none and boundary.kind == "section" {
        pad(top: boundary.figure-correction, styled)
      } else { styled }
    }
    show figure.where(kind: image): set figure(
      supplement: localized(config, [图], [Figure]),
      // TeX's 6bp skip starts at a caption strut with 70% ascent; Typst's
      // caption frame starts at 0.8em. Convert between those two anchors.
      gap: bp(6)
        + 0.7 * if chinese(config) { bp(14.3) } else { bp(12.65) }
        - 0.8 * bp(11),
      numbering: n => _object-number(
        config,
        config.figure-numbering,
        config.figure-number-separator,
        n,
      ),
    )
    show figure.where(kind: table): set figure(
      supplement: localized(config, [表], [Table]),
      // Caption's 6bp skip starts at the TeX line strut's bottom. Convert it
      // to Typst's shallower 0.2em caption frame.
      gap: bp(6)
        + 0.3
          * if config.degree == "bachelor" {
            bp(15)
          } else if chinese(config) {
            bp(14.3)
          } else {
            bp(12.65)
          }
        - 0.2 * bp(11),
      numbering: n => _object-number(
        config,
        config.table-numbering,
        config.table-number-separator,
        n,
      ),
    )
    show figure.where(kind: "algorithm"): set figure(
      supplement: localized(config, [算法], [Algorithm]),
      numbering: n => _object-number(
        config,
        config.figure-numbering,
        config.figure-number-separator,
        n,
      ),
    )
    show figure.where(kind: table): set figure.caption(position: top)
    show figure.caption: it => _caption(config, it)
    body
  }

  // thuthesis.dtx's GB and ISO styles differ from Typst's TeX-oriented
  // defaults in these symbols. Keep all rules in one scope: a nested show-rule
  // helper would realize the formula before an outer symbol rule sees it.
  let _non-tex-math-style(style, body) = {
    // The LaTeX XITS setup selects StylisticSet=8 for upright integrals. All
    // built-in font profiles use XITS Math, as required by this feature.
    show math.equation: set text(stylistic-set: 8)
    show math.Alpha: math.italic
    show math.Beta: math.italic
    show math.Digamma: math.italic
    show math.Gamma: math.italic
    show math.Delta: math.italic
    show math.Epsilon: math.italic
    show math.Zeta: math.italic
    show math.Eta: math.italic
    show math.Theta: math.italic
    show math.Theta.alt: math.italic
    show math.Iota: math.italic
    show math.Kappa: math.italic
    show math.Lambda: math.italic
    show math.Mu: math.italic
    show math.Nu: math.italic
    show math.Xi: math.italic
    show math.Omicron: math.italic
    show math.Pi: math.italic
    show math.Rho: math.italic
    show math.Sigma: math.italic
    show math.Tau: math.italic
    show math.Upsilon: math.italic
    show math.Phi: math.italic
    show math.Chi: math.italic
    show math.Psi: math.italic
    show math.Omega: math.italic
    let less-than-or-equal = if style == "GB" {
      sym.lt.eq.slant
    } else { it => it }
    let greater-than-or-equal = if style == "GB" {
      sym.gt.eq.slant
    } else { it => it }
    let ellipsis = if style == "GB" { math.dots.h.c } else { math.dots.h }
    let integral-limits = if style == "ISO" {
      math.limits.with(inline: false)
    } else { it => it }
    show sym.lt.eq: less-than-or-equal
    show sym.gt.eq: greater-than-or-equal
    show math.partial: math.upright
    show math.dots: ellipsis
    show math.Re: math.upright("Re")
    show math.Im: math.upright("Im")
    show math.integral: integral-limits
    show math.integral.arrow.hook: integral-limits
    show math.integral.ccw: integral-limits
    show math.integral.cont: integral-limits
    show math.integral.cont.ccw: integral-limits
    show math.integral.cont.cw: integral-limits
    show math.integral.cw: integral-limits
    show math.integral.dash: integral-limits
    show math.integral.dash.double: integral-limits
    show math.integral.double: integral-limits
    show math.integral.quad: integral-limits
    show math.integral.inter: integral-limits
    show math.integral.slash: integral-limits
    show math.integral.square: integral-limits
    show math.integral.surf: integral-limits
    show math.integral.times: integral-limits
    show math.integral.triple: integral-limits
    show math.integral.union: integral-limits
    show math.integral.vol: integral-limits
    show math.sum.integral: integral-limits
    body
  }

  let _display-equation(config, it) = context {
    // Typst exposes an equation as a centered frame, while TeX appends a box
    // whose baseline lies on the OpenType math axis. XITS MATH's AxisHeight is
    // 0.25em, so split the measured frame at that axis before applying TeX's
    // normal baselineskip/lineskip decision to each boundary.
    set block(above: 0pt, below: 0pt)
    let formula-height = measure(it).height
    let math-axis = _body-font-size / 4
    let formula-ascent = formula-height / 2 + math-axis
    let formula-depth = formula-height / 2 - math-axis
    // The equation show rule cannot inspect the adjacent laid-out paragraph
    // lines. Use the document's declared line frame on both boundaries rather
    // than substituting a language-specific representative glyph.
    let above = tex-vlist-boundary(
      _body-baseline,
      0.2 * _body-font-size,
      formula-ascent,
      skip: bp(6),
      previous-frame-depth: 0.2 * _body-font-size,
      next-frame-height: formula-ascent,
    ).spacing
    let below = tex-vlist-boundary(
      _body-baseline,
      formula-depth,
      0.8 * _body-font-size,
      skip: bp(6),
      previous-frame-depth: formula-depth,
      next-frame-height: 0.8 * _body-font-size,
    ).spacing
    // TeX appends display glue in addition to surrounding vertical-list glue.
    // Put it inside a zero-spacing wrapper so Typst does not collapse it with
    // an adjacent figure's `below` spacing.
    block(above: 0pt, below: 0pt, {
      v(above, weak: false)
      it
      v(below, weak: false)
    })
  }

  let _equation-style(config, body) = {
    show math.equation: set text(font: math-fonts(config))
    set math.equation(numbering: n => {
      let number = _object-number(
        config,
        config.equation-numbering,
        config.equation-number-separator,
        n,
      )
      if chinese(config) and config.eqn-paren-style == "full" {
        text(font: serif-fonts(config), [（#number）])
      } else {
        text(font: serif-fonts(config), [(#number)])
      }
    })
    show math.equation.where(block: true): it => _display-equation(config, it)
    if config.math-style == "TeX" { body } else {
      _non-tex-math-style(config.math-style, body)
    }
  }

  let _footnote-style(config, body) = {
    let marker-fonts = if config.footnote-style == "circled" {
      serif-fonts(config).slice(1)
    } else {
      serif-fonts(config)
    }
    // thuthesis.dtx uses bare `\xiaowu`: 9bp with the named-size default
    // multiplier 1.3, hence an 11.7bp baseline.
    let footnote-size = bp(9)
    let footnote-baseline = footnote-size * 1.3
    // latex.ltx's `\strutbox` depth is 30% of the active baseline. Each
    // footnote ends with that strut, so it is both the one-line box depth and
    // the distance between consecutive entry frames in Typst's model.
    let footnote-strut-depth = 0.3 * footnote-baseline
    set footnote(numbering: n => if config.footnote-style == "plain" {
      str(n)
    } else if n < _circled-footnotes.len() {
      _circled-footnotes.at(n)
    } else {
      str(n)
    })
    set footnote.entry(
      // LaTeX's -3pt/0.4pt/2.6pt rule has zero layout height. Place the rule
      // 3pt above the first footnote line box instead of compensating a moved
      // text baseline with an unrelated fitted offset.
      separator: block(height: 0pt, place(
        top + left,
        // Typst inserts `gap` before the first entry as well as between later
        // entries. Start from that first entry's top edge, then reproduce
        // TeX's -3pt skip and convert the rule's top edge to a stroke center.
        dy: footnote-strut-depth - tex-pt(3) + tex-pt(0.4) / 2,
        line(length: 30%, stroke: tex-pt(0.4)),
      )),
      // LaTeX's 12pt book class sets `\skip\footins` to 10.8pt. The
      // separator's -3pt/0.4pt/2.6pt dimensions cancel, so this clearance is
      // the full reserved distance between the body and the footnote area.
      clearance: tex-pt(10.8),
      gap: footnote-strut-depth,
      indent: 0pt,
    )
    show footnote.entry: set block(breakable: false)
    show footnote.entry: it => {
      // `\footnotesep` is the height of TeX's footnote strut. Its baseline is
      // the bottom edge, so glyph depth may extend into the bottom margin.
      set text(
        size: footnote-size,
        top-edge: tex-pt(8.4),
        bottom-edge: "baseline",
      )
      // `\xiaowu` uses a 11.7bp baseline. With the explicit 8.4pt strut,
      // leading is the remainder rather than the former generic 0.3em.
      set par(
        leading: footnote-baseline - tex-pt(8.4),
        spacing: footnote-baseline - tex-pt(8.4),
      )
      // Body lists reproduce LaTeX's first-level left margin below. Keep
      // list markup inside a footnote on Typst's existing compact geometry.
      set list(indent: 0pt, body-indent: 0.5em)
      set enum(indent: 0pt, body-indent: 0.5em)
      let location = it.note.location()
      // thuthesis.dtx fixes `\footnotemargin` at 13.5bp. Model it directly
      // as the marker column so the marker starts at the rule and every body
      // line starts exactly one margin later.
      grid(
        columns: (bp(13.5), 1fr),
        inset: 0pt,
        text(
          font: marker-fonts,
          size: footnote-size,
          link(
            location,
            counter(footnote).display(it.note.numbering, at: location),
          ),
        ),
        it.note.body,
      )
    }
    body
  }

  let _body-style(config, body) = {
    set text(
      font: serif-fonts(config),
      size: _body-font-size,
      top-edge: 0.8em,
      bottom-edge: -0.2em,
      lang: if chinese(config) { "zh" } else { "en" },
      region: if chinese(config) { "CN" } else { none },
      // TeX uses finite widow and club penalties, while Typst currently
      // treats every non-zero cost as an absolute prohibition. Let the
      // available page height decide so two-line paragraphs can split like
      // their LaTeX counterparts when a footnote occupies the page bottom.
      costs: (widow: 0%, orphan: 0%),
    )
    set par(
      justify: true,
      // Typst's optimized breaker matches TeX's paragraph-wide algorithm for
      // English. For Chinese prose, the simple breaker follows xeCJK's dense
      // per-character opportunities more closely and avoids unstable reshaping.
      linebreaks: if chinese(config) { "simple" } else { "optimized" },
      leading: _body-baseline - _body-font-size,
      spacing: _body-baseline - _body-font-size,
      first-line-indent: (
        amount: if chinese(config) { 2em } else if config.degree == "bachelor" {
          0.8cm
        } else { 0.74cm },
        all: true,
      ),
    )
    // A real paragraph ends chapter/section adjacency before the next heading
    // rule is evaluated. At that same boundary, restore CTEX's natural first
    // line ascent without changing the paragraph's internal line frames.
    show par: it => context {
      let boundary = (thuthesis-runtime.after-heading-at)(it.location())
      (thuthesis-runtime.clear-after-heading)()
      if boundary != none {
        let first-text = _first-inert-text(it.body)
        if first-text != none { _fixed-heading-boundary(first-text) }
      }
      it
    }
    // The 12pt book layout fixes first-level `leftmargin` at 30pt and
    // `labelsep` at 6pt. LaTeX right-aligns the marker in the remaining 24pt
    // `labelwidth`; measuring a marker only detects the exceptional case in
    // which it overflows that slot. Ordinary markers never move the body.
    let label-separation = tex-pt(6)
    let label = body => box(
      width: tex-pt(30) - label-separation,
      align(right, body),
    )
    // Typst measures `spacing` between item boxes, while LaTeX's zero
    // `itemsep` still retains the document baseline. One leading restores
    // that baseline without adding an extra blank line between items.
    set list(
      marker: label(sym.bullet),
      indent: 0pt,
      body-indent: label-separation,
      spacing: _body-baseline - _body-font-size,
    )
    set enum(
      numbering: n => label(numbering("1.", n)),
      indent: 0pt,
      body-indent: label-separation,
      spacing: _body-baseline - _body-font-size,
    )
    // TeX arrays hold a 20bp body row open with a 14bp/6bp strut. Preserve
    // that asymmetric baseline instead of splitting the 8bp allowance evenly.
    set table(inset: (
      x: tex-pt(6),
      top: 0.7 * _body-baseline - 0.8 * _body-font-size,
      bottom: 0.3 * _body-baseline - 0.2 * _body-font-size,
    ))
    show raw: set text(font: mono-fonts(config))
    let styles = (
      _figure-style,
      _equation-style,
      _footnote-style,
      heading-style,
    )
    styles.fold(body, (result, style) => style(config, result))
  }

  let _document(config, body) = {
    set document(
      title: config.metadata.title,
      author: (config.metadata.author,),
      description: config.metadata.subject,
    )
    (thuthesis-runtime.start)()
    // A selected profile is authoritative. Do not silently embed an unrelated
    // system fallback when one of its fonts lacks a glyph.
    set text(fallback: false)
    title-pages(config)
    _page-set(config, _body-style(config, body))
    (thuthesis-runtime.finish)()
  }

  let _appendix-citation-style(config, body) = if (
    config.bibliography-style == "author-year"
  ) {
    body
  } else {
    let csl = read("thuthesis-appendix-citation.csl")
    show cite.where(style: auto): it => context {
      let chapter = counter(heading).at(here()).first()
      cite(
        it.key,
        supplement: it.supplement,
        form: it.form,
        style: bytes(csl.replace(
          "THUTHESIS_APPENDIX",
          numbering("A", chapter),
        )),
      )
    }
    show regex("^\\[[0-9]+\\]$"): label => context {
      let chapter = counter(heading).at(here()).first()
      text(label.text.replace("[", "[" + numbering("A", chapter) + "."))
    }
    body
  }

  let _matter(config, kind, body) = {
    (thuthesis-runtime.require-active)()
    if kind in ("front", "main") {
      clear-double-page(config, weak: true)
      counter(page).update(1)
    } else if kind == "back" {
      clear-page(weak: true)
    }
    (thuthesis-runtime.transition)(kind, appendix: kind == "appendix")
    if kind == "appendix" { counter(heading).update(0) }
    if kind == "appendix" {
      _appendix-citation-style(config, body)
    } else { body }
  }

  let instance(config) = (
    document: body => _document(config, body),
    frontmatter: body => _matter(config, "front", body),
    mainmatter: body => _matter(config, "main", body),
    appendix: body => _matter(config, "appendix", body),
    backmatter: body => _matter(config, "back", body),
    spine: () => {
      (thuthesis-runtime.require-active)()
      spine-page(config)
    },
    heading-style: (body, variant: "body") => heading-style(
      config,
      body,
      variant: variant,
    ),
    page-header: () => page-header(config),
    scanned-page-header: () => page-header(config, compensate-ascent: false),
    page-footer: (numbering: _page-numbering) => page-footer(
      config,
      numbering: numbering,
    ),
    object-number-at: (scope, separator, number, location) => object-number-at(
      config,
      scope,
      separator,
      number,
      location,
    ),
  )

  (instance: instance)
}
