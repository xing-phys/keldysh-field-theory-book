# Keldysh Field Theory

**A working introduction to driven open quantum matter**

[Read the book](https://xing-phys.github.io/keldysh-field-theory-book/) · [Download PDF](https://xing-phys.github.io/keldysh-field-theory-book/keldysh-field-theory.pdf) · [Review](https://doi.org/10.1088/0034-4885/79/9/096001)

A self-contained teaching companion to Sieberer, Buchhold, and Diehl (2016), aimed at beginning graduate students and advanced undergraduates. It develops density matrices and coherent states before the contour construction, then treats symmetry, functional RG, cavity spin models and glasses, driven condensation, KPZ phase fluctuations, and universal heating. It includes intermediate derivations, worked problems, original figures, and standard-library Julia calculations.

The book is original expository writing, prepared with AI assistance for Ze-Yu Xing. It is independent of the review's authors and publisher. It has not received a full independent expert scientific review. Approximation and model limitations are stated in the chapters; software checks verify rendering, references, and selected calculations.

## Build locally

Use **Quarto 1.10.18**, a working **XeLaTeX/TeX Live** installation, and the **TeX Gyre Pagella**, **TeX Gyre Heros**, and **DejaVu Sans Mono** fonts. Quarto can install TinyTeX with `quarto install tinytex`. On Ubuntu, system fonts are available through `fonts-texgyre` and `fonts-dejavu-core`.

```sh
quarto render                          # Multi-page HTML and combined PDF
python3 scripts/check_book.py          # Citations, labels, local links, assets
quarto preview --to html --no-browser  # The terminal prints the local URL
```

The output is `_site/index.html` and `_site/keldysh-field-theory.pdf`. The PDF download is available in the book sidebar and on the welcome page. A preview is local; publishing happens through the workflow described below. There is no need for Python packages, Jupyter, or an external plotting package to render this book.

## Reproduce the figures

The rendered figure assets are committed so ordinary builds need no plotting tool. To regenerate them, use **Julia 1.10 or later**, **Python 3**, and **Inkscape**:

```sh
julia --startup-file=no scripts/build_figures.jl
python3 scripts/build_schematics.py
python3 scripts/export_figures.py
quarto render
python3 scripts/check_book.py
```

Julia uses only `LinearAlgebra`, `Printf`, and `DelimitedFiles`. The scientific examples check an independent birth-death cavity solution, the Dicke stability threshold, a Fourier-mode phase covariance, and an exact finite-dimensional dephasing Liouvillian. The KPZ crossover plot evaluates a stated one-loop formula; it is not a numerical KPZ simulation. Data and check results are in `data/`; figures are in `figs/` as SVG, PDF, and PNG. The precise Julia version is recorded in `data/checks.txt`.

## Source layout

- `index.qmd`, `00-*.qmd`–`13-*.qmd`: welcome and teaching chapters.
- `a-mathematics.qmd`, `b-conventions.qmd`, `c-review-map.qmd`, `d-worked-integrals.qmd`: mathematical tools, conventions, section-by-section review coverage, and worked loop/integral calculations.
- `assets/bibliography.bib`: verified paper metadata; `assets/*-refs.bib` record the editorial source groups.
- `assets/macros.sty` and `assets/mathjax-config.html`: equivalent PDF/HTML physics macros.
- `_quarto.yml`, `assets/styles.css`, and theme files: book structure and appearance.
- `scripts/`: reproducible figures and link/reference verification.
- `.github/workflows/publish.yml`: numerical checks, HTML/PDF build, verification, and GitHub Pages deployment.

Do not run a full render concurrently with a preview in the same checkout. Use a separate copy for independent build verification.

## Publishing and version control

The `main` branch contains source and reproducible assets; `_site/` and `.quarto/` are ignored. Pushes to `main` run the build and automatically deploy its result to GitHub Pages using the `github-pages` environment. Pull requests build the same book and upload a preview artifact without deploying. Pages must use **GitHub Actions** as the publishing source. No personal access token is stored in the repository; deployment uses the workflow's scoped `GITHUB_TOKEN` and OIDC permissions.

```sh
git add .
git commit -m "Describe the scientific or editorial change"
git push origin main
```

The site is https://xing-phys.github.io/keldysh-field-theory-book/ . Check the Actions tab for the deployment result after a push.

## Attribution and corrections

Original text, figures, and data are CC BY 4.0; scripts and workflow code are MIT. See [LICENSE](LICENSE). Papers remain separately copyrighted. No published-paper figures are redistributed. Please report a scientific correction with the chapter, equation label, assumptions, and proposed replacement; report a rendering issue with the page URL and browser.
