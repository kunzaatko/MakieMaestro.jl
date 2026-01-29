```@meta
CurrentModule=MakieMaestro
CollapsedDocStrings=true
```

# User Public API Documentation

Documentation for `MakieMaestro`'s public interface.

```@contents
Pages = ["reference.md"]
Depth = 1:2
```

# Exporting

For a deeper overview of how to export figures while ensuring consistent style and sizing, see the section on [Exporting
    publication figures](@ref exporting_figures).

```@docs
savefig
figure_dir!
export_format!
```

```@raw html
<details><summary>Internals</summary>
```
```@docs
MakieMaestro.isvectorgraphic
MakieMaestro.skip
MakieMaestro.extension
MakieMaestro.choose_backend
MakieMaestro.backend_formats

MakieMaestro.get_figure_dir
MakieMaestro.get_themes
MakieMaestro.get_export_theme
MakieMaestro.get_formats
MakieMaestro.get_export_format

MakieMaestro.FunctionSpec
MakieMaestro.uniqueid
MakieMaestro.uniqueids

MakieMaestro.PathSpec

MakieMaestro.SizeSpec
MakieMaestro.RelativeSize
MakieMaestro.FigHeight

MakieMaestro._savefig
MakieMaestro._savepdftex
```
```@raw html
</details>
```

## Logging

```@raw html
<details><summary>Internals</summary>
```
```@docs
MakieMaestro.create_logger

MakieMaestro.FigureLogger
MakieMaestro.add_entry(::FigureLogger, ::String, ::AbstractDict; kwargs...)

MakieMaestro.TOMLLogger
MakieMaestro.add_entry(::TOMLLogger, ::String, ::AbstractDict; kwargs...)
MakieMaestro.logs_path(::TOMLLogger)
MakieMaestro.inlineids

MakieMaestro.NullLogger

MakieMaestro.InlineDict
```
```@raw html
</details>
```

# Workflows

## `Documenter.jl` Plugin
For an extensive overview of how you can use the `Documenter.jl` plugin and the documentation workflow, take a look at
    the [dedicated workflow page](@ref workflows-documenter).
```@docs
MakieMaestro.MakieDocBlocks
```

## `Pluto.jl`
For an extensive overview of how to use this, see the [Pluto.jl workflow page](@ref pluto_workflow).

```@docs
MakieMaestro.with_backend
```

# Theming

```@docs
MakieMaestro.Themes
```

```@docs
MakieMaestro.Themes.width!
MakieMaestro.Themes.hwratio!
MakieMaestro.Themes.update_theme
MakieMaestro.Themes.update_theme!
MakieMaestro.Themes.get_theme
MakieMaestro.Themes.theme_keys
```

```@raw html
<details><summary>Internals</summary>
```
```@docs
MakieMaestro.Themes.ThemeGenerator
MakieMaestro.Themes.gen
MakieMaestro.Themes.merge_generate

MakieMaestro.Themes.get_hwratio
MakieMaestro.Themes.get_width
MakieMaestro.Themes.to_units
MakieMaestro.Themes.figsize

MakieMaestro.Themes.ScreenInfo
MakieMaestro.Themes.interactive_size!
MakieMaestro.Themes.get_interactive_size
MakieMaestro.Themes.screen_parameters
```
```@raw html
</details>
```

## Paper Sizes

!!! warning "ISO 216 standard"
    The standard under ISO 216 is to define the paper size of `{A/B/C}{1-X}` paper to be the size when the paper with an
    index one lower is folded in half. This means that with an increasing index we alternate between the width > height
    and width < height, or, loosely speaking, "landscape" and "portrait" orientation. If you truly want to use the
    standard, then the constants `{A/B/C}{1-X}_{WIDTH/HEIGHT}_TRUE` are the ones that you should use. If like any other
    sane person, you view the width as the left to right span of the paper, when oriented _vertically_ you should use
    the constants `{A/B/C}{1-X}_{WIDTH/HEIGHT}` instead.
    ```@example
    using MakieMaestro # hide
    using MakieMaestro.Themes
    @assert Themes.A0_WIDTH == Themes.A1_HEIGHT
    @assert Themes.A2_HEIGHT_TRUE == Themes.A1_WIDTH_TRUE # weird
    ```

```@raw html
<details><summary>Paper Size Constants</summary>
```
```@docs
MakieMaestro.Themes.A0_WIDTH
MakieMaestro.Themes.A0_WIDTH_TRUE
MakieMaestro.Themes.A0_HEIGHT
MakieMaestro.Themes.A0_HEIGHT_TRUE
MakieMaestro.Themes.A1_WIDTH
MakieMaestro.Themes.A1_WIDTH_TRUE
MakieMaestro.Themes.A1_HEIGHT
MakieMaestro.Themes.A1_HEIGHT_TRUE
MakieMaestro.Themes.A2_WIDTH
MakieMaestro.Themes.A2_WIDTH_TRUE
MakieMaestro.Themes.A2_HEIGHT
MakieMaestro.Themes.A2_HEIGHT_TRUE
MakieMaestro.Themes.A3_WIDTH
MakieMaestro.Themes.A3_WIDTH_TRUE
MakieMaestro.Themes.A3_HEIGHT
MakieMaestro.Themes.A3_HEIGHT_TRUE
MakieMaestro.Themes.A4_WIDTH
MakieMaestro.Themes.A4_WIDTH_TRUE
MakieMaestro.Themes.A4_HEIGHT
MakieMaestro.Themes.A4_HEIGHT_TRUE
MakieMaestro.Themes.A5_WIDTH
MakieMaestro.Themes.A5_WIDTH_TRUE
MakieMaestro.Themes.A5_HEIGHT
MakieMaestro.Themes.A5_HEIGHT_TRUE
MakieMaestro.Themes.A6_WIDTH
MakieMaestro.Themes.A6_WIDTH_TRUE
MakieMaestro.Themes.A6_HEIGHT
MakieMaestro.Themes.A6_HEIGHT_TRUE
MakieMaestro.Themes.A7_WIDTH
MakieMaestro.Themes.A7_WIDTH_TRUE
MakieMaestro.Themes.A7_HEIGHT
MakieMaestro.Themes.A7_HEIGHT_TRUE
MakieMaestro.Themes.A8_WIDTH
MakieMaestro.Themes.A8_WIDTH_TRUE
MakieMaestro.Themes.A8_HEIGHT
MakieMaestro.Themes.A8_HEIGHT_TRUE
MakieMaestro.Themes.A9_WIDTH
MakieMaestro.Themes.A9_WIDTH_TRUE
MakieMaestro.Themes.A9_HEIGHT
MakieMaestro.Themes.A9_HEIGHT_TRUE
MakieMaestro.Themes.A10_WIDTH
MakieMaestro.Themes.A10_WIDTH_TRUE
MakieMaestro.Themes.A10_HEIGHT
MakieMaestro.Themes.A10_HEIGHT_TRUE
MakieMaestro.Themes.A11_WIDTH
MakieMaestro.Themes.A11_WIDTH_TRUE
MakieMaestro.Themes.A11_HEIGHT
MakieMaestro.Themes.A11_HEIGHT_TRUE
MakieMaestro.Themes.A12_WIDTH
MakieMaestro.Themes.A12_WIDTH_TRUE
MakieMaestro.Themes.A12_HEIGHT
MakieMaestro.Themes.A12_HEIGHT_TRUE
MakieMaestro.Themes.A13_WIDTH
MakieMaestro.Themes.A13_WIDTH_TRUE
MakieMaestro.Themes.A13_HEIGHT
MakieMaestro.Themes.A13_HEIGHT_TRUE

MakieMaestro.Themes.B0_WIDTH
MakieMaestro.Themes.B0_WIDTH_TRUE
MakieMaestro.Themes.B0_HEIGHT
MakieMaestro.Themes.B0_HEIGHT_TRUE
MakieMaestro.Themes.B1_WIDTH
MakieMaestro.Themes.B1_WIDTH_TRUE
MakieMaestro.Themes.B1_HEIGHT
MakieMaestro.Themes.B1_HEIGHT_TRUE
MakieMaestro.Themes.B2_WIDTH
MakieMaestro.Themes.B2_WIDTH_TRUE
MakieMaestro.Themes.B2_HEIGHT
MakieMaestro.Themes.B2_HEIGHT_TRUE
MakieMaestro.Themes.B3_WIDTH
MakieMaestro.Themes.B3_WIDTH_TRUE
MakieMaestro.Themes.B3_HEIGHT
MakieMaestro.Themes.B3_HEIGHT_TRUE
MakieMaestro.Themes.B4_WIDTH
MakieMaestro.Themes.B4_WIDTH_TRUE
MakieMaestro.Themes.B4_HEIGHT
MakieMaestro.Themes.B4_HEIGHT_TRUE
MakieMaestro.Themes.B5_WIDTH
MakieMaestro.Themes.B5_WIDTH_TRUE
MakieMaestro.Themes.B5_HEIGHT
MakieMaestro.Themes.B5_HEIGHT_TRUE
MakieMaestro.Themes.B6_WIDTH
MakieMaestro.Themes.B6_WIDTH_TRUE
MakieMaestro.Themes.B6_HEIGHT
MakieMaestro.Themes.B6_HEIGHT_TRUE
MakieMaestro.Themes.B7_WIDTH
MakieMaestro.Themes.B7_WIDTH_TRUE
MakieMaestro.Themes.B7_HEIGHT
MakieMaestro.Themes.B7_HEIGHT_TRUE
MakieMaestro.Themes.B8_WIDTH
MakieMaestro.Themes.B8_WIDTH_TRUE
MakieMaestro.Themes.B8_HEIGHT
MakieMaestro.Themes.B8_HEIGHT_TRUE
MakieMaestro.Themes.B9_WIDTH
MakieMaestro.Themes.B9_WIDTH_TRUE
MakieMaestro.Themes.B9_HEIGHT
MakieMaestro.Themes.B9_HEIGHT_TRUE
MakieMaestro.Themes.B10_WIDTH
MakieMaestro.Themes.B10_WIDTH_TRUE
MakieMaestro.Themes.B10_HEIGHT
MakieMaestro.Themes.B10_HEIGHT_TRUE
MakieMaestro.Themes.B11_WIDTH
MakieMaestro.Themes.B11_WIDTH_TRUE
MakieMaestro.Themes.B11_HEIGHT
MakieMaestro.Themes.B11_HEIGHT_TRUE
MakieMaestro.Themes.B12_WIDTH
MakieMaestro.Themes.B12_WIDTH_TRUE
MakieMaestro.Themes.B12_HEIGHT
MakieMaestro.Themes.B12_HEIGHT_TRUE
MakieMaestro.Themes.B13_WIDTH
MakieMaestro.Themes.B13_WIDTH_TRUE
MakieMaestro.Themes.B13_HEIGHT
MakieMaestro.Themes.B13_HEIGHT_TRUE

MakieMaestro.Themes.C0_WIDTH
MakieMaestro.Themes.C0_WIDTH_TRUE
MakieMaestro.Themes.C0_HEIGHT
MakieMaestro.Themes.C0_HEIGHT_TRUE
MakieMaestro.Themes.C1_WIDTH
MakieMaestro.Themes.C1_WIDTH_TRUE
MakieMaestro.Themes.C1_HEIGHT
MakieMaestro.Themes.C1_HEIGHT_TRUE
MakieMaestro.Themes.C2_WIDTH
MakieMaestro.Themes.C2_WIDTH_TRUE
MakieMaestro.Themes.C2_HEIGHT
MakieMaestro.Themes.C2_HEIGHT_TRUE
MakieMaestro.Themes.C3_WIDTH
MakieMaestro.Themes.C3_WIDTH_TRUE
MakieMaestro.Themes.C3_HEIGHT
MakieMaestro.Themes.C3_HEIGHT_TRUE
MakieMaestro.Themes.C4_WIDTH
MakieMaestro.Themes.C4_WIDTH_TRUE
MakieMaestro.Themes.C4_HEIGHT
MakieMaestro.Themes.C4_HEIGHT_TRUE
MakieMaestro.Themes.C5_WIDTH
MakieMaestro.Themes.C5_WIDTH_TRUE
MakieMaestro.Themes.C5_HEIGHT
MakieMaestro.Themes.C5_HEIGHT_TRUE
MakieMaestro.Themes.C6_WIDTH
MakieMaestro.Themes.C6_WIDTH_TRUE
MakieMaestro.Themes.C6_HEIGHT
MakieMaestro.Themes.C6_HEIGHT_TRUE
MakieMaestro.Themes.C7_WIDTH
MakieMaestro.Themes.C7_WIDTH_TRUE
MakieMaestro.Themes.C7_HEIGHT
MakieMaestro.Themes.C7_HEIGHT_TRUE
MakieMaestro.Themes.C8_WIDTH
MakieMaestro.Themes.C8_WIDTH_TRUE
MakieMaestro.Themes.C8_HEIGHT
MakieMaestro.Themes.C8_HEIGHT_TRUE
MakieMaestro.Themes.C9_WIDTH
MakieMaestro.Themes.C9_WIDTH_TRUE
MakieMaestro.Themes.C9_HEIGHT
MakieMaestro.Themes.C9_HEIGHT_TRUE
MakieMaestro.Themes.C10_WIDTH
MakieMaestro.Themes.C10_WIDTH_TRUE
MakieMaestro.Themes.C10_HEIGHT
MakieMaestro.Themes.C10_HEIGHT_TRUE
```
```@raw html
</details>
```

# Plotting

## Overrides

```@docs
MakieMaestro.Recipes.image!
MakieMaestro.Recipes.image
```

## Utility / QOL functions 

```@docs
MakieMaestro.L
MakieMaestro.fftvis
```
