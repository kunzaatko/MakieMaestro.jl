# TODO: Assure that the gaps are set correctly such that if I use subfigures in LaTeX that the figures output is the
# same as when I generate a figure with multiple axes <18-10-24> 
module Themes
using ColorTypes, Makie, ColorSchemes, Unitful

# TODO: Perhaps these should all be only a dictionary that has the keys for the particular theme types. Such
# a dictionary could be passed to the save-fig and the `with_theme` functions as a whole or via an accessor <18-10-24> 
# TODO: Framework for setting the base theme and/or updating it etc. <18-10-24> 

include("theme-constants.jl")

# TODO: Add pdf_version to export theme <20-10-24> 

# TODO: Test
# In [4]: f = () -> Theme(; figure_padding = 3)
#21 (generic function with 1 method)
# In [10]: merge_generate(f, theme_latexfonts)
# Attributes with 2 entries:
#   figure_padding => 3
#   fonts => Attributes with 4 entries:
#     bold => FTFont (family = NewComputerModern, style = 10 Bold)
#     bolditalic => FTFont (family = NewComputerModern, style = 10 Bold Italic)
#     italic => FTFont (family = NewComputerModern, style = 10 Italic)
#     regular => FTFont (family = NewComputerModern Math, style = Regular)

const ThemeGenerator = Union{Function,Theme}
generate(gen::ThemeGenerator) = gen isa Function ? gen() : gen
"""
    merge_generate(themes::ThemeGenerator)

Merge and generate themes from a `ThemeGenerator`.

This function takes a `ThemeGenerator` (which can be a collection of themes or theme-generating functions)
and merges them into a single theme. If an element of `themes` is a function, it is called to generate
a theme; otherwise, the element is used as-is.

# Arguments
- `themes::ThemeGenerator`: A collection of themes or theme-generating functions.

# Returns
A merged theme combining all the input themes. Note that the inputs that earlier in the collection have precedence.

# Example
```julia
theme = merge_generate(BASE_THEME,Theme(; figure_padding=2), GL_THEME, SIZE_THEME(20u"cm", 0.5))
```
"""
function merge_generate(themes::Vararg{Union{ThemeGenerator}})
    return merge(map(generate, themes)...)
end

"""
    figsize(width::Length=get_width(), hw_ratio=get_hwratio())

Calculate the figure size in points based on the given width and height-to-width ratio.

# Arguments
- `width::Length`: The desired width of the figure. Defaults to the result of `get_width()`.
- `hw_ratio`: The height-to-width ratio. Defaults to the result of `get_hwratio()`.

# Example
```julia
width, height = figsize(800u"px", 0.75)
```
"""
function figsize(width::Length=get_width(), hw_ratio=get_hwratio())
    width_pts = floor(Int, to_units(width)) # TODO: Test whether these can be floats <17-10-24> 
    height_pts = floor(Int, width_pts * hw_ratio)
    return width_pts, height_pts
end

const THEME = Ref{Dict{Symbol,ThemeGenerator}}(Dict())

gen(s::Symbol; dict=THEME[]) = (args...) -> dict[s](args...)

# TODO: Use `Makie.current_default_theme()` to modify the base theme and add it to the `with_backend` function not to
# overwrite the current theme <20-10-24> 

# TODO: Testing <19-10-24> 
"""
    get_theme(themes::Vector{Union{ThemeGenerator,Symbol}}; dict = THEME[])
    get_theme(A, B, C, ...; dict = THEME[])

Create theme for specified keys and/or generators (including `Theme`s).

# Arguments
- `keys::Vector{Symbol}`: A vector of symbols representing the desired theme property keys.

# Example
```julia
gap = true
theme_props = get_theme([Theme(; figure_padding=2), :font, () -> Theme(; colgap = gap, rowgap = gap),  :linewidth, :color])
```
This will return a theme that combines the three specified themes together. Note that rightmost has precedence unlike
merges on usual julia dictionaries, but same as with `Makie.Attributes`.
"""
function get_theme(themes::Vector{Union{ThemeGenerator,Symbol}}; dict=THEME[])
    return merge_generate(map(k -> k isa Symbol ? getindex(dict, k) : k, themes)...)
end
function get_theme(themes::Vararg{Union{ThemeGenerator,Symbol}}; dict=THEME[])
    return get_theme(collect(Union{ThemeGenerator,Symbol}, themes); dict=dict)
end
"""
    update_theme!(key::Symbol, new::ThemeGenerator)

Update a specific theme component in the global theme.

# Arguments
- `key::Symbol`: The key representing the theme component to be updated.
- `new::ThemeGenerator`: The new theme generator to replace the existing one.

This function modifies the global theme by replacing the theme generator for the specified
component with a new one. It directly updates the `THEME` global variable.

See also Use [`update_theme`](@ref) for a function a non-overwriting method.
"""
function update_theme!(key::Symbol, new::ThemeGenerator)
    return THEME[][key] = new
end
"""
    update_theme(key::Symbol, with::ThemeGenerator)

Update a specific theme component identified by `key` in the global `THEME` dictionary.

# Arguments
- `key::Symbol`: The key identifying the theme component to update.
- `with::ThemeGenerator`: The new theme or function to update the existing theme with.

See also Use [`update_theme!`](@ref) for direct modifications.

#  Extended help
Specific behaviour for argument types:
- If the `key` doesn't exist in `THEME`, it adds the new theme or function.
- If the `key` exists:
  - For an existing `Theme`:
    - If `with` is a `Function`, it merges the result of `with` with the current theme.
    - If `with` is a `Theme`, it merges the current theme with `with`.
  - For an existing `Function`:
    - If `with` is a `Theme`, it creates a new function that merges `with` with the result of the current function.
    - If `with` is a `Function`, it throws an `ArgumentError`.

# Throws
- `ArgumentError`: If attempting to update a generating function with another generating function.
"""
function update_theme(key::Symbol, with::ThemeGenerator)
    if !haskey(THEME[], key)
        update_theme!(key, with)
    else
        current = THEME[][key]
        if current isa Theme
            if with isa Function
                update_theme!(key, (args...) -> merge(with(args...), current))
            elseif with isa Theme
                update_theme!(key, merge(current, with))
            end
        elseif current isa Function
            if with isa Theme
                update_theme!(key, (args...) -> merge(with, current(args...)))
            elseif with isa Function
                throw(
                    ArgumentError(
                        "Cannot update a generating function with a generating function. If you wish to overwrite the current generating function instead of merging, use `update_theme!(key, new)`.",
                    ),
                )
            end
        end
    end
end

# NOTE: Here is a great explanation of how to choose the correct colorscheme for a plot: https://seaborn.pydata.org/tutorial/color_palettes.html#qualitative-color-palettes  

# FIX: I should eliminate the attributes that are not useful or not necessary to define in the given theme. In example
# the :base theme doesn't need to have font sizes <18-10-24> 

# FIX: This theme should not set the font size. It depends on the output size which is different depending on the where
# we are plotting. In Pluto the smaller font makes the labels illegible <18-10-24> 
# FIX: Adjust font sizes <21-11-23> 
THEME[][:base] = function base_theme()
    return merge_generate(
        Theme(;
            figure_padding=2,
            Axis=(
                xgridvisible=false,
                ygridvisible=false,
                xticklabelsize=10,
                yticklabelsize=10,
                xtickwidth=0.7,
                ytickwidth=0.7,
                xticksize=4,
                yticksize=4,
            ),
            Lines=(; cycle=CYCLE),
            Scatter=(cycle=CYCLE, markersize=MARKERSIZE, strokewidth=0),
            Image=(; interpolate=false),
            Heatmap=(; colormap=:Spectral),
            Colorbar=(
                labelsize=10,
                ticklabelsize=10,
                leftspinevisible=false,
                rightspinevisible=false,
                topspinevisible=false,
                bottomspinevisible=false,
                width=5,
                # labelpadding=1.5,
                tickwidth=0.7,
                ticksize=4,
            ),
            Legend=(
                labelsize=10,
                nbanks=1,
                framevisible=false,
                tellwidth=false,
                tellheight=false,
            ),
        ),
        theme_latexfonts,
    )
end

THEME[][:raster] = Theme()
THEME[][:vector] = Theme(;
# NOTE: `rasterize=10` is a hack that enables to save with CairoMakie
# https://github.com/MakieOrg/Makie.jl/issues/1909 (makes the figures significantly larger) <16-11-23> 
# Image=(; rasterize=10),
)

THEME[][:size] = function size_theme(width::Length=get_width(), hwratio=get_hwratio())
    width_pts, height_pts = figsize(width, hwratio)
    # TODO: Is this necessary? <17-10-24> 
    # if w_pts < 250
    #     return Theme(;
    #         size=(w_pts, h_pts),
    #         # figure_padding=10
    #     )
    # else
    return Theme(; size=(width_pts, height_pts))
    # end
end

# TODO: Theme generators should also be dynamic meaning that when one calls a generating function, it should be able to
# decide based on the previous attributes that were set. This can be done by a generic argument to the theme generating
# function `current_theme` that contains the theme until the merge with the current theme generating function. For
# instance I would like to dynamically be able to set the figure padding based on the font size of the axis labels and
# their rotation. Also perhaps the `columngap`, `rowgap` etc. should be set based on the size of the figure.  <22-10-24> 

# TODO: Add Axis3 to BASE_THEME and only change what is not same <22-12-23> 
# TODO: https://docs.makie.org/stable/how-to/save-figure-with-transparency/#glmakie <20-11-23> 
THEME[][:glmakie] = Theme(; figure_padding=3)
THEME[][:wglmakie] = Theme(;)

# FIX: This is maybe not necessary anymore and it only adds memory in the saved image <16-10-24> 
THEME[][:cairomakie] = Theme(;
    backgroundcolor=:transparent, CairoMakie=(; pdf_version="1.5")
) #= px_per_unit=20, =#

# TODO: There should be a function for combining the themes based on the keys to the dictionary and the arguments
# supplied to the theme generating function if it is a generator <18-10-24> 
# FIX: Is this done? <23-10-24> 
THEME[][:interactive] = function INTERACTIVE_THEME(width_ratio=0.8, hwratio=get_hwratio())
    return merge_generate(
        THEME[][:glmakie],
        THEME[][:size](width_ratio * to_units(get_width()), hwratio),
        THEME[][:base],
    )
end

include("override-themes.jl")

export width!, hwratio!, screen_parameters
end
