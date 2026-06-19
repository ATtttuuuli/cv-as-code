# ============================================================
# CV AS CODE — Makefile
# Usage :
#   make build        → génère le PDF via Docker
#   make build-local  → génère le PDF localement (Pandoc + WeasyPrint requis)
#   make clean        → supprime les fichiers générés
# ============================================================

OUTPUT_DIR  := dist
PDF_NAME    := cv-ali-benali.pdf
HTML_NAME   := cv-ali-benali.html

SRC         := src/cv.md
TEMPLATE    := template/cv.html
CSS         := styles/cv.css

.PHONY: all build build-local clean docker-build

all: build

## Build via Docker (recommandé — reproductible sur toutes les machines)
build:
	@echo "→ Génération du PDF via Docker..."
	@mkdir -p $(OUTPUT_DIR)
	docker build -t cv-builder . && \
	docker run --rm -v "$$(pwd)/$(OUTPUT_DIR):/cv/$(OUTPUT_DIR)" cv-builder make build-local
	@echo "✓ PDF généré : $(OUTPUT_DIR)/$(PDF_NAME)"

## Build local (nécessite pandoc et weasyprint installés)
build-local:
	@echo "→ [1/2] Pandoc : Markdown → HTML intermédiaire..."
	@mkdir -p $(OUTPUT_DIR)
	pandoc $(SRC) \
		--template=$(TEMPLATE) \
		--standalone \
		--metadata-file=$(SRC) \
		-o $(OUTPUT_DIR)/$(HTML_NAME)

	@echo "→ [2/2] WeasyPrint : HTML → PDF..."
	weasyprint \
		--stylesheet=$(CSS) \
		$(OUTPUT_DIR)/$(HTML_NAME) \
		$(OUTPUT_DIR)/$(PDF_NAME)

	@echo "✓ PDF prêt : $(OUTPUT_DIR)/$(PDF_NAME)"

## Nettoyage
clean:
	@rm -rf $(OUTPUT_DIR)
	@echo "✓ dist/ supprimé"
