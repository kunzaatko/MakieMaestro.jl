# TODO: Assure that the gaps are set correctly such that if I use subfigures in LaTeX that the figures output is the
# same as when I generate a figure with multiple axes <18-10-24> 
"""
This module is used to set themes for your figures. It can help you define a consistent
theming scheme for your saved figures and for the figures you experiment with interactively.

It intends to solve the problem, where `Makie` gives you the option of theming, but if you
want to change the theme at multiple places with multiple attribute changes and perhaps
combine these options differently for your figures, it is necessary that you create the
override themes and merge them with the current one which sooner or later becomes tedious
and error prone. Especially if you are to create a lot of figures with various theming
preferences. This tries to make theming and keeping consistency in your plots a little bit
easier by allowing you to define all the connected attributes in one theme, register it with
`update_theme!(:my_theme, theme)` and use these where necessary in your figure creation
process and when saving.
"""
module Themes
using ColorTypes, Makie, ColorSchemes, Unitful
using Makie: Theme

# TODO: Perhaps these should all be only a dictionary that has the keys for the particular theme types. Such
# a dictionary could be passed to the save-fig and the `with_theme` functions as a whole or via an accessor <18-10-24> 
# TODO: Framework for setting the base theme and/or updating it etc. <18-10-24> 

include("theme-constants.jl")

# TODO: Theme generators should also be dynamic meaning that when one calls a generating function, it should be able to
# decide based on the previous attributes that were set. This can be done by a generic argument to the theme generating
# function `current_theme` that contains the theme until the merge with the current theme generating function. For
# instance I would like to dynamically be able to set the figure padding based on the font size of the axis labels and
# their rotation. Also perhaps the `columngap`, `rowgap` etc. should be set based on the size of the figure.  <22-10-24> 

# TODO: ThemeGeneratingFunction should instead be an abstract type that holds its latent arguments and is able to
# generate the theme from the arguments passed to the invoking function. <13-12-24> 
"""
    ThemeGenerator == Union{Function,Theme}
A struct used for defining new theme “mixins” that can be inferred from some latent parameters.

!!! danger
    That the function returns a `Theme` value is not checked. Therefore this type is only to be used internally...
    ```jldoctest
    julia> (() -> nothing) isa MakieMaestro.Themes.ThemeGenerator
    true
    ```
"""
const ThemeGenerator = Union{Function,Theme}
generate(gen::ThemeGenerator) = gen isa Function ? gen() : gen

"""
    merge_generate(theme::ThemeGenerator,...)::Theme
Generate and merge all the `theme` arguments.

Later input arguments have precedence similarly as in a merge of dictionaries.

See also [`get_theme`](@ref), [`ThemeGenerator`](@ref)

# Examples
```jldoctest
julia> MakieMaestro.Themes.merge_generate(Theme(; figure_padding=3), () -> Theme(; figure_padding=6))
Attributes with 1 entry:
  figure_padding => 6
```
"""
merge_generate(themes::Vararg{Union{ThemeGenerator}}) =
    merge(map(generate, reverse(themes))...)

"""
    figsize(width::Length=get_width(), hw_ratio=get_hwratio())
Calculate the figure size in points (`1u"pt" == (1//72)u"inch"`) based on the given width
and height-to-width ratio.

# Examples
```jldoctest; setup = :(using MakieMaestro.Themes)
julia> w,h = Themes.figsize(32u"cm", (1 + √(5))/2)
(907, 1467)
```
"""
function figsize(width::Length=get_width(), hw_ratio=get_hwratio())
    width_pts = floor(Int, to_units(width)) # TODO: Test whether these can be floats <17-10-24> 
    height_pts = floor(Int, width_pts * hw_ratio)
    return width_pts, height_pts
end

# TODO: Should supply some method that gives the keys that are defined in the theme dictionary. <09-01-25> 
# TODO: Should add the base Themes as `dark`, `light` (`theme_light`) etc. defined in Makie itself under some keys in
# this theming dictionary. Then document this. <09-01-25> 
const THEME = Ref{Dict{Symbol,ThemeGenerator}}(Dict())

"""
    gen(s::Symbol; dict=THEME[])
Return the function from the key `s` of dict.
"""
gen(s::Symbol; dict=THEME[]) = (args...) -> dict[s](args...)

# TODO: Use `Makie.current_default_theme()` to modify the base theme and add it to the `with_backend` function not to
# overwrite the current theme <20-10-24> 

"""
    get_theme(themes::Vector{Union{ThemeGenerator,Symbol}}; dict = THEME[])
    get_theme(A, B, C, ...; dict = THEME[])
Create theme for specified keys and/or generators (including `Theme`s).

Later arguments have precedence similarly to `Base.merge(A::Dict, B::Dict)`.

# Arguments
- `keys`: A `Vector` or `Vararg` of symbols, functions generating themes or themes. Symbols are taken as keys from the dict.

# Examples
```jldoctest
julia> gap = true
true

julia> theme_props = MakieMaestro.Themes.get_theme([Theme(; figure_padding=2), () -> Theme(; colgap = gap, rowgap = gap), :orange_title])
Attributes with 4 entries:
  Axis => Attributes with 1 entry:
    titlecolor => orange
  colgap => true
  figure_padding => 2
  rowgap => true
```
"""
function get_theme(themes::Vector; dict=THEME[]) # NOTE: Reason for not specifying the eltype of the vector is that when the vector is created it tends to have an eltype of `Any` which does not fit the signature then <08-01-25> 
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

See also [`update_theme`](@ref)
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

See also [`update_theme!`](@ref) for direct modifications.

#  Extended help
Specific behaviour for argument types:
- If the `key` doesn't exist in `THEME`, it adds the new theme or function.
- If the `key` exists:
  - For an existing `Theme`:
    - If `with` is a `Function`, it merges the result of `with` with the current theme.
    - If `with` is a `Theme`, it merges the current theme with `with`.
  - For an existing `Function`:
    - If `with` is a `Theme`, it creates a new function that merges `with` with the result
        of the current function.
    - If `with` is a `Function`, it throws an `ArgumentError`.

# Throws
- `ArgumentError`: If attempting to update a generating function with another generating
function.
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
                        """
                        Cannot update a generating function with a generating function. If
                        you wish to overwrite the current generating function instead of
                        merging, use `update_theme!(key, new)`.
                        """
                    ),
                )
            end
        end
    end
end

include("predefined-themes.jl")
include("override-themes.jl")

export width!, hwratio!
end
