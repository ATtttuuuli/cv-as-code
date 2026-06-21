# ============================================================
# CV AS CODE — Makefile
# ============================================================

OUTPUT_DIR  := dist
PDF_NAME    := cv-ali-atrouche.pdf
HTML_NAME   := cv-ali-atrouche.html

SRC         := src/cv.md
TEMPLATE    := template/cv.html
CSS         := styles/cv.css

.PHONY: all build build-local clean

all: build

build:
	@echo "→ Génération du PDF via Docker..."
	@mkdir -p $(OUTPUT_DIR)
	docker build -t cv-builder . && \
	docker run --rm -v "$$(pwd)/$(OUTPUT_DIR):/cv/$(OUTPUT_DIR)" cv-builder make build-local
	@echo "✓ PDF généré : $(OUTPUT_DIR)/$(PDF_NAME)"

build-local:
	@echo "→ [1/2] Pandoc : Markdown → HTML intermédiaire..."
	@mkdir -p $(OUTPUT_DIR)
	pandoc $(SRC) \
		--template=./$(TEMPLATE) \
		--standalone \
		-t html5 \
		-o $(OUTPUT_DIR)/$(HTML_NAME)
	@echo "→ [2/2] WeasyPrint : HTML → PDF..."
	weasyprint \
		$(OUTPUT_DIR)/$(HTML_NAME) \
		$(OUTPUT_DIR)/$(PDF_NAME)
	@echo "✓ PDF prêt : $(OUTPUT_DIR)/$(PDF_NAME)"

clean:
	@rm -rf $(OUTPUT_DIR)
	@echo "✓ dist/ supprimé"