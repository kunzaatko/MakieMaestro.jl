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
const HWRATIO_DEFAULT = Ref{Number}(0.68)

"""
    hwratio!(val)
Set the default height-width ratio for figures.

```julia_repl
julia> MakieMaestro.hwratio!(0.8)
```
"""
function hwratio!(val::Number)
    return HWRATIO_DEFAULT[] = val
end

"""
    get_hwratio()
Get the default height-width ratio for figures
"""
get_hwratio() = HWRATIO_DEFAULT[]

"""
    width!(val)
Set the default width for figures.

```julia_repl
julia> MakieMaestro.width!(177u"mm" * 0.8)
```
"""
function width!(val::Length)
    return WIDTH_DEFAULT[] = val
end

"""
    to_units(val::Length)
Convert `val` to Makie figure units
"""
function to_units(val::Length)
    return ustrip(uconvert(u"pt", val))
end

"""
    get_width()
Get the default figure width
"""
function get_width()
    ismissing(WIDTH_DEFAULT[]) && throw(
        ErrorException(
            """
            WIDTH_DEFAULT not set! Use MakieMaestro.Themes.width!(val) to set it before saving a figure.
            """,
        ),
    )
    return WIDTH_DEFAULT[]
end

# TODO: Add some function that sets all the necessary variables at once <17-10-24>

struct ScreenInfo
    default::Union{Missing,Bool}
    index::Int
    size::Tuple{Int,Int}
    dimesions::Tuple{Length,Length}
end
if isnothing(Sys.which("xdpyinfo"))
    function screen_parameters(args...)
        throw(
            ErrorException(
                "`xdypinfo` not available. This is not implemented for your system."
            ),
        )
    end
else
    # TODO: Test... <17-10-24> 
    # TODO: Handle the cases, where the matches do not match or we reach the end of the output String <17-10-24> 
    function screen_parameters()
        screens = ScreenInfo[]
        default = missing
        info = read(`xdpyinfo`, String)
        lines = collect(eachline(IOBuffer(info)))
        i = 0
        while i != length(lines)
            i += 1
            if startswith(lines[i], r"default screen number:")
                m_default = match(r"default screen number:\s+(\d+)", lines[i])
                isnothing(m_default) && continue
                @assert length(m_default.captures) == 1
                default = parse(Int, m_default.captures[1])
                i += 1
            end
            if startswith(lines[i], r"screen")
                m_index = match(r"screen #(\d+):", lines[i])
                isnothing(m_index) && continue
                @assert length(m_index.captures) == 1
                index = parse(Int, m_index.captures[1])
                i += 1
                while !startswith(lines[i], r"\s+dimensions:")
                    i += 1
                end
                m_size_dimensions = match(
                    r"dimensions:\s+(\d+)x(\d+) pixels \((\d+)x(\d+) millimeters\)",
                    lines[i],
                )
                isnothing(m_size_dimensions) && continue
                @assert length(m_size_dimensions.captures) == 4
                w, h, w_mm, h_mm = map(d -> parse(Int, d), m_size_dimensions.captures)
                push!(
                    screens,
                    ScreenInfo(
                        ismissing(default) ? missing : index == default,
                        index,
                        (w, h),
                        (w_mm, h_mm) .* u"mm",
                    ),
                )
            end
        end
        return screens
    end
end

@doc raw"""
    screen_parameters() -> Vector{ScreenInfo}

Retrieve information about available screens using the `xdpyinfo` command.

This function parses the output of `xdpyinfo` to extract details about each screen,
including its index, dimensions in pixels and millimeters, and whether it's the default screen.

Returns:
- A vector of `ScreenInfo` objects, each containing details about a screen.

Note:
- This function relies on the `xdpyinfo` command and is therefore only compatible with
    systems where this command is available (typically Unix-like systems with X11).
- The function may return an empty vector if no screens are detected or if parsing fails.
- Requires the Unitful.jl package for handling millimeter units.

Example:
```julia
screens = screen_parameters()
for screen in screens
    println("Screen $(screen.index): $(screen.size_px) pixels, $(screen.size_mm) physical size")
end
```
""" screen_parameters

INTERACTIVE_SIZE = Ref{Union{Missing,Tuple{Length,Length}}}(missing)

function get_interactive_size()
    if ismissing(INTERACTIVE_SIZE[])
        try
            interactive_size!((0.8, 0.8))
        catch e
            throw(e)
        end
    end
    ismissing(INTERACTIVE_SIZE[]) && throw(
        ErrorException(
            """
            INTERACTIVE_SIZE not set! Use MakieMaestro.interactive_size!(ratio) or MakieMaestro.interactive_size!((width, height)) to set it before showing a figure.
            """,
        ),
    )
    return INTERACTIVE_SIZE[]
end

# NOTE: This does not make much sense for GLMakie. It does however for WGLMakie since it does not create its own window. <17-10-24> 
"""
    interactive_size!(ratio::Tuple{Number,Number}; index=nothing) -> Tuple

Calculate the interactive size based on the given ratio and screen parameters.

# Arguments
- `ratio::Tuple{Number,Number}`: A tuple of two numbers between 0 and 1 representing the ratio of the screen size.
- `index::Union{Nothing,Int}`: Optional. If provided, uses the screen parameters at the specified index.

# Returns
A tuple representing the calculated interactive size.

# Throws
- `ArgumentError`: If the ratio is not between 0 and 1.
- Any error that might occur when filtering for the default screen.

# Description
This function calculates the interactive size by multiplying the screen size with the provided ratio. 
If an index is provided, it uses the screen parameters at that index. Otherwise, it attempts to use 
the default screen parameters.
"""
function interactive_size!(ratio::Tuple{Number,Number}; index=nothing)
    0 < ratio <= 1 || throw(ArgumentError("ratio must be between 0 and 1"))
    screens = screen_parameters()
    if !isnothing(index)
        screen = screens[index]
    else
        try
            screen = filter!(s -> s.default, screens)
        catch e
            throw(e)
        end
    end
    interactive_size!(screen.size .* ratio)
    return get_interactive_size()
end
function interactive_size!(size::Tuple{Length,Length})
    return INTERACTIVE_SIZE[] = size
end
