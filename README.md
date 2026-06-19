# CV As Code — Ali BENALI

> **Bachelor 2 Informatique — Ynov Campus Lyon**
> Projet Vibe Coding : pipeline de génération automatisée de CV

---

## Compilation locale (TL;DR)

**Prérequis :** Docker installé et démarré.

```bash
git clone https://github.com/<votre-username>/cv-as-code.git
cd cv-as-code
make build
```

Le PDF est généré dans `dist/cv-ali-benali.pdf`.

### Sans Docker (si Pandoc + WeasyPrint sont installés en local)

```bash
# Installer WeasyPrint
pip install weasyprint==62.3

# Générer le PDF directement
make build-local
```

---

## Structure du projet

```
cv-as-code/
├── src/
│   └── cv.md                  # Contenu du CV (Markdown pur, zéro style)
├── template/
│   └── cv.html                # Template HTML Pandoc (structure)
├── styles/
│   └── cv.css                 # Feuille de style dédiée à l'impression
├── .github/
│   └── workflows/
│       └── build-cv.yml       # CI/CD GitHub Actions
├── Dockerfile                 # Environnement de build isolé
├── Makefile                   # Pipeline en une commande
└── README.md
```

**Séparation stricte contenu / structure / présentation :**
- `src/cv.md` — données brutes, aucune balise HTML, aucun style
- `template/cv.html` — squelette structurel, aucune information de contenu
- `styles/cv.css` — 100% de la présentation, variables CSS, règles `@page`

---

## Arsenal IA utilisé

| Outil | Usage |
|---|---|
| **Claude (claude.ai)** | Génération de l'architecture globale, CSS WeasyPrint, Makefile, GitHub Actions |
| **GitHub Copilot** | Autocomplétion lors de l'écriture du Makefile et du workflow YAML |

LLM principal : **Claude Sonnet 4.6** (claude.ai, interface web)

---

## Ingénierie de Prompt

### Prompt CSS & Print

Le point critique était de forcer WeasyPrint à respecter les règles d'impression. WeasyPrint est un moteur CSS headless — il ignore les media queries `@media screen` et ne supporte pas toutes les propriétés CSS3. Les prompts qui ont donné les meilleurs résultats :

> *"Génère une feuille de style CSS pour WeasyPrint (pas un navigateur). Utilise uniquement des règles compatibles avec le rendu paged media CSS : `@page`, `page-break-inside: avoid`, `orphans`, `widows`. Utilise des variables CSS `--var`. Zéro style inline. Le rendu cible est un PDF A4."*

> *"WeasyPrint ignore `display: flex` dans certains contextes d'impression. Pour l'en-tête avec deux colonnes, utilise `display: flex` mais prévois un fallback avec `float` si le rendu est cassé."*

### Prompt GitHub Actions

> *"Génère un workflow GitHub Actions pour Ubuntu latest. La chaîne de compilation est : Pandoc (apt) → WeasyPrint (pip). Le PDF final doit être uploadé comme artifact avec `actions/upload-artifact@v4`. Si le push est un tag, créer une Release GitHub avec le PDF en pièce jointe."*

### Prompt Dockerfile

> *"Génère un Dockerfile basé sur python:3.12-slim qui installe Pandoc via apt et WeasyPrint via pip. L'image doit être reproductible sur x86_64 et ARM64 (notamment Mac M1/M2). Liste explicitement toutes les dépendances graphiques de WeasyPrint (pango, cairo, gdk-pixbuf)."*

---

## Analyse Critique & Débogage

### 1. Problème : WeasyPrint et `display: flex` en header

**Symptôme :** L'en-tête du CV s'affichait en une seule colonne au lieu de deux. WeasyPrint 62.x supporte Flexbox mais avec des limitations sur `align-items: flex-end` dans certains contextes paginés.

**Solution :** Passage à `justify-content: space-between` seul, suppression de `align-items` qui causait le problème. Testé en itérant avec le prompt :
> *"Le flex ne fonctionne pas avec align-items en WeasyPrint. Propose une alternative CSS qui donne le même résultat visuel en paged media."*

### 2. Problème : Variables Pandoc non résolues dans le template

**Symptôme :** Le template affichait `$name$` littéralement au lieu de la valeur du frontmatter YAML.

**Cause :** L'IA avait généré `--metadata title="..."` en argument Pandoc au lieu de lire les variables depuis le frontmatter YAML du fichier source.

**Solution :** Suppression du `--metadata-file` redondant dans le Makefile. Pandoc lit nativement le frontmatter YAML du `.md` et injecte les variables dans le template `$variable$`.

### 3. Problème : PDF généré en local mais pas en CI

**Symptôme :** La GitHub Action échouait sur `weasyprint: command not found`.

**Cause :** L'IA avait oublié d'ajouter `pip install` dans le step CI, supposant que WeasyPrint était disponible nativement sur `ubuntu-latest`.

**Solution :** Ajout d'un step dédié `pip install weasyprint==62.3` avec version épinglée pour la reproductibilité.

### 4. Hallucination : dépendances WeasyPrint incomplètes

**Symptôme :** Sur une Ubuntu fraîche, WeasyPrint crashait avec `OSError: cannot load library 'libgobject-2.0-0'`.

**Cause :** L'IA avait listé les bibliothèques principales mais pas `libgdk-pixbuf2.0-0` et `libpangoft2-1.0-0` qui sont des dépendances transverses nécessaires pour le rendu des fontes.

**Solution :** Test sur un container Docker vierge + ajout manuel des dépendances manquantes après lecture de la documentation officielle WeasyPrint.

---

## CI/CD

À chaque `push` sur `main` :
1. GitHub Actions installe Pandoc + WeasyPrint sur `ubuntu-latest`
2. `make build-local` compile `src/cv.md` → `dist/cv-ali-benali.pdf`
3. Le PDF est uploadé comme **artifact** (accessible 30 jours)
4. Sur un push tagué (`git tag v1.0.0`), une **GitHub Release** est créée avec le PDF en pièce jointe

Le PDF n'est **jamais** présent dans le dépôt Git (`.gitignore` strict).
