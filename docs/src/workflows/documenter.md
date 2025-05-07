```@meta
CurrentModule = MakieMaestro
```

# Documenter Integration

MakieMaestro.jl includes a plugin for [Documenter.jl](@extref Documenter :std:doc:`index`) that allows you to
embed Makie figures directly into your documentation using code blocks.

## Setup

To use the MakieMaestro Documenter plugin in your documentation, add the following to your `docs/make.jl` file:

```julia
using Documenter, MakieMaestro
using YourPackage

# Create the MakiePlugin with optional customization
makie_blocks = MakieMaestro.docblocks(
    figure_dir = @__DIR__ * "/assets/",  # default = @__DIR__ * "/assets/figs", 
    # Optional: specify the export formats (default: [:svg, :pdf])
    export_format = [:svg, :png, :pdf]
)

makedocs(
    # ... your existing options ...
    plugins = [makie_blocks],
)
```

!!! tip 
    It is not necessary to create the plugin with `MakieMaestro.docblocks`. As long as you do not want to change the
    defaults, it is only necessary to load `MakieMaestro`.

## Basic Usage

Once the plugin is set up, you can include Makie figures in your documentation using code blocks with the `@makie`
language tag:

````markdown
```@makie
fig = Figure()
ax = Axis(fig[1, 1], title = "Example Plot")
lines!(ax, 0..10, sin)
fig
```
````

The code will be executed during the documentation build, and the resulting figure will be saved and inserted into your
documentation as a [`Documenter.LocalImage`](@extref), which will be further expanded.

The code in the block must return a `Figure` in order to work. 

!!! tip
    ```
    using MakieMaestro   
    ```
    is already included at the top of the block for convenience.

## Example

Here's an example of using the `@makie` code block in documentation:

This code block
````markdown
```@makie
x = 0:0.1:2π
fig,ax,_ = lines(x, sin.(x), linewidth = 2, label = "sin(x)")
axislegend(ax)
fig
```
````
generates the following figure
```@makie
x = 0:0.1:2π
fig,ax,_ = lines(x, sin.(x), linewidth = 2, label = "sin(x)")
axislegend(ax)
fig
```
