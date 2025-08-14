```@meta
CurrentModule = MakieMaestro
CollapsedDocStrings=true
```

```@setup images
using MakieMaestro
using MakieMaestro.Recipes
using TestImages
```

```@setup graphs
using MakieMaestro
using MakieMaestro.Recipes
```

```@setup polygon
using MakieMaestro
using MakieMaestro.Recipes
using GeometryBasics
```

# Ensemble Plots

For plotting multiple data with a single function to a figure, `MakieMaestro` defines a `mosaic`/`mosaic!` function in
the `Recipes` module.

```@docs
Recipes.mosaic
```

```@example images
img_gray = testimage("mandril_gray")
img_color = testimage("mandril_color")
nothing # hide
```

If you would want to plot the two images side-by-side, you can use `mosaic`
```@example images
Recipes.mosaic(Recipes.image!, img_gray', img_color'; axis=(;yreversed=true))
nothing # hide
```

```@makie images; formats=:png
f,_,_ = Recipes.mosaic(Recipes.image!, img_gray', img_color'; axis=(;yreversed=true))
f
```

Or graphs in a mosaic with 2 rows (number of rows is set by `nrows` and columns with `ncols`)

```@example graphs
using Graphs, GraphMakie
Recipes.mosaic(graphplot!,
  lollipop_graph(2,5), 
  turan_graph(6, 2), 
  cycle_graph(5), 
  binary_tree(5), 
  star_digraph(3),
  barabasi_albert(10, 2); nrows=2, linkaxes=false) # axes are linked by default
nothing # hide
```

```@makie graphs; size=(15u"cm", 25u"cm")
f,_,_ = Recipes.mosaic(graphplot!,lollipop_graph(2,5), turan_graph(6, 2), cycle_graph(5), binary_tree(5), star_digraph(3), barabasi_albert(10, 2); nrows=2)
f
```

!!! tip "`do` syntax"
    For more complicated functions, you can use the `do` syntax to define any alteration that you want to make to the
    data and the axes the data will be plotted on.
    The signature of the function that plots into the axis is `(ax, data) -> Any` which mutates the axis by plotting the
    data into it and may perform any modifications to the axis (e.g. change the title, style, etc.).

The default is to use `Makie.plot!` so if you have a type that implements plotting, you do not have to supply the
function


```@example polygon
polys = [Polygon([Point(sin(θ), cos(θ)) for θ in range(0; step=2π/N, length=N)]) for N in 3:7]
Recipes.mosaic(polys...; axis=(;aspect=1))
nothing # hide
```

```@makie polygon; size=(7u"cm", 25u"cm"), format=:png
f,_,_ = Recipes.mosaic(polys...; axis=(;aspect=1))
f
```
