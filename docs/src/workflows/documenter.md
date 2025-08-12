```@meta
CurrentModule = MakieMaestro
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
makie_blocks = MakieDocBlocks(
    figure_dir = "assets/my_figure_dir",  # default is  "assets/figs", 
    # Optionally specify the export formats (default: [:svg, :pdf])
    export_format = [:svg, :png, :pdf, :eps],
)

makedocs(
    # ... your existing Documenter options ...
    plugins = [makie_blocks],
)
```

!!! tip "Constructing the plugin is not necessary"
    It is not necessary to create the plugin with `MakieDocBlocks`. As long as you do not want to change the default
    settings of the plugin. You only need to load `MakieMaestro` to use the `Documenter` plugin. However, consider
    defining the plugin if you are developing a package with other contributors as it is more explicit and will make it
    easier for them to understand the documentation generation process.

!!! warning "Custom `figure_dir` path"
    The target figure directory should not be preceded by a slash.
    ```julia 
    # MakieDocBlocks(figure_dir = "/assets/my_figure_dir") # ⚠️ DOESN'T WORK!!!
    MakieDocBlocks(figure_dir = "assets/my_figure_dir") # ⬅️ USE THIS
    ```
    For more details about this issue, see the functioning of [`joinpath`](@extref Julia :jl:function:`Base.Filesystem.joinpath`)

!!! info "CI setup"
    For the CI to be able to build figures using `GLMakie` you need to set up a screen in the CI environment. You can do
    this by prepending the command with `DISPLAY=:0 xvfb-run -s '-screen 0 1024x768x24' --`. For example to build the
    documentation, you will run the command
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

The code in the block must return a `Figure` in order to work. 

!!! tip
    ```
    using MakieMaestro   
    ```
    is already included at the top of the block for convenience so there is no need to add it yourself.

You can also use named blocks with the same format as for the documenter [`@example` block](@extref Documenter
:std:label:`reference-at-example`). The code will be evaluated in the same module as the `@example` blocks with this
name, so it will have the global variables at its disposal. 

For example this is possible to have

````markdown
```@example sine
x = 0.01:0.01:10
y = sin.(x) ./ x .+ x
```
```@makie  sine
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
nothing # hide
```
```@makie  A
lines(x,y)
```
````
and produce 
```@example A
x = 0.01:0.01:10
y = sin.(x) ./ x .+ x
nothing # hide
```
```@makie  A
lines(x,y)
```

# Advanced Usage
Any options specified after a `;` in the `@makie` block will be parsed used for saving or showing the figure in the
documentation.

The options that can be specified are: 
- `basename` -- Changes the figure path name. By default the basename to save the figure as
  is`"makie_$(name)_$(hash(code))"`

````
```@makie named_figure; basename="my_figure"
lines(sin.(0:0.1:pi))
```
````
```@makie named_figure; basename="my_figure"
lines(sin.(0:0.1:pi))
```

- `formats` -- Specify the export formats to use for the figure. The default is determined by the plugin options.
````
```@makie pdf_figure; formats = :pdf
lines(sin.(0:0.1:pi))
```
````

```@makie pdf_figure; formats = :pdf
lines(sin.(0:0.1:pi))
```

````
```@makie multiple_formats; formats = [:png, :pdf]
lines(sin.(0:0.1:pi))
```
````

```@makie multiple_formats; formats = [:png, :pdf]
lines(sin.(0:0.1:pi))
```

- `caption` -- Attach a caption under the figure in the documentation. 
- `size` -- Specify the size of the figure to export. All of the options that can be passed to [`savefig`](@ref) are
  possible
````
```@makie large_figure; size=25u"cm"
lines(sin.(0:0.1:pi))
```
````

```@makie large_figure; size=25u"cm"
lines(sin.(0:0.1:pi))
```

- `alt` --  Specify an alternate text to add to the figure in the HTML output. (`alt_figure; alt = "A figure"`)
