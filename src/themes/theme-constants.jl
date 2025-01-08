using Unitful
using Unitful: Length
using MakieMaestro.Units

const ALPHA = 1.0
const COLOR_SCHEME = ColorSchemes.seaborn_deep.colors
const COLORS = @. RGBAf(red(COLOR_SCHEME), green(COLOR_SCHEME), blue(COLOR_SCHEME), ALPHA)
const LINESTYLES = [
    nothing,  # solid line
    :dash,
    :dot,
    :dashdot,
    :dashdotdot,
]
const MARKERS = [
    :circle,
    :rect,
    :dtriangle,
    :utriangle,
    :cross,
    :diamond,
    :ltriangle,
    :rtriangle,
    :pentagon,
    :xcross,
    :hexagon,
]
const MARKERSIZE = 7
const CYCLE = Cycle([:color, :marker]; covary=true)
const WIDTH_DEFAULT = Ref{Union{Missing,Length}}(missing)
const HWRATIO_DEFAULT = Ref{Number}(float(2 / (√(5) + 1)))

"""
    hwratio!(val)

Set the height-width ratio for saving figures.

```jldoctest; setup = :(using MakieMaestro.Themes)
julia> hwratio!((1 + √(5))/2)
1.618033988749895

julia> Themes.get_hwratio()
1.618033988749895
```
"""
function hwratio!(val::Number)
    return HWRATIO_DEFAULT[] = val
end

"""
    Themes.get_hwratio()

Get the set height-width ratio for saving figures.

# Examples
```jldoctest; setup = :(using MakieMaestro.Themes)
julia> hwratio!(0.5)
0.5

julia> Themes.get_hwratio()
0.5
```
"""
get_hwratio() = HWRATIO_DEFAULT[]

"""
    width!(val::Length)

Set the default width for figures.

```jldoctest; setup = :(using MakieMaestro.Themes)
julia> width!(177u"mm" * 0.8)
141.6 mm

julia> Themes.get_width()
141.6 mm
```
"""
function width!(val::Length)
    return WIDTH_DEFAULT[] = val
end

"""
    Themes.to_units(val::Length)

Convert `val` to Makie figure units

# Example
```jldoctest; setup = :(using MakieMaestro.Themes)
julia> Themes.to_units(2u"cm")
7200//127
```
"""
function to_units(val::Length)
    return ustrip(uconvert(u"pt", val))
end

"""
    Themes.get_width()

Get the default figure width

# Examples
```jldoctest; setup = :(using MakieMaestro.Themes)
julia> width!(10u"cm")
10 cm

julia> Themes.get_width()
10 cm
```
"""
function get_width()
    ismissing(WIDTH_DEFAULT[]) && throw(
        ErrorException(
            """
            WIDTH_DEFAULT not set! Use MakieMaestro.Themes.width!(val) to set it before
            saving a figure.
            """
        ),
    )
    return WIDTH_DEFAULT[]
end

# TODO: Add some function that sets all the necessary variables at once <17-10-24>

include("interactive-theme.jl")

# TODO: Test the `ErrorException`s that are thrown if no definition of the constant is made
# before the `get`ing call <13-12-24> 

# NOTE: This does not make much sense for GLMakie. It does however for WGLMakie since it does not create its own window. <17-10-24> 
"""
    interactive_size!(size::Tuple{Length,Length})
    interactive_size!(ratio::Tuple{Number,Number}; index=nothing)

Set the interactive figure size.

If given a `ratio`, calculate the size from the screen parameters so that the figure takes
up the given width/height ratio of the screen. The optional index specifies the screen to
use.

See also [`screen_parameters`](@ref), [`get_interactive_size`](@ref)
"""
function interactive_size!(ratio::Tuple{Number,Number}; index=nothing)
    all(0 .< ratio .<= 1) ||
        throw(ArgumentError("both numbers of ratio must be between 0 and 1"))
    screens = screen_parameters()
    if !isnothing(index)
        screen = screens[index]
    else
        try
            screen = filter!(s -> s.default, screens)
            @assert length(screen) == 1 "Found more than one default screen. Check the output of `MakieMaestro.Themes.screen_parameters()`."
            screen = first(screen)
        catch e
            throw(e)
        end
    end
    interactive_size!(screen.dimensions .* ratio)
    return screen.dimensions .* ratio
end
function interactive_size!(size::Tuple{Length,Length})
    return INTERACTIVE_SIZE[] = size
end
