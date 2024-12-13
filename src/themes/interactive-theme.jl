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
    screen_parameters() -> Vector{ScreenInfo}

Retrieve information about available screens using the `xdpyinfo` command.

This function parses the output of `xdpyinfo` to extract details about each screen,
including its index, dimensions in pixels and millimeters, and whether it's the default
screen.

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
            INTERACTIVE_SIZE not set! Use Themes.interactive_size!(ratio) or
            MakieMaestro.interactive_size!((width, height)) to set it before showing
            a figure.
            """,
        ),
    )
    return INTERACTIVE_SIZE[]
end
