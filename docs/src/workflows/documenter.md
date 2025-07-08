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

MakieMaestro.Themes.width!(15u"cm") # Make sure to set a default width or use the `width` option in the `@makie` block

# Create the MakiePlugin with optional customization
makie_blocks = MakieDocBlocks(
    figure_dir = "assets/my_figure_dir",  # default is  "assets/figs", 
    # Optional: specify the export formats (default: [:svg, :pdf])
    export_format = [:svg, :png, :pdf, :eps],
)

makedocs(
    # ... your existing options ...
    plugins = [makie_blocks],
)
```

!!! tip 
    It is not necessary to create the plugin with `MakieDocBlocks`. As long as you do not want to change the default
    settings of the plugin. You only need to load `MakieMaestro` to use the `Documenter` plugin. However, consider
    defining the plugin if you are developing a package with other contributors as it is more explicit and will make it
    easier for them to understand the documentation generation process.

!!! warning
    The target figure directory should not be preceded by a slash.
    ```julia 
    # MakieDocBlocks(figure_dir = "/assets/my_figure_dir") # ⚠️ DOESN'T WORK!!!
    MakieDocBlocks(figure_dir = "assets/my_figure_dir") # ⬅️ USE THIS
    ```
    For more details about this issue, see the functioning of [`joinpath`](@extref Julia :jl:function:`Base.Filesystem.joinpath`)

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

The code in the block must return a `Figure` in order to work. 

!!! tip
    ```
    using MakieMaestro   
    ```
    is already included at the top of the block for convenience.

You can also use named blocks with the same format as for the documenter [`@example` block](@extref Documenter
:std:label:`reference-at-example`). The code will be evaluated in the same module as the `@example` blocks with this
name, so it will have the global variables at its disposal. 

For example this is possible to 

````markdown
```@example sine
x = 0.01:0.01:10
y = sin.(x) ./ x .+ x
```
```@makie  sine
lines(x,y)
```
````

## Example

Here's an example of using the `@makie` code block in documentation:

This code block
````markdown
```@makie
x = 0:0.1:2π
fig,ax,_ = lines(x, sin.(x) ./ x, linewidth = 2, label = "sin(x)")
axislegend(ax)
fig
```
````
generates the following figure
```@makie
x = 0:0.1:2π
fig,ax,_ = lines(x, sin.(x) ./ x, linewidth = 2, label = "sin(x)")
axislegend(ax)
fig
```

This `@example` and `@makie` blocks are evaluated in the same module
````markdown
```@example A
x = 0.01:0.01:10
y = sin.(x) ./ x .+ x
```
```@makie  A
lines(x,y)
```
````
and produce 
```@example A
x = 0.01:0.01:10
y = sin.(x) ./ x .+ x
```
```@makie  A
lines(x,y)
```
