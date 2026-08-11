# Makefile for ThuThesis

PACKAGE = thuthesis
THESIS  = thuthesis-example

SOURCES = $(PACKAGE).ins $(PACKAGE).dtx
CLSFILE = dtx-style.sty $(PACKAGE).cls

LATEXMK = latexmk
SHELL  := /usr/bin/env bash
TEXMFDIST := $(shell kpsewhich -var-value=TEXMFDIST 2>/dev/null)
TYPST_FONT_ARGS ?= $(if $(TEXMFDIST),--ignore-system-fonts --font-path "$(TEXMFDIST)/fonts/opentype/public/tex-gyre" --font-path "$(TEXMFDIST)/fonts/opentype/public/fandol" --font-path "$(TEXMFDIST)/fonts/opentype/public/xits")

# make deletion work on Windows
ifdef SystemRoot
	RM = del /Q
else
	RM = rm -f
endif

.PHONY: all all-dev clean distclean dist thesis typst viewthesis doc viewdoc cls check save test FORCE_MAKE

thesis: $(THESIS).pdf

typst: build/typst/thuthesis-example.pdf

build/typst/thuthesis-example.pdf: thuthesis-example.typ lib.typ $(wildcard src/*.typ data/*.typ) ref/refs.bib $(wildcard assets/*.pdf figures/*.pdf)
	@mkdir -p $(@D)
	typst compile --root . $(TYPST_FONT_ARGS) $< $@

all: thesis

all-dev: doc all

cls: $(CLSFILE)

$(CLSFILE): $(SOURCES)
	xetex $(PACKAGE).ins

doc: $(PACKAGE).pdf

$(PACKAGE).pdf: cls FORCE_MAKE
	$(LATEXMK) $(PACKAGE).dtx

$(THESIS).pdf: cls FORCE_MAKE
	$(LATEXMK) $(THESIS)

viewdoc: doc
	$(LATEXMK) -pv $(PACKAGE).dtx

viewthesis: thesis
	$(LATEXMK) -pv $(THESIS)

save:
ifeq ($(target),)
	bash testfiles/save.sh
else
	bash testfiles/save.sh $(target)
endif

test:
ifeq ($(target),)
	l3build check
else
	bash testfiles/test.sh $(target)
endif

clean: compare-clean
	$(LATEXMK) -c $(PACKAGE).dtx $(THESIS)
	-@$(RM) -rf *~ main-survey.* main-translation.* _markdown_thuthesis* thuthesis.markdown.*

cleanall: clean
	-@$(RM) $(PACKAGE).pdf $(THESIS).pdf

distclean: cleanall
	-@$(RM) $(CLSFILE)
	-@$(RM) -r dist

check: FORCE_MAKE
ifeq ($(version),)
	@echo "Error: version missing: \"make [check|dist] version=X.Y.Z\""; exit 1
else
	@[[ $(shell grep -E -c '$(version) Tsinghua University Thesis Template|\\def\\version\{$(version)\}' thuthesis.dtx) -eq 3 ]] || (echo "bump version with \"l3build tag\" before release"; exit 1)
endif

dist: check all-dev
	# use l3build for CTAN release (zip with .tds.zip)
	l3build ctan --config utils/build-ctan
	# use gulp for GitHub release (zip with generated file)
	python3 utils/create_release.py --version="v$(version)"

include mk/compare.mk
