#let thuthesis-pages = {
  import "thuthesis-config.typ": thuthesis-config
  import "thuthesis-dates.typ": thuthesis-dates
  import "thuthesis-people.typ": thuthesis-people
  import "thuthesis-text.typ": thuthesis-text
  let chinese = thuthesis-config.chinese
  let fangsong-fonts = thuthesis-config.fangsong-fonts
  let sans-fonts = thuthesis-config.sans-fonts
  let serif-fonts = thuthesis-config.serif-fonts
  let date-en = thuthesis-dates.date-en
  let date-zh = thuthesis-dates.date-zh
  let date-zh-digits = thuthesis-dates.date-zh-digits
  let bachelor-person = thuthesis-people.bachelor-person
  let english-person = thuthesis-people.english-person
  let graduate-person = thuthesis-people.graduate-person
  let bp = thuthesis-text.bp
  let distribute = thuthesis-text.distribute
  let line-height = thuthesis-text.line-height
  let content-ink-ascent = thuthesis-text.content-ink-ascent
  let stretch = thuthesis-text.stretch
  let stretch-text = thuthesis-text.stretch-text
  let tex-pt = thuthesis-text.tex-pt
  let tex-vlist-boundary = thuthesis-text.tex-vlist-boundary

  let clear-page(weak: false) = pagebreak(weak: weak)
  let clear-double-page(config, weak: false) = if config.output == "print" {
    {
      // Typst's `pagebreak(to: "odd")` inherits the current page style on the
      // inserted even page. LaTeX's `cleardoublepage` uses the empty style.
      set page(header: none, footer: none, numbering: none)
      pagebreak(to: "odd", weak: weak)
    }
  } else {
    pagebreak(weak: weak)
  }

  let _underline(
    width,
    body: [],
    stroke: tex-pt(0.7),
    inset-bottom: tex-pt(2),
  ) = box(
    width: width,
    inset: (bottom: inset-bottom),
    stroke: (bottom: stroke),
    align(center, body),
  )

  let _degree-label(config) = {
    let category = config.info.degree-category
    text("(")
    if config.thesis-type == "proposal" {
      [清华大学]
      if config.degree == "doctor" { [博士] } else { [硕士] }
      [学位论文选题报告]
    } else {
      [申请清华大学]
      category
      if config.degree-type == "professional" { [专业] }
      [学位论文]
    }
    text(")")
  }

  let _row(label, value, person: false) = if value != none {
    (label: label, value: value, person: person)
  }

  let _graduate-info(config) = {
    let info = config.info
    // Unlike the postdoc named-size forms, thuthesis.dtx:4614,4619 write
    // `\fontsize{16bp}{31.2bp}` literally, so this baseline remains direct.
    let font-size = bp(16)
    let baseline = bp(31.2)
    let rows = (
      _row("培养单位", info.at("department", default: none)),
      _row(
        if config.degree-type == "academic" { "学科" } else { "专业领域" },
        if config.degree-type == "academic" {
          info.at("discipline", default: none)
        } else {
          info.at("professional-field", default: none)
        },
      ),
      if config.degree-type == "professional" {
        _row("工程领域", info.at("engineering-field", default: none))
      },
      _row(
        if config.degree-type == "academic" { "研究生" } else { "申请人" },
        info.at("author", default: none),
        person: true,
      ),
      if config.thesis-type == "proposal" {
        _row("学号", info.at("student-id", default: none))
      },
      _row("指导教师", info.at("supervisor", default: none), person: true),
      _row(
        "副指导教师",
        info.at("associate-supervisor", default: none),
        person: true,
      ),
      _row(
        "联合指导教师",
        info.at("co-supervisor", default: none),
        person: true,
      ),
    ).filter(it => it != none)
    // LaTeX's `tabular` inserts an array strut whose height and depth are
    // respectively 0.7 and 0.3 of the 31.2bp baseline.  Model the row around
    // that baseline instead of centring 16bp ink in an equally padded cell.
    let row-ascent = 0.7 * baseline
    let row-descent = 0.3 * baseline
    let cell = body => pad(
      top: row-ascent - 0.8 * font-size,
      bottom: row-descent - 0.2 * font-size,
      body,
    )
    // The tabular used by LaTeX retains one 6pt `tabcolsep` at its left edge.
    box(width: 100%, pad(left: 2.3cm + tex-pt(6), grid(
      columns: (2.85cm, 0.77cm, 1fr),
      column-gutter: 0pt,
      row-gutter: 0pt,
      ..rows
        .map(row => (
          cell(box(width: 2.85cm, align(left, stretch(2.75cm, row.label)))),
          cell(box(width: 0.77cm, align(left, [：]))),
          cell(if row.person { graduate-person(row.value) } else { row.value }),
        ))
        .flatten(),
    )))
  }

  let _bachelor-info(config) = {
    let info = config.info
    let size = bp(16)
    let baseline = bp(20)
    let row-height = baseline * 1.548
    let co-supervisor = info.at("co-supervisor", default: none)
    let label-width = if co-supervisor != none { bp(86) } else { bp(79.35) }
    let label-text-width = if co-supervisor != none { 5em } else { 4em }
    let rows = (
      _row("系别", info.at("department", default: none)),
      _row("专业", info.at("discipline", default: none)),
      _row("姓名", info.at("author", default: none), person: true),
      _row("指导教师", info.at("supervisor", default: none), person: true),
      _row(
        "副指导教师",
        info.at("associate-supervisor", default: none),
        person: true,
      ),
      _row("联合指导教师", co-supervisor, person: true),
    ).filter(it => it != none)
    // LaTeX's array strut puts 70% of the stretched 20bp baseline above each
    // row baseline and 30% below it. Keep that asymmetry: symmetric padding
    // preserves row height but moves every text baseline.
    let cell = body => pad(
      top: 0.7 * row-height - 0.8 * size,
      bottom: 0.3 * row-height - 0.2 * size,
      body,
    )
    set text(
      font: fangsong-fonts(config),
      size: size,
      top-edge: 0.8em,
      bottom-edge: -0.2em,
    )
    grid(
      columns: (label-width, bp(23.25), bp(159.4)),
      column-gutter: 0pt,
      row-gutter: 0pt,
      ..rows
        .map(row => (
          cell(box(width: label-width, align(center, distribute(
            label-text-width,
            row.label,
          )))),
          // An isolated full-width colon is compressed at both CJK line
          // edges by Typst. Give it an explicit em box before centring it,
          // matching TeX's full-width punctuation box.
          cell(box(width: bp(23.25), align(center, box(
            width: 1em,
            align(left, [：]),
          )))),
          cell(box(
            width: bp(159.4),
            align(left, if row.person {
              bachelor-person(row.value)
            } else {
              row.value
            }),
          )),
        ))
        .flatten(),
    )
  }

  let _graduate-cover(config) = {
    let info = config.info
    let date = info.date
    let normal-baseline = bp(20)
    let secret-size = bp(16)
    let secret = if info.at("secret-level", default: none) != none {
      [#info.at("secret-level")★#box(width: 3em, align(center, str(info.at(
        "secret-year",
        default: "",
      ))))年]
    } else {
      // thuthesis.dtx:4650 uses the same text in `\phantom`.
      hide([秘密])
    }
    // thuthesis.dtx:4598,4604 writes these `\fontsize` pairs literally;
    // unlike named-size commands, their baselines are not derived defaults.
    let title-size = bp(26)
    let title-baseline = bp(46.8)
    let english-title-size = bp(20)
    let english-title-baseline = bp(31.2)
    let degree-size = bp(16)
    let degree-baseline = bp(22)
    // Fixed heights from the two `\parbox[t][...][t]` declarations in
    // `\thu@titlepage@thesis`.
    let secret-box-height = 2cm
    let date-box-height = 1.03cm
    let paragraph-baseline-skip(
      skip,
      from-descent,
      to-size,
      to-baseline,
      frame-leading: true,
    ) = (
      skip
        + to-baseline
        - from-descent
        - if frame-leading { to-baseline - to-size } else { 0pt }
        - 0.8 * to-size
    )
    set page(
      paper: "a4",
      margin: (top: 2cm, bottom: 6cm, left: 3.5cm, right: 3.5cm),
      header: none,
      footer: none,
      numbering: none,
    )
    set text(font: serif-fonts(config), size: bp(12), lang: "zh", region: "CN")
    align(center)[
      // At the top of a TeX page, `\null` establishes the first baseline at
      // `\topskip`.  The following 2cm top-aligned parbox is still carried by
      // a normal 20bp line, so TeX inserts the remaining baseline glue before
      // the parbox and falls back to `\lineskip` before the 26bp title line.
      #v(tex-pt(12))
      #v(tex-pt(8.1))
      #context {
        v(normal-baseline - content-ink-ascent(text(
          font: sans-fonts(config),
          size: secret-size,
          secret,
        )))
      }
      #block(
        height: secret-box-height,
        width: 100%,
        above: 0pt,
        below: 0pt,
        align(top + left)[
          #move(dx: -tex-pt(21.5), text(
            font: sans-fonts(config),
            size: secret-size,
            secret,
          ))
        ],
      )
      #v(tex-pt(40.5))
      #context {
        let title-ascent = content-ink-ascent(text(
          font: sans-fonts(config),
          size: title-size,
          info.title,
        ))
        // Keep Typst's one-em line frame while deriving where its baseline
        // splits that frame from the selected font and the actual title.
        let title-descent = title-size - title-ascent
        [
          #v(tex-vlist-boundary(
            normal-baseline,
            secret-box-height,
            title-ascent,
          ).spacing)
          #line-height(
            title-size,
            title-baseline,
            text(
              font: sans-fonts(config),
              top-edge: title-ascent,
              bottom-edge: -title-descent,
              info.title,
            ),
            paragraph-spacing: 0pt,
          )
          #if not chinese(config) {
            v(paragraph-baseline-skip(
              tex-pt(5.4),
              title-descent,
              english-title-size,
              english-title-baseline,
              frame-leading: false,
            ))
            line-height(
              english-title-size,
              english-title-baseline,
              text(
                font: sans-fonts(config),
                weight: "bold",
                info.at("title-en"),
              ),
              paragraph-spacing: 0pt,
            )
          }
          // TeX changes to the degree line's 22bp baseline after the explicit
          // skip. Remove the adjoining paragraph edges and leading that Typst
          // would otherwise add around that same baseline-to-baseline distance.
          #let previous-descent = if chinese(config) {
            title-descent
          } else {
            0.2 * english-title-size
          }
          #let degree-skip = if chinese(config) {
            tex-pt(24.1)
          } else {
            tex-pt(24.1 - 9.2)
          }
          #v(paragraph-baseline-skip(
            degree-skip,
            previous-descent,
            degree-size,
            degree-baseline,
          ))
          #line-height(
            degree-size,
            degree-baseline,
            text(tracking: bp(1), _degree-label(config)),
          )
        ]
      }
      #v(1fr)
      #block(
        width: 100%,
        height: if config.degree-type == "academic" { 7.25cm } else { 5.25cm },
        above: 0pt,
        below: 0pt,
        align(
          if config.degree-type == "academic" { top + left } else {
            bottom + left
          },
          text(
            font: fangsong-fonts(config),
            size: bp(16),
            top-edge: 0.8em,
            bottom-edge: -0.2em,
            _graduate-info(config),
          ),
        ),
      )
      #if config.degree-type == "professional" { v(tex-pt(62)) }
      // Both LaTeX parboxes occupy ordinary lines.  Since their combined
      // height and depth exceed the body baseline, TeX separates the lines by
      // `\lineskip`; the title-page macro then lets the date overhang the text
      // area by cancelling 6pt after that line.
      #v(tex-vlist-boundary(normal-baseline, 0pt, date-box-height).spacing)
      #block(
        width: 100%,
        height: date-box-height,
        above: 0pt,
        below: 0pt,
        align(top + center, text(
          size: bp(16),
          tracking: bp(1),
          top-edge: "bounds",
          date-zh(date),
        )),
      )
      #v(-tex-pt(6))
    ]
    clear-page()
  }

  let _english-supervisors(config, thesis-name, baseline) = {
    let info = config.info
    let size = bp(15)
    let rows = (
      (
        [#thesis-name Supervisor],
        english-person(info.supervisor-en),
      ),
      ..if info.at("associate-supervisor-en", default: none) != none {
        (
          (
            [Associate Supervisor],
            english-person(info.associate-supervisor-en),
          ),
        )
      } else { () },
      ..if info.at("co-supervisor-en", default: none) != none {
        (([Co-supervisor], english-person(info.co-supervisor-en)),)
      } else { () },
    )
    // LaTeX's tabular rows contain an array strut with 70% of the requested
    // baseline above and 30% below. A row gutter preserves the row-to-row
    // distance but leaves the first baseline 0.8em from the parbox top.
    let cell = body => pad(
      top: 0.7 * baseline - 0.8 * size,
      bottom: 0.3 * baseline - 0.2 * size,
      body,
    )
    line-height(size, baseline, grid(
      columns: (auto, bp(20.5), auto),
      column-gutter: 0pt,
      row-gutter: 0pt,
      ..rows
        .map(row => (
          cell(align(right, row.at(0))),
          cell(align(left, pad(left: bp(2), [:]))),
          cell(align(left, row.at(1))),
        ))
        .flatten(),
    ))
  }

  let _english-degree(config, thesis-name) = {
    let info = config.info
    let size = bp(16)
    let baseline = size * 1.725
    let line(body, font: serif-fonts(config), weight: "regular") = block(
      width: 100%,
      height: baseline,
      above: 0pt,
      below: 0pt,
      align(top + center, text(
        font: font,
        weight: weight,
        size: size,
        top-edge: 0.8em,
        bottom-edge: -0.2em,
        body,
      )),
    )
    stack(
      spacing: 0pt,
      line([#thesis-name submitted to]),
      line([Tsinghua University], weight: "bold"),
      line([in partial fulfillment of the requirement]),
      line({
        [for the]
        text(" ")
        if config.degree-type == "professional" {
          [professional]
          text(" ")
        }
        [degree of]
      }),
      line(
        info.degree-category-en,
        font: sans-fonts(config),
        weight: "bold",
      ),
      if config.degree-type == "academic" {
        stack(
          spacing: 0pt,
          v(bp(3)),
          line([in]),
          v(bp(3.5)),
          line(
            info.discipline-en,
            font: sans-fonts(config),
            weight: "bold",
          ),
        )
      },
    )
  }

  let _english-author(config) = context {
    let size = bp(16)
    let baseline = size * 1.725
    let natural-line(body, weight: "regular") = block(
      width: 100%,
      above: 0pt,
      below: 0pt,
      align(center, box(text(
        font: sans-fonts(config),
        weight: weight,
        size: size,
        top-edge: "bounds",
        bottom-edge: "bounds",
        body,
      ))),
    )
    let by = natural-line([by])
    // TeX's author paragraph is followed by a large parbox and therefore
    // contributes its real glyph depth before `lineskip` is applied.
    let author = natural-line(config.info.author-en, weight: "bold")
    stack(
      spacing: baseline + 0.24cm - measure(by).height,
      by,
      author,
    )
  }

  let _english-title-page(config) = {
    let info = config.info
    // thuthesis.dtx:4839 explicitly selects `\fontsize{20bp}{31.2bp}`.
    let title-size = bp(20)
    let title-baseline = bp(31.2)
    let surrounding-baseline = bp(16) * 1.725
    let title-box-height = bp(143)
    let supervisor-box-height = if config.degree-type == "academic" {
      3cm
    } else { 3.37cm }
    let supervisor-size = bp(15)
    let supervisor-baseline = supervisor-size * if (
      config.degree-type == "academic"
    ) { 2.1 } else { 1.82 }
    let supervisor-rows = 1 + (
      if info.at("associate-supervisor-en", default: none) != none { 1 } else {
        0
      }
    ) + (if info.at("co-supervisor-en", default: none) != none { 1 } else { 0 })
    // A centred LaTeX `tabular` is a `\vcenter`: its reference height is
    // half the array's total strut height plus XITS Math's 0.25em axis.
    // `parbox[t]` uses that reference height, not the declared box height.
    let supervisor-reference-height = (
      supervisor-rows * supervisor-baseline / 2 + supervisor-size / 4
    )
    let natural-line(body, weight: "regular") = block(
      width: 100%,
      above: 0pt,
      below: 0pt,
      align(center, box(text(
        font: sans-fonts(config),
        weight: weight,
        size: bp(16),
        top-edge: "bounds",
        bottom-edge: "bounds",
        body,
      ))),
    )
    let author-depth = () => measure(text(
      font: sans-fonts(config),
      weight: "bold",
      size: bp(16),
      top-edge: 0em,
      bottom-edge: "bounds",
      info.author-en,
    )).height
    let thesis-name = if config.degree == "master" { "Thesis" } else {
      "Dissertation"
    }
    let date = info.date
    set page(
      paper: "a4",
      margin: (top: 5.5cm, bottom: 5cm, left: 3.4cm, right: 3.4cm),
      header: none,
      footer: none,
      numbering: none,
    )
    set text(font: serif-fonts(config), lang: "en")
    set block(spacing: 0pt)
    align(center)[
      #v(-0.31cm)
      #block(
        width: 100%,
        height: title-box-height,
        above: 0pt,
        below: 0pt,
        align(top + center, move(
          // `\null` starts an ordinary 20bp line whose first baseline is
          // positioned by the 12pt `\topskip`. Keep the 143bp title region
          // fixed and reproduce that baseline inside it.
          dy: tex-pt(12) + bp(20) - 0.8 * title-size,
          line-height(
            title-size,
            title-baseline,
            text(
              font: sans-fonts(config),
              weight: "bold",
              info.title-en,
            ),
          ),
        )),
      )
      // A TeX top-aligned parbox ends below the first title baseline by its
      // declared height minus the title glyph ascent. The following degree
      // paragraph starts after `lineskip` plus its own glyph ascent. Derive
      // that transition from the two fonts instead of shifting the degree
      // block by an observed coordinate.
      #context {
        let title-ascent = content-ink-ascent(text(
          font: sans-fonts(config),
          weight: "bold",
          size: title-size,
          info.title-en,
        ))
        let degree-ascent = content-ink-ascent(text(
          font: serif-fonts(config),
          size: bp(16),
          [#thesis-name submitted to],
        ))
        v(
          tex-pt(12) + bp(20)
            - title-ascent
            + tex-vlist-boundary(
              bp(20),
              title-box-height,
              degree-ascent,
            ).spacing
            + degree-ascent
            - 0.8 * bp(16),
        )
        _english-degree(config, thesis-name)
      }
      #v(1fr)
      // TeX makes `by` and the author two ordinary `\sanhao[1.725]`
      // paragraphs, with the explicit 0.24cm skip added between their
      // baselines. Keep them in one fixed-baseline stack so Typst does not
      // create two extra paragraph frames around the intervening space.
      #_english-author(config)
      #if config.degree-type == "academic" {
        context {
          v(tex-vlist-boundary(
            surrounding-baseline,
            author-depth(),
            supervisor-reference-height,
            skip: 0.18cm,
            previous-frame-depth: author-depth(),
            next-frame-height: supervisor-reference-height,
          ).spacing)
        }
      } else if info.at("professional-field-en", default: none) != none {
        let field = [(#info.at("professional-field-en"))]
        context {
          let field-ascent = measure(text(
            font: sans-fonts(config),
            weight: "bold",
            size: bp(16),
            top-edge: "bounds",
            bottom-edge: "baseline",
            field,
          )).height
          v(tex-vlist-boundary(
            surrounding-baseline,
            author-depth(),
            field-ascent,
            skip: -0.1cm,
            previous-frame-depth: author-depth(),
            next-frame-height: field-ascent,
          ).spacing)
          natural-line(field, weight: "bold")
          let field-depth = measure(text(
            font: sans-fonts(config),
            weight: "bold",
            size: bp(16),
            top-edge: 0em,
            bottom-edge: "bounds",
            field,
          )).height
          v(tex-vlist-boundary(
            surrounding-baseline,
            field-depth,
            supervisor-reference-height,
            skip: 1.1cm,
            previous-frame-depth: field-depth,
            next-frame-height: supervisor-reference-height,
          ).spacing)
        }
      } else {
        context {
          v(tex-vlist-boundary(
            surrounding-baseline,
            author-depth(),
            supervisor-reference-height,
            skip: 1.95cm,
            previous-frame-depth: author-depth(),
            next-frame-height: supervisor-reference-height,
          ).spacing)
        }
      }
      #block(
        width: 100%,
        height: supervisor-box-height,
        above: 0pt,
        below: 0pt,
        align(top + center, _english-supervisors(
          config,
          thesis-name,
          supervisor-baseline,
        )),
      )
      #v(tex-vlist-boundary(
        surrounding-baseline,
        supervisor-box-height,
        0pt,
      ).spacing)
      #text(
        font: sans-fonts(config),
        weight: "bold",
        size: bp(16),
        top-edge: "bounds",
        bottom-edge: "bounds",
        date-en(date),
      )
      #v(if config.degree-type == "academic" { 0.7cm } else { 0.3cm })
    ]
    clear-page()
  }

  let _bachelor-cover(config) = {
    let info = config.info
    let date = info.date
    let heading-size = bp(36)
    let heading-baseline = heading-size * 1.3
    let title-size = bp(26)
    // thuthesis.dtx:4933 explicitly writes `\fontsize{26bp}{32.5bp}`.
    let title-baseline = bp(32.5)
    // The source logo is square and included at 49bp; the title is the
    // `\parbox[t][136bp]` immediately below it.
    let logo-size = bp(49)
    let title-box-height = bp(136)
    set page(
      paper: "a4",
      margin: (top: 3.8cm, bottom: 3.2cm, left: 3.2cm, right: 3cm),
      header: none,
      footer: none,
      numbering: none,
    )
    set text(font: serif-fonts(config), lang: "zh", region: "CN")
    box(width: 100%, height: 0pt, align(top + right, text(size: bp(12))[
      #if info.at("secret-level", default: none) != none {
        info.at("secret-level")
        text(" ")
        str(info.at("secret-year", default: ""))
        text(" ")
        [年]
      }
    ]))
    v(bp(21))
    align(center)[
      // The zero-height secrecy parbox still establishes TeX's 12pt top-skip.
      // The following 49bp image line is too tall for the normal baseline, so
      // TeX adds its 1pt lineskip before the line box.
      #v(tex-pt(12) + tex-vlist-boundary(bp(20), 0pt, logo-size).spacing)
      #block(
        width: 100%,
        height: logo-size,
        above: 0pt,
        below: 0pt,
        align(bottom + center, grid(
          columns: (bp(49), bp(10), bp(112)),
          // The two graphics are inline boxes in LaTeX: their bottoms share a
          // baseline before the wordmark is raised by 4.5bp.
          align: (bottom + center, bottom + center, bottom + center),
          image("../assets/thu-fig-logo.pdf", width: logo-size),
          [],
          move(
            dy: -bp(4.5),
            image(
              "../assets/thu-text-logo.pdf",
              width: bp(112),
              height: bp(41),
              // LaTeX's `\includegraphics[width=112bp, height=41bp]`
              // scales the 143pt × 47pt source independently on both axes.
              fit: "stretch",
            ),
          ),
        )),
      )
      #v(bp(21.5))
      // These are ordinary TeX paragraph lines: the first heading baseline is
      // a full 1.3-line baseline below the preceding image baseline. Typst's
      // default first-line frame includes only half-leading, so use explicit
      // baseline-high blocks whose bottoms are the baselines.
      #context {
        let heading-line(body) = block(
          width: 100%,
          height: heading-baseline,
          above: 0pt,
          below: 0pt,
          align(bottom + center, text(
            font: sans-fonts(config),
            weight: "bold",
            size: heading-size,
            tracking: 0.3em,
            top-edge: "bounds",
            bottom-edge: "baseline",
            body,
          )),
        )
        let heading-lines = (
          [综合论文训练],
          ..if config.thesis-type == "proposal" { ([开题报告],) } else { () },
        )
        stack(spacing: 0pt, ..heading-lines.map(heading-line))

        let last-heading = heading-lines.last()
        let heading-depth = measure(text(
          font: sans-fonts(config),
          weight: "bold",
          size: heading-size,
          tracking: 0.3em,
          top-edge: 0em,
          bottom-edge: "bounds",
          last-heading,
        )).height

        // The title is the first line of a 136bp top-aligned parbox. TeX
        // reaches its top through the preceding glyph depth, 48bp source skip
        // and the 1pt lineskip used between the two oversized line boxes.
        v(
          heading-depth
            + bp(48)
            + tex-vlist-boundary(bp(20), 0pt, title-box-height).spacing
        )
        block(
          width: 100%,
          height: title-box-height,
          above: 0pt,
          below: 0pt,
          align(top + center, {
            let title-paragraph(body, font) = block(
              width: 100%,
              above: 0pt,
              below: 0pt,
              align(center, line-height(
                title-size,
                title-baseline,
                text(
                  font: font,
                  top-edge: "bounds",
                  bottom-edge: "bounds",
                  body,
                ),
                paragraph-spacing: 0pt,
              )),
            )
            title-paragraph(info.title, sans-fonts(config))
            if config.language == "english" {
              let previous-depth = measure(text(
                font: sans-fonts(config),
                size: title-size,
                top-edge: 0em,
                bottom-edge: "bounds",
                info.title,
              )).height
              let next-ascent = measure(text(
                font: serif-fonts(config),
                size: title-size,
                top-edge: "bounds",
                bottom-edge: "baseline",
                info.title-en,
              )).height
              v(title-baseline - previous-depth - next-ascent)
              title-paragraph(info.title-en, serif-fonts(config))
            }
          }),
        )
      }
      // The information tabular is another oversized line box, so TeX puts
      // its 1pt lineskip immediately after the fixed-height title parbox.
      #v(tex-vlist-boundary(bp(20), title-box-height, 0pt).spacing)
      #_bachelor-info(config)
      #v(1fr)
      #line-height(
        bp(16),
        bp(24),
        text(tracking: 0.03em, date-zh(date)),
      )
      #v(bp(53))
    ]
    clear-page()
  }

  // A TeX line is a baseline-oriented hbox.  Keeping that hbox separate from
  // Typst's paragraph frame prevents a one-line paragraph from consuming a
  // full requested baseline below its ink.
  //
  // The 0.8em/0.2em split is not a LaTeX layout constant: it is the local
  // Typst frame convention defined by `thuthesis-text.line-height`.  These
  // names only convert between that frame edge and TeX's baseline/depth model.
  let _postdoc-frame-ascent = 0.8
  let _postdoc-frame-descent = 0.2
  // LaTeX sources: size12.clo sets `\topskip=12pt`; latex.ltx sets
  // `\normallineskip=1pt`; thuthesis.dtx:2223 sets `\normalsize` to 12/20bp.
  let _postdoc-topskip = tex-pt(12)
  let _postdoc-lineskip = tex-pt(1)
  let _postdoc-surrounding-baseline = bp(20)
  let _postdoc-line(size, body, alignment: center) = block(
    width: 100%,
    height: size,
    clip: false,
    align(alignment, text(
      size: size,
      top-edge: 0.8em,
      bottom-edge: -0.2em,
      body,
    )),
  )

  let _postdoc-cover(config) = {
    let info = config.info
    let date = info.date
    let start = info.start-date
    let end = info.end-date
    // thuthesis.dtx:5006,5013,5019,5024,5026,5038,5040.  The optional
    // arguments of `\sihao`, `\xiaoer`, and `\xiaosi` multiply the font size
    // to produce the requested baseline; none of these are fitted offsets.
    let metadata-size = bp(14)
    let metadata-baseline = metadata-size * 2.6
    let heading-size = bp(18)
    let heading-baseline = heading-size * 2.6
    let title-size = bp(14)
    let title-baseline = title-size * 3.46
    let body-size = bp(12)
    let date-baseline = body-size * 1.58
    let institution-baseline = body-size * 2
    let metadata-underline(value) = {
      // TeX's primitive `\underline` uses XITS Math's OpenType MATH
      // constants: 0.198em vertical gap and 0.066em rule thickness.  The
      // surrounding `\ULthickness` assignment only affects ulem, not this
      // primitive underline (thuthesis.dtx:5004,5007-5010).
      let gap = 0.198 * metadata-size
      let thickness = 0.066 * metadata-size
      box(
        width: 3.7cm,
        height: metadata-size,
        baseline: _postdoc-frame-ascent * metadata-size,
        clip: false,
        {
          place(
            top + left,
            dy: gap + thickness / 2,
            line(length: 100%, stroke: thickness),
          )
          move(
            dy: -_postdoc-frame-ascent * metadata-size,
            block(width: 100%, align(top + center, value)),
          )
        },
      )
    }
    let date-underline(body) = box(
      width: 5.9cm,
      height: body-size,
      baseline: _postdoc-frame-ascent * body-size,
      clip: false,
      {
        // thuthesis.dtx:5027 sets `\ULdepth=0.9em`; unlike a padded box,
        // ulem's rule does not change the line's reference baseline.
        place(
          top + left,
          dy: 0.9 * body-size,
          line(length: 100%, stroke: tex-pt(0.7)),
        )
        move(
          dy: -_postdoc-frame-ascent * body-size,
          block(width: 100%, align(top + center, body)),
        )
      },
    )
    let top-line(label, value, cjk: true) = {
      if cjk {
        stretch(3.1em, label)
      } else {
        // `\thu@stretch` only stretches XeCJK's `\CJKglue`.  Latin spaces
        // in “U D C” therefore keep their natural width and the 3.1em box is
        // padded on the right; distributing Latin clusters is not equivalent.
        box(width: 3.1em, align(left, label))
      }
      h(tex-pt(1))
      metadata-underline(value)
      h(tex-pt(3))
    }
    let report-date-value = date-zh-digits(date, day: false)
    let report-date-row = [报告提交日期#h(1em)#date-underline(report-date-value)]
    set page(
      paper: "a4",
      margin: 3cm,
      header: none,
      footer: none,
      numbering: none,
    )
    set text(font: serif-fonts(config), lang: "zh", region: "CN")
    set block(spacing: 0pt)
    align(center)[
      // `center` starts with an empty line at `topskip`; the first 14bp line
      // is then appended at its requested 36.4bp baseline.
      #v(
        _postdoc-topskip
          + metadata-baseline
          - _postdoc-frame-ascent * metadata-size
          + 0.35cm
      )
      #_postdoc-line(metadata-size, grid(
        columns: (1fr, 1fr),
        align: (left, right),
        top-line("分类号", info.at("clc", default: [])),
        {
          [密级]
          h(tex-pt(1))
          metadata-underline(info.at("secret-level", default: []))
        },
      ))
      #v(metadata-baseline - metadata-size)
      #_postdoc-line(metadata-size, grid(
        columns: (1fr, 1fr),
        align: (left, right),
        top-line("U D C", info.at("udc", default: []), cjk: false),
        {
          [编号]
          h(tex-pt(1))
          metadata-underline(info.at("id", default: []))
        },
      ))
      // An explicit vskip between TeX paragraphs is followed by the next
      // baseline glue.  Convert that baseline to the two line-frame edges.
      #v(
        3.15cm
          + heading-baseline
          - _postdoc-frame-descent * metadata-size
          - _postdoc-frame-ascent * heading-size
      )
      #_postdoc-line(heading-size, text(
        font: sans-fonts(config),
        weight: "bold",
        tracking: 1.5em,
        [清华大学],
      ))
      #v(heading-baseline - heading-size)
      #_postdoc-line(heading-size, text(
        font: sans-fonts(config),
        weight: "bold",
        tracking: 0.5em,
        [博士后研究工作报告],
      ))
      // A top-aligned parbox has zero height at its reference baseline and
      // follows the surrounding 20bp paragraph baseline.
      #v(
        0.2cm
          + _postdoc-surrounding-baseline
          - _postdoc-frame-descent * heading-size
      )
      #block(
        width: 100%,
        height: 4cm,
        align(center + horizon, pad(
          // `line-height` already reserves 0.2em below the baseline.  ulem's
          // `\ULdepth=1em` in thuthesis.dtx:5020 adds the remaining 0.8em to
          // the title paragraph's last line before `parbox[c]` centres it.
          bottom: (1 - _postdoc-frame-descent) * title-size,
          line-height(title-size, title-baseline, underline(
            offset: 1em,
            stroke: tex-pt(0.7),
            info.title,
          )),
        )),
      )
      // The deep parbox and both underlined date rows trigger TeX's 1pt
      // `lineskip` branch instead of its normal baseline glue.
      #context {
        let author-height = measure(text(
          font: serif-fonts(config),
          size: body-size,
          top-edge: "bounds",
          bottom-edge: "baseline",
          info.author,
        )).height
        v(tex-vlist-boundary(
          _postdoc-surrounding-baseline,
          4cm,
          author-height,
          skip: 0.4cm,
          previous-frame-depth: 4cm,
          next-frame-height: _postdoc-frame-ascent * body-size,
          mode: "lineskip",
        ).spacing)
      }
      #_postdoc-line(body-size, info.author)
      #v(1.4cm + date-baseline - body-size)
      #_postdoc-line(body-size)[
        工作完成日期#h(1em)#date-underline(
          [#date-zh-digits(start, day: false)—#date-zh-digits(
              end,
              day: false,
            )],
        )
      ]
      #context {
        v(tex-vlist-boundary(
          date-baseline,
          0.9 * body-size,
          measure(text(
            font: serif-fonts(config),
            size: body-size,
            top-edge: "bounds",
            bottom-edge: "baseline",
            [报告提交日期#h(1em)#report-date-value],
          )).height,
          skip: 0.55cm,
          previous-frame-depth: _postdoc-frame-descent * body-size,
          next-frame-height: _postdoc-frame-ascent * body-size,
          mode: "lineskip",
        ).spacing)
      }
      #_postdoc-line(body-size, report-date-row)
      #v(0.45cm + institution-baseline - body-size)
      #_postdoc-line(body-size)[
        #text(tracking: 1em, [清华大学])#h(1em)#text[（北京）]
      ]
      #v(0.25cm + institution-baseline - body-size)
      #_postdoc-line(body-size, date-zh-digits(date, day: false))
    ]
    clear-page()
  }

  let _postdoc-title-page(config) = {
    let info = config.info
    let date = info.date
    let start = info.start-date
    let end = info.end-date
    // thuthesis.dtx:5052,5056,5059,5068,5074,5076.  In particular, the
    // repeated 31.2bp is derived as both 16bp*1.95 and 12bp*2.6.
    let chinese-title-size = bp(16)
    let chinese-title-baseline = chinese-title-size * 1.95
    let english-title-size = bp(14)
    let english-title-baseline = english-title-size * 1.36
    let body-size = bp(12)
    let body-baseline = body-size * 2.6
    let final-date-size = bp(10.5)
    let final-date-baseline = final-date-size * 1.3
    let centered-parbox(height, size, baseline, body) = block(
      width: 100%,
      height: height,
      // thuthesis.dtx:5051-5057 uses `parbox[t][3cm][c]`: retain the fixed
      // outer height, vertical centring and the named font's baseline.
      align(center + horizon, line-height(size, baseline, body)),
    )
    let table-baseline = body-baseline
    let table-line(body) = box(
      height: body-size,
      clip: false,
      text(
        size: body-size,
        top-edge: 0.8em,
        bottom-edge: -0.2em,
        body,
      ),
    )
    let table-cell(body) = pad(
      // latex.ltx's `\strutbox` is 0.7 baseline high and 0.3 deep;
      // thuthesis.dtx:5061 keeps `\arraystretch=1` for this table.
      top: 0.7 * table-baseline - _postdoc-frame-ascent * body-size,
      bottom: 0.3 * table-baseline - _postdoc-frame-descent * body-size,
      table-line(body),
    )
    let information-table = block(width: 100%, align(center, pad(
      x: tex-pt(6),
      grid(
        columns: (11 * body-size, body-size, auto),
        column-gutter: 0pt,
        row-gutter: 0pt,
        align: left,
        table-cell(distribute(11 * body-size, "博士后姓名")), [],
        table-cell(info.author),
        table-cell(distribute(11 * body-size, "流动站（一级学科）名称")), [],
        table-cell(info.discipline-level-1),
        table-cell(distribute(
          11 * body-size,
          ("专", h(body-size), "业（二级学科）名称"),
        )), [],
        table-cell(info.discipline-level-2),
      ),
    )))
    let start-date-row = [研究工作起始时间#h(1em)#date-zh-digits(start)]
    set page(
      paper: "a4",
      margin: 3cm,
      header: none,
      footer: none,
      numbering: none,
    )
    set text(font: serif-fonts(config), lang: "zh", region: "CN")
    set block(spacing: 0pt)
    align(center)[
      // The first top-aligned parbox follows the empty `center` line at the
      // class's 20bp body baseline.
      #v(_postdoc-topskip + _postdoc-surrounding-baseline + 1.5cm)
      #centered-parbox(
        3cm,
        chinese-title-size,
        chinese-title-baseline,
        info.title,
      )
      #v(0.15cm + _postdoc-lineskip)
      #centered-parbox(
        3cm,
        english-title-size,
        english-title-baseline,
        info.title-en,
      )
      #v(0.4cm + _postdoc-lineskip)
      #information-table
      #context {
        v(tex-vlist-boundary(
          body-baseline,
          0pt,
          measure(text(
            font: serif-fonts(config),
            size: body-size,
            top-edge: "bounds",
            bottom-edge: "baseline",
            start-date-row,
          )).height,
          skip: 2.7cm,
          previous-frame-depth: 0pt,
          next-frame-height: _postdoc-frame-ascent * body-size,
          mode: "lineskip",
        ).spacing)
      }
      #_postdoc-line(body-size, start-date-row)
      #v(0.1cm + body-baseline - body-size)
      #_postdoc-line(body-size)[
        研究工作期满时间#h(1em)#date-zh-digits(end)
      ]
      #v(2.1cm + body-baseline - body-size)
      #_postdoc-line(body-size, [清华大学人事处（北京）])
      #v(
        0.6cm
          + final-date-baseline
          - _postdoc-frame-descent * body-size
          - _postdoc-frame-ascent * final-date-size
      )
      #_postdoc-line(final-date-size, date-zh-digits(date, day: false))
    ]
    clear-page()
  }

  let spine-page(config) = {
    let title = if config.spine-title == auto {
      config.info.title
    } else { config.spine-title }
    let author = if config.spine-author == auto {
      config.info.author
    } else { config.spine-author }
    let font-size = if config.spine-font != auto {
      config.spine-font
    } else if config.degree == "doctor" {
      bp(16)
    } else {
      bp(15)
    }
    let text-height = if config.degree == "bachelor" { 23.7cm } else { 18.7cm }
    set page(
      paper: "a4",
      margin: (
        top: if config.degree == "bachelor" { 3cm } else { 5.5cm },
        bottom: if config.degree == "bachelor" { 3cm } else { 5.5cm },
        left: 1cm,
        right: 1cm,
      ),
      header: none,
      footer: none,
      numbering: none,
    )
    align(right + horizon, rotate(
      -90deg,
      origin: top + left,
      reflow: true,
      block(width: text-height, height: 1.5em)[
        #set text(
          font: fangsong-fonts(config),
          size: font-size,
          features: ("vert",),
        )
        // Typst's transformed frame runs opposite to graphicx's `lt` origin;
        // reverse the two anchors so the rendered spine still reads title at
        // the physical top and author at the physical bottom.
        #place(right + horizon, title)
        #place(left + horizon, stretch-text(4.5em, author))
      ],
    ))
    clear-page()
  }

  let title-pages(config) = {
    counter(page).update(1)
    clear-double-page(config, weak: true)
    if config.degree == "bachelor" {
      _bachelor-cover(config)
      if config.include-spine { spine-page(config) }
    } else if config.degree == "postdoc" {
      _postdoc-cover(config)
      clear-double-page(config, weak: true)
      _postdoc-title-page(config)
      if config.include-spine { spine-page(config) }
    } else {
      _graduate-cover(config)
      if config.include-spine { spine-page(config) }
      if config.thesis-type == "thesis" {
        clear-double-page(config, weak: true)
        _english-title-page(config)
      }
    }
  }

  (
    clear-page: clear-page,
    clear-double-page: clear-double-page,
    spine-page: spine-page,
    title-pages: title-pages,
  )
}
