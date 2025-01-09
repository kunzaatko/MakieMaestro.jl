"""
    MakieMaestro.Themes.ScreenInfo

# Fields
* `default::Union{Missing,Bool}` -- X11 default screen
* `index::Int` -- X11 screen index
* `size::Tuple{Int,Int}` -- pixel dimensions of the display
* `dimensions::Tuple{Length,Length}` -- physical dimensions of the display
"""
struct ScreenInfo
    default::Union{Missing,Bool}
    index::Int
    size::Tuple{Int,Int}
    dimensions::Tuple{Length,Length}
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
    # FIX: On multiple displays it returns the sum of the virtual displays. That is, if the displays are next to
    # each other, it returns there width summed up. <13-12-24> 
    # TODO: Is there a julia library that can handle this instead of using my own implementation? <13-12-24> 
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
    screen_parameters()

Retrieve information about available screens (`Vector{ScreenInfo}`) using the `xdpyinfo` command.

This function parses the output of `xdpyinfo` to extract details about each screen,
including its index, dimensions in pixels and millimeters, and whether it's the default
screen.

# Examples
```julia
screens = screen_parameters()
for screen in screens
    println("Screen $(screen.index): $(screen.size) pixels, $(screen.dimensions) physical size")
end
# Screen 0: (4080, 1920) pixels, (1072 mm, 504 mm) physical size
```

See also [`ScreenInfo`](@ref)

# Extended help
- This function relies on the `xdpyinfo` command and is therefore only compatible with
    systems where this command is available (typically Unix-like systems with X11).
- The function may return an empty vector if no screens are detected or if parsing fails.
- Requires the Unitful.jl package for handling millimeter units.
""" screen_parameters

INTERACTIVE_SIZE = Ref{Union{Missing,Tuple{Length,Length}}}(missing)

"""
    get_interactive_size()

Retrieve the current interactive size setting for figures.

This function checks the global `INTERACTIVE_SIZE` variable and returns its value.
If `INTERACTIVE_SIZE` is not set (i.e., it's `missing`), it attempts to set a default
size of 80% of the screen dimensions using `interactive_size!((0.8, 0.8))`.

See also [`interactive_size!`](@ref)

# Throws
- `ErrorException`: If `INTERACTIVE_SIZE` is not set and the function fails to set a default value.
"""
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
            INTERACTIVE_SIZE not set! Use Themes.interactive_size!(ratio) or
            MakieMaestro.interactive_size!((width, height)) to set it before showing
            a figure.
            """
        ),
    )
    return INTERACTIVE_SIZE[]
end
