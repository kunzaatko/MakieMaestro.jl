# Changelog

## [0.8.1] - 2026-11-22

### 🐛 Bug Fixes

- *(release)* Correct version in bump status message by @kunzaatko

- *(export)* [**breaking**] Correct cache digests and logger dispatch by @kunzaatko


## [0.8.0] - 2026-11-20

### 🚀 Features

- *(test)* When failed parsing, see the arguments that where passed by @kunzaatko

- *(logger)* Add entry lookup interface for figure loggers by @kunzaatko

- *(export)* Cache rendered figures by content digest by @kunzaatko


### 🐛 Bug Fixes

- *(test)* Hashing changes and CompatHelperLocal compatibility by @kunzaatko

- *(docs)* Escape underscore in dev docs to show link by @kunzaatko

- *(test)* Parsing fails for empty arguments by @kunzaatko

- *(docs)* Admonition formatting by @kunzaatko

- *(docs)* Wrong reference by @kunzaatko

- *(precompilation)* Avoid registering Unitful units during precompile by @kunzaatko

- *(precompilation)* Skip backend activation during precompile by @kunzaatko


### 💼 Other

- Configure project workspace and Julia compatibility by @kunzaatko


### 🚜 Refactor

- *(rename)* Paper sizes rename `_TRUE` -> `_ISO216` for clarity by @kunzaatko


### 📚 Documentation

- Reword sentences in the docs and add functions to the reference by @kunzaatko

- Add some main features and start dev docs by @kunzaatko


### 🎨 Styling

- Add comments, add/rm empty lines by @kunzaatko

- Reorder imports and exports consistently by @kunzaatko


### 🧪 Testing

- Check persistent tasks on Julia 1.11 and later by @kunzaatko


### ⚙️ Miscellaneous Tasks

- Some stylistic modification and link to Documenter docs through `@extref` by @kunzaatko

- *(docs)* Add some comments into the code by @kunzaatko

- *(deps)* Manage Julia updates with Dependabot by @kunzaatko

- Add just recipes for Julia project workflows by @kunzaatko

- *(release)* Add changelog and registration recipes by @kunzaatko


## [0.7.0] - 2025-11-26

### 🚀 Features

- Add `uniqueids` and `uniqueid` functions for FunctionSpec for caching figures by @kunzaatko

- *(logger)* Implementing a basic logger for the figure exporting by @kunzaatko

- *(docs)* Add favicon to documentation by @kunzaatko


### 🐛 Bug Fixes

- Remove the false note in the inter links by @kunzaatko

- Unique ID by using `code_string` on the function by @kunzaatko

- Fix the `uniqueid` function and add tests for it by @kunzaatko

- Add teardown code to doctest where I set `figure_dir!` by @kunzaatko

- *(docs)* Missing period in savefigs docs by @kunzaatko

- *(compat+docs)* Undefined bindings and compat entries for InteractiveUtils by @kunzaatko

- IdSet is exported in Julia 1.11 and later only by @kunzaatko

- *(logging)* `inline_tables` supported only in julia 1.11 and later by @kunzaatko

- *(docs)* Docstring for `L` has to be `raw` by @kunzaatko

- Logging with inline tables preserved by @kunzaatko

- *(CI)* Use `latest` for `buildpkg` action to futureproof by @kunzaatko


### 🚜 Refactor

- Add the argument cascade into its own file by @kunzaatko


### 📚 Documentation

- Improve the docstrings for `savefig` by @kunzaatko

- Improve the docstring of `PathSpec` by @kunzaatko

- Add docstrings to paper sizes by @kunzaatko

- Add paper-sizes documentation and tip admonition by @kunzaatko

- Do not show the logs when saving the figures in `savefig.md` by @kunzaatko

- Do not link axes in the graphs figure by @kunzaatko

- Do not plot the triangle by @kunzaatko

- Rephrase the ISO 216 standard comment by @kunzaatko

- *(logging)* Add logging API to documentation by @kunzaatko

- *(documenter)* Add a few tips and comments to the documenter docs by @kunzaatko

- Reorder the blocks in the documenter page by @kunzaatko

- Add ticks around `MakieMaestro` consistently by @kunzaatko

- Clarify Documenter workflow and modify (shorten) external links by @kunzaatko


### 🧪 Testing

- Better structure for `savefig` tests by @kunzaatko

- Add alias `MM` as MakieMaestro to doctestsetup.jl by @kunzaatko

- *(logging)* Add some basic tests for logging by @kunzaatko


### ⚙️ Miscellaneous Tasks

- *(git)* Add the cached docs to gitignore by @kunzaatko

- *(git)* Remove `docs/src/assets` from gitignore by @kunzaatko

- *(compat)* Update CodeTracking compatibility to new version by @kunzaatko

- *(release)* Bump minor version by @kunzaatko


## [0.6.1] - 2025-08-13

### 🚀 Features

- Cache the docs for continual viewing in the browser by @kunzaatko


### 🚜 Refactor

- *(docs)* Use keyword arguments for MakieDocBlocks instantiation by @kunzaatko


### 📚 Documentation

- Add tip on using the png format for images by @kunzaatko


### ⚙️ Miscellaneous Tasks

- Todo comments by @kunzaatko

- Bump patch version by @kunzaatko


## [0.6.0] - 2025-08-13

### 🚀 Features

- *(documenter)* Add options parsing to the `DocumenterExt` for `Makie` and test rigorously by @kunzaatko


### 🐛 Bug Fixes

- *(mosaic)* Fix method dispatch and missing `!` by @kunzaatko

- *(test)* Add `LINES` and `COLUMNS` environment variables to `doctestsetup.jl` by @kunzaatko

- *(documenter)* Fix the `repr(size)` issue where the `show` was not parse-able and `theme` -> `override_theme` by @kunzaatko

- *(tests)* Earlier versions to not have `Fix{N}` by @kunzaatko

- *(mosaic)* Bad use of non `!` method by @kunzaatko

- *(documenter)* Add a prefix to all logs generated when running the makie code by @kunzaatko

- *(docs)* Side by side comparison in savefig by @kunzaatko

- *(docs)* Size of the figures in `mosaic.md` by @kunzaatko


### 📚 Documentation

- Add a skeleton for the `mosaic` docs page by @kunzaatko

- Enhance documenter plugin docs, add advanced usage section with option description by @kunzaatko

- Add better docs for the DocumenterExt workflow and document the `mosaic` in Ensemble Recipes by @kunzaatko

- Add warning about `png` format in documenter workflow by @kunzaatko

- Remove the logs clutter and do not show the side-by-side by @kunzaatko


### ⚙️ Miscellaneous Tasks

- *(git)* Add log files to .gitignore by @kunzaatko

- Add fix comment by @kunzaatko

- Bump minor version by @kunzaatko


## [0.5.0] - 2025-08-01

### 🚀 Features

- *(CI)* Configure CI to run on new commits on ready for review PR by @kunzaatko

- *(CI)* Julia versions "pre", "lts" and "min" in matrix by @kunzaatko

- Better signature and implementation for mosaic by @kunzaatko

- Use AbstractDict instead of Dict for pluto workflow by @kunzaatko

- Method for mosaic to accept a grid position by @kunzaatko


### 🐛 Bug Fixes

- *(compat)* [**breaking**] Rm MakieExtra dependency and leaner compat entries by @kunzaatko

- *(test)* Fix the offending doctests by @kunzaatko

- *(docs)* Fix the location of figures with the plugin by @kunzaatko

- *(compat)* [**breaking**] Julia 1.10 compat restriction by Makie by @kunzaatko

- Removed method from Makie causes issue in `image` recipe by @kunzaatko

- Create `ax_inds` in mosaic when `nrows` and `ncols` are set by @kunzaatko

- *(docs)* Typo in index.md by @kunzaatko

- *(docs)* Docstring of `with_backend` by @kunzaatko

- *(docs)* Update the url to Unitful.jl documentation by @kunzaatko


### 💼 Other

- *(docs)* DocumenterInterLinks link to Makie documentation by @kunzaatko

- *(compat)* CompatHelper: bump compat for CairoMakie to 0.15, (keep existing compat)

- *(compat)* CompatHelper: bump compat for WGLMakie to 0.13, (keep existing compat)


### 🚜 Refactor

- *(documenter)* [**breaking**] Rename `docblocks` function to `MakieDocBlocks` by @kunzaatko


### 📚 Documentation

- *(CI)* Add comments about the necessity of DISPLAY in CI by @kunzaatko

- *(documenter)* Specify some tips and warnings about using the Documenter plugin by @kunzaatko

- *(make)* Explicitly use the plugin and remove doctesting by @kunzaatko

- *(documenter)* Add instructions for running in the CI by @kunzaatko


### 🧪 Testing

- Separate tests into files and cond testing by @kunzaatko


### ⚙️ Miscellaneous Tasks

- *(git)* Add .tasks to gitignore by @kunzaatko

- Update source of MakieMaestro.jl package by @kunzaatko

- Bump minor version by @kunzaatko


## [0.3.1] - 2025-06-29

### 🚀 Features

- *(CI)* Test on 1.12 beta in Github Actions by @kunzaatko


### 🐛 Bug Fixes

- *(compat)* Do not specify compat for MarkdownAST by @kunzaatko


### 💼 Other

- *(compat)* CompatHelper: bump compat for GLMakie to 0.13, (keep existing compat)


## [0.3.0] - 2025-05-08

### 🚀 Features

- *(docs)* Implement the Documenter plugin as an extension and document it by @kunzaatko

- *(documenter)* Named @makie blocks, docs and tests by @kunzaatko

- Bump version to 0.3.0 by @kunzaatko


### 🐛 Bug Fixes

- *(CI)* Export what MakieExtra does not export from Makie by @kunzaatko

- *(CI)* WGLMakie not compiling in `pre` Julia by @kunzaatko

- *(compat)* Ignore assets in documentation and fix compat by @kunzaatko

- *(documenter)* Relative path to source in the `LocalImage` structure by @kunzaatko

- Remove unecessary dependencies by @kunzaatko

- *(documenter)* Directory of build and reference for figures by @kunzaatko

- *(docs)* Documentation of the Documenter plugin by @kunzaatko

- *(DocumenterExt)* Correct typo and improve regex for Makie block options by @kunzaatko


### 💼 Other

- \pm function shortcut for selecting a window of indices around a point by @kunzaatko


### 🚜 Refactor

- *(theme)* Reorganize constants and add ISO paper sizes by @kunzaatko


### 📚 Documentation

- Add LaTeX layout guide for figure sizing by @kunzaatko

- Add font size guidance for LaTeX document classes by @kunzaatko


### ⚙️ Miscellaneous Tasks

- *(CI)* Change CompatHelper.yml workflow to run only every two weeks by @kunzaatko


## [0.2.0] - 2025-01-31

### 🚀 Features

- *(docs)* Add DocumenterInterLinks for cross-documentation references by @kunzaatko

- Add coverage badge to README by @kunzaatko

- *(formats)* Add format parsing and default format management by @kunzaatko

- *(export)* [**breaking**] Improve struct documentation and display methods by @kunzaatko


### 🐛 Bug Fixes

- *(docs)* Improve savefig documentation and cross-references by @kunzaatko

- *(export)* [**breaking**] Improve error handling for argument confusion by @kunzaatko

- *(export)* Improve error handling and documentation by @kunzaatko


### 🚜 Refactor

- *(export)* [**breaking**] Reorganize figure saving functionality by @kunzaatko

- [**breaking**] Rename HeightLength to FigHeight and export_formats to export_format by @kunzaatko

- *(export)* [**breaking**] Simplify format handling and improve API by @kunzaatko


### 📚 Documentation

- *(save-fig)* Add documentation for internal save functions by @kunzaatko

- *(savefig)* Add detailed argument documentation and examples by @kunzaatko


### 🧪 Testing

- Skip PDF path test in GitHub Actions CI by @kunzaatko


### ⚙️ Miscellaneous Tasks

- *(version)* Bump minor version by @kunzaatko


## [0.1.0] - 2025-01-17

### 🚀 Features

- Auto-select appropriate Makie backend based on environment by @kunzaatko

- *(test)* Add doctest fixing script by @kunzaatko


### 🐛 Bug Fixes

- *(CI)* Headless rendering in CI by @kunzaatko

- *(CI)* Fix compat and remove MacOS from CI matrix by @kunzaatko

- *(CI)* `make.jl` docs run within the `docs/` project by @kunzaatko

- *(docs)* Workflow markdown formatting by @kunzaatko

- *(docs)* Include missing doc strings in the documentation by @kunzaatko

- Merge order in the merge_generate function of themes by @kunzaatko

- *(themes)* Implement proper theme comparison functionality by @kunzaatko

- *(tests)* Synchronize doctest setup between docs and tests by @kunzaatko

- [**breaking**] Theming when saving a figure (#3) by @kunzaatko in #3

- *(CI)* Commit message for CompatHelper by @kunzaatko

- *(compat)* Better SemVer compatibility versions by @kunzaatko

- *(CI)* Release needs file argument by @kunzaatko


### 💼 Other

- *(CI)* Doctests are run in the testing by @kunzaatko

- Bump compat for ColorTypes to 0.12, (keep existing compat)

- Small fixes and todo comments by @kunzaatko

- Logo to README and documentation by @kunzaatko

- *(test)* Doctests and documentation by @kunzaatko

- Cache generation for the figures by @kunzaatko

- Move the theming module around and minor improvements by @kunzaatko

- *(test)* Tests for merge_generate by @kunzaatko

- *(docs)* Remove index and autodocs from the index by @kunzaatko

- *(compat)* Bump compat for GLMakie to 0.11, (keep existing compat) (#8) by @github-actions[bot] in #8

- *(compat)* Bump compat for WGLMakie to 0.11, (keep existing compat) (#7) by @github-actions[bot] in #7

- *(compat)* Bump compat for CairoMakie to 0.13, (keep existing compat) (#5) by @github-actions[bot] in #5

- *(compat)* Bump compat for Makie to 0.22, (keep existing compat) (#6) by @github-actions[bot] in #6

- *(test)* Test for missing compat versions locally by @kunzaatko

- *(CI)* Cliff.toml for Changelog generation by @kunzaatko


### 🚜 Refactor

- Move exports closer to their implementations by @kunzaatko


### 📚 Documentation

- Improve function documentation and add doctests by @kunzaatko

- Reorganize API reference documentation structure by @kunzaatko


### ⚙️ Miscellaneous Tasks

- Bump the minor version since this is breaking to the merge arguments by @kunzaatko

- Lighten the compat version restriction of ColorTypes by @kunzaatko



