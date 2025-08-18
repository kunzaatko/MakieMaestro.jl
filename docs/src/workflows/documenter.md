```@meta
CurrentModule = MakieMaestro
CollapsedDocStrings=true
```

# Documenter Integration

MakieMaestro.jl includes a plugin for [Documenter.jl](@extref Documenter :std:doc:`index`) that allows you to
embed Makie figures directly into your documentation using code blocks.

## Setup

To use the `MakieMaestro` ↔ `Documenter` plugin in your documentation, add the following to your `docs/make.jl` file:

```julia
using Documenter, MakieMaestro
using YourPackage

# Make sure to set a default width or use the `size` option in the `@makie` block
MakieMaestro.Themes.width!(15u"cm")

# Create the MakiePlugin with optional customization
makie_blocks = MakieDocBlocks(;
    path="assets/my_figure_dir",  # default is  "assets/figs", 
    # Optionally specify the export formats (default: [:svg, :pdf])
    formats=[:svg, :png, :pdf, :eps],
)

makedocs(
    # ... your existing Documenter options ...
    plugins = [makie_blocks],
)
```

```@docs
MakieMaestro.MakieDocBlocks
```

!!! tip "Constructing the plugin is not necessary"
    It is not necessary to create the plugin with `MakieDocBlocks`. As long as you do not want to change the default
    settings of the plugin. You only need to load `MakieMaestro` to use the `Documenter` plugin. However, consider
    defining the plugin if you are developing a package with other contributors as it is more explicit and will make it
    easier for them to understand the documentation generation process.

!!! warning "Custom `path`"
    The target figure directory should not be preceded by a slash.
    ```julia 
    # MakieDocBlocks(;path="/assets/my_figure_dir") # ⚠️ DOESN'T WORK!!!
    MakieDocBlocks(;path="assets/my_figure_dir") # ⬅️ USE THIS
    ```
    For more details about this issue, see the functioning of [`joinpath`](@extref Julia
    :jl:function:`Base.Filesystem.joinpath`).

!!! info "CI setup"
    For the CI to be able to build figures using `GLMakie` you need to set up a screen in the CI environment. You can do
    this by prepending the command with 
    ```bash

    DISPLAY=:0 xvfb-run -s '-screen 0 1024x768x24' --
    ```
    For example to build the documentation, you will run the command
    ```bash
    DISPLAY=:0 xvfb-run -s '-screen 0 1024x768x24' -- julia --project --color=yes make.jl
    ```
    Look at the workflows in this repository for a working example.

## Basic Usage

Once the plugin is set up, you can include Makie figures in your documentation using code blocks with the `@makie`
language tag:

````markdown
```@makie
# Your code for generating the figure
fig # Return the figure at the end of the block
```
````

The code will be executed during the documentation build, and the resulting figure will be saved and inserted into your
documentation as an image (specifically the [Documenter `LocalImage`](@extref `Documenter.LocalImage`)).

The code in the block must return a [`Figure`](@extref Makie `Makie.Figure`) or `FigureAxis` or `FigureAxisPlot` in
order to work.

!!! note "Types that can be exported"
    There are other types that can be exported and used in the documentation. The guiding criterium is that the
    `function` that is defined by wrapping the code block in a function definition must be a function that is savable
    using [`savefig`](@ref).  See [Exporting publication figures](@ref).

!!! warning "What is allowed in the block"
    Not all code is allowed in the `@makie` block. Most notably the definition of a struct is not allowed. The
    limitation arises from the fact that not all code is allowed to be placed inside a function. You can bypass this
    limitation in two ways: 
    1. You can define the struct or call `using ...` in an `@example` block or `@setup` block with the same ID and use
       it in the `@makie` block that follows.
    2. You can wrap the disallowed expression in an `@eval begin ... end` block to evaluate it in the top level from
       within the function that the `@makie` block defines.

!!! tip "No need to add `using MakieMaestro`"
    ```
    using MakieMaestro   
    ```
    is already included at the top of the block for convenience so there is no need to add it yourself.

You can also use named blocks with the same format as for the documenter [`@example` block](@extref Documenter
:std:label:`reference-at-example`). The code will be evaluated in the same module as the `@example` blocks with this
name, so it will have the global variables at its disposal. 

For example this is possible to have

````markdown
```@example wavepocket
x = -2.2:0.01:2.2
y = @. exp(-x^2) * cos(5x)
```
```@makie  wavepocket
lines(x,y)
```
````

It is also possible to specify some of the options for [`savefig`](@ref) to modify the size, file name, theme, etc. See
[Advanced Usage](@ref) for further details.

## Example

Here's an example of using the `@makie` code block in documentation:

This code block
````markdown
```@makie
x = -2π:0.01:2π
fig,ax,_ = lines(x, sin.(x.^2) ./ x, linewidth = 2, label = "chirp(x)")
axislegend(ax)
fig
```
````
generates the following figure
```@makie
x = -2π:0.01:2π
fig,ax,_ = lines(x, sin.(x.^2) ./ x, linewidth = 2, label = "chirp(x)")
axislegend(ax)
fig
```

This `@example` and `@makie` blocks are evaluated in the same module
````markdown
```@example besselj
using SpecialFunctions
x = 0:0.01:20
y = besselj0.(x)
nothing # hide
```
```@makie  besselj
lines(x,y)
```
````
and produce 
```@example besselj
using SpecialFunctions
x = 0:0.01:20
y = besselj0.(x)
nothing # hide
```
```@makie  besselj
lines(x,y)
```

# Advanced Usage
Any options specified after a `;` in the `@makie` block will be parsed used for saving or showing the figure in the
documentation.

The options that can be specified are: 
- `basename` -- Changes the figure path name. By default the basename to save the figure as
  is`"makie_$(name)_$(hash(code))"`

````
```@makie named_figure; basename="rose"
θs = 0:0.01:4π
rs = sin.(4θs)
x,y = rs .* cos.(θs), rs .* sin.(θs)
lines(x,y)
```
````
```@makie named_figure; basename="rose"
θs = 0:0.01:4π
rs = sin.(4θs)
x,y = rs .* cos.(θs), rs .* sin.(θs)
lines(x,y)
```

- `formats` -- Specify the export formats to use for the figure. You can specify a single format as a symbol or a vector
  of symbols. The default is determined by the plugin options.
````
```@makie hypotrochoid; formats = :png
ts = 0:0.01:2π
x = @. cos(ts) - cos(3ts)
y = @. sin(ts) - sin(3ts)
lines(x,y)
```
````

```@makie hypotrochoid; formats = :png
ts = 0:0.01:2π
x = @. cos(ts) - cos(3ts)
y = @. sin(ts) - sin(3ts)
lines(x,y)
```

````
```@makie exponential_spiral; formats = [:png, :pdf]
θs = 0:0.01:4π
rs = @. exp(0.1θs)
x,y = rs .* cos.(θs), rs .* sin.(θs)
lines(x,y)
```
````

!!! warn "`:png` format on a HTML spans the whole width" 
    If you choose to export to a `png` the figure will span the full width of the documentation page. If you want to
    enforce the size of the figure exported, you need to use the `:svg` format (which is default).

!!! tip "Use `:png` for images"
    If you use images or `GridLike`/`CellLike` plots in your documentation, you should be using them with the `:png`
    format. It is possible to export these plots to `:svg` but it leads to performance issues in the browser since
    vector graphics are really not meant for use with _image like_ graphics.

```@makie exponential_spiral; formats = [:png, :pdf]
θs = 0:0.01:4π
rs = @. exp(0.1θs)
x,y = rs .* cos.(θs), rs .* sin.(θs)
lines(x,y)
```

- `caption` -- Attach a caption under the figure in the documentation. 
- `size` -- Specify the size of the figure to export. All of the options that can be passed to [`savefig`](@ref) are
  possible
```@example large_figure
using GeometryBasics
struct FitzhughNagumo{T}
    ϵ::T
    s::T
    γ::T
    β::T
end
P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)
f(x, P::FitzhughNagumo) = Point2f(
    (x[1]-x[2]-x[1]^3+P.s)/P.ϵ,
    P.γ*x[1]-x[2] + P.β
)
f(x) = f(x, P)
```

````
```@makie large_figure; size=25u"cm"
streamplot(f, -1.5..1.5, -1.5..1.5, colormap = :magma)
```
````

```@makie large_figure; size=25u"cm"
streamplot(f, -1.5..1.5, -1.5..1.5, colormap = :magma)
```

- `alt` --  Specify an alternate text to add to the figure in the HTML output. (`alt_figure; alt = "A figure"`)
