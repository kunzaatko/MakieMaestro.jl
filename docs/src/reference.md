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
```

```@raw html
<details><summary>Internals</summary>
```
```@docs
MakieMaestro.get_figure_dir
MakieMaestro.isvectorgraphic
MakieMaestro.skip
MakieMaestro.extension
MakieMaestro.choose_backend
MakieMaestro.get_themes
```
```@raw html
</details>
```

# Theming

```@docs
MakieMaestro.Themes.width!
MakieMaestro.Themes.hwratio!
```

```@raw html
<details><summary>Internals</summary>
```
```@docs
MakieMaestro.Themes.get_theme
MakieMaestro.Themes.interactive_size!
MakieMaestro.Themes.get_hwratio
MakieMaestro.Themes.get_width
MakieMaestro.Themes.to_units
MakieMaestro.Themes.figsize
MakieMaestro.Themes.screen_parameters
MakieMaestro.Themes.update_theme
MakieMaestro.Themes.update_theme!
MakieMaestro.Themes.merge_generate
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
