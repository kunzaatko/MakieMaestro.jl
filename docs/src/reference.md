# Public Documentation

Documentation for `MakieMaestro.jl`'s public interface.


## Contents

```@contents
Pages = ["reference.md"]
Depth = 2:2
```

```@index
Pages = ["reference.md"]
```

# Exporting


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

MakieMaestro.FunctionSpec
MakieMaestro.PathSpec
MakieMaestro.get_export_format
MakieMaestro.SizeSpec
MakieMaestro.RelativeSize
MakieMaestro.FigHeight

MakieMaestro._savefig
MakieMaestro._savepdftex
```
```@raw html
</details>
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

# Plotting

## Overrides

```@docs
MakieMaestro.Recipes.image!
MakieMaestro.Recipes.image
```

## Plotting functions
```@docs
MakieMaestro.Recipes.mosaic
```

## Utility / QOL functions 

```@docs
MakieMaestro.L
MakieMaestro.fftvis
```
