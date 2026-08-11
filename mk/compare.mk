# Visual comparison matrix for the LaTeX and Typst implementations.

COMPARE_DIR       := build/compare
COMPARE_LATEX_DIR := $(COMPARE_DIR)/latex
COMPARE_TYPST_DIR := $(COMPARE_DIR)/typst

COMPARE_CASES := \
	bachelor-chinese \
	bachelor-english \
	master-academic-chinese \
	master-academic-english \
	master-professional-chinese \
	master-proposal-chinese \
	doctor-print-chinese \
	doctor-professional-english \
	doctor-schwarzman-chinese \
	postdoc-chinese

COMPARE_SPEC.bachelor-chinese := bachelor chinese electronic academic thesis none
COMPARE_SPEC.bachelor-english := bachelor english electronic academic thesis none
COMPARE_SPEC.master-academic-chinese := master chinese electronic academic thesis none
COMPARE_SPEC.master-academic-english := master english electronic academic thesis none
COMPARE_SPEC.master-professional-chinese := master chinese electronic professional thesis none
COMPARE_SPEC.master-proposal-chinese := master chinese electronic academic proposal none
COMPARE_SPEC.doctor-print-chinese := doctor chinese print academic thesis none
COMPARE_SPEC.doctor-professional-english := doctor english electronic professional thesis none
COMPARE_SPEC.doctor-schwarzman-chinese := doctor chinese electronic academic thesis schwarzman
COMPARE_SPEC.postdoc-chinese := postdoc chinese electronic academic thesis none

COMPARE_LATEX_PDFS := $(addprefix $(COMPARE_LATEX_DIR)/,$(addsuffix .pdf,$(COMPARE_CASES)))
COMPARE_TYPST_PDFS := $(addprefix $(COMPARE_TYPST_DIR)/,$(addsuffix .pdf,$(COMPARE_CASES)))
COMPARE_PDFS       := $(addprefix $(COMPARE_DIR)/,$(addsuffix .pdf,$(COMPARE_CASES)))

.PHONY: compare compare-clean

compare: $(COMPARE_PDFS)

$(COMPARE_LATEX_DIR) $(COMPARE_TYPST_DIR):
	@mkdir -p $@

$(COMPARE_LATEX_PDFS): $(COMPARE_LATEX_DIR)/%.pdf: mk/compare.tex mk/compare.mk $(CLSFILE) | $(COMPARE_LATEX_DIR)
	@read -r degree language output degree_type thesis_type style_override <<< "$(COMPARE_SPEC.$*)"; \
	input="\\PassOptionsToClass{degree=$$degree,degree-type=$$degree_type,language=$$language,thesis-type=$$thesis_type,style-override=$$style_override,fontset=fandol}{thuthesis}\\def\\CompareOutput{$$output}\\input{mk/compare.tex}"; \
	for pass in 1 2; do \
		xelatex -halt-on-error -interaction=batchmode -file-line-error \
		-output-directory="$(abspath $(COMPARE_LATEX_DIR))" -jobname="$*" "$$input" || exit; \
	done; \
	$(RM) $(COMPARE_LATEX_DIR)/$*.aux $(COMPARE_LATEX_DIR)/$*.log $(COMPARE_LATEX_DIR)/$*.toc $(COMPARE_LATEX_DIR)/$*.out

$(COMPARE_TYPST_PDFS): $(COMPARE_TYPST_DIR)/%.pdf: mk/compare.typ mk/compare.mk lib.typ $(wildcard src/*.typ) | $(COMPARE_TYPST_DIR)
	@read -r degree language output degree_type thesis_type style_override <<< "$(COMPARE_SPEC.$*)"; \
	typst compile --root . $(TYPST_FONT_ARGS) \
	--input degree="$$degree" \
	--input language="$$language" \
	--input output="$$output" \
	--input degree-type="$$degree_type" \
	--input thesis-type="$$thesis_type" \
	--input style-override="$$style_override" \
	mk/compare.typ "$@"

$(COMPARE_PDFS): $(COMPARE_DIR)/%.pdf: $(COMPARE_TYPST_DIR)/%.pdf $(COMPARE_LATEX_DIR)/%.pdf testfiles/overlay-pdfs.py
	python3 testfiles/overlay-pdfs.py $< $(word 2,$^) $@

compare-clean:
	-@$(RM) -r $(COMPARE_DIR)
