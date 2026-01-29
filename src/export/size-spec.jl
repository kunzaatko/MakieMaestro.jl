# FIX: Unintuitive order of width and height. Also width and height in printing is not aligned with width and height in
# arguments (tuple). <30-01-25> 

"""
    MakieMaestro.SizeSpec(width::Length, hwratio::Real)
Specification of the physical size of the exported image.

The primary way to represent the size of a figure is it's `width` and the height to width ratio `hwratio`. However, any
set of two values from {`width`, `hwratio`, `height`} fully determine the size. `width` and `height` may be either fixed
values of the type [`Length`](@extref Unitful Length) or relative sizes to their default values by the type `Real`
([`RelativeSize`](@ref)). None, one or two of the values may be supplied and the size is determined from these values
and the defaults. These defaults may be set with [`width!`](@ref Themes.width!) and [`hwratio!`](@ref Themes.hwratio!).

See also [`Themes.width!`](@ref), [`Themes.get_width`](@ref), [`Themes.hwratio!`](@ref), [`Themes.get_hwratio`](@ref)

# Examples
```jldoctest; setup=:(using MakieMaestro.Themes; using MakieMaestro: SizeSpec)
julia> Themes.width!(Themes.A4_WIDTH), Themes.hwratio!(2/(√(5) + 1));

julia> SizeSpec(0.5, 2)
w×h: 105.0 mm × 210.0 mm [h/w: 2.0]

julia> SizeSpec(10u"cm")
w×h: 10.0 cm × 6.18 cm [h/w: 2/(√5 + 1)]

julia> SizeSpec((15u"cm", 10u"cm"))
w×h: 10.0 cm × 15.0 cm [h/w: 1.5]

julia> SizeSpec((15u"cm", 0.5))
w×h: 105.0 mm × 150.0 mm [h/w: 1.4]

julia> SizeSpec((2, 10u"cm"))
w×h: 10.0 cm × 12.36 cm [h/w: 1.2]
```
"""
struct SizeSpec
    width::Length
    hwratio::Real
    logs::Dict{String,Any}
    function SizeSpec(w::Length, hwratio::Real, logs::Dict{String,Any}) # 0
        hwratio > 0 || throw(ArgumentError("`hwratio` must be positive. Got `$hwratio`."))
        return new(w, hwratio, logs)
    end
end
function SizeSpec()
    logs = Dict{String,Any}()
    logs["args"] = InlineDict{String,Any}()
    logs["args"]["default_width"] = true

    return SizeSpec(Themes.get_width(), logs)
end
function SizeSpec(w::Length, logs::Dict=Dict{String,Any}())
    haskey(logs, "args") || (logs["args"] = InlineDict{String,Any}())
    logs["args"]["width"] = string(w)
    logs["args"]["default_hwratio"] = true

    return SizeSpec(w, Themes.get_hwratio(), logs)
end
function SizeSpec(w::Length, hwratio::Real) # final
    logs = Dict{String,Any}()
    logs["args"] = InlineDict{String,Any}()
    logs["args"]["width"] = string(w)
    logs["args"]["hwratio"] = hwratio

    return SizeSpec(w, hwratio, logs)
end

logs(s::SizeSpec) = s.logs

function Base.repr(s::SizeSpec)
    return "SizeSpec($(repr(ustrip(s.width)))u\"$(repr(unit(s.width)))\", $(repr(s.hwratio)))"
end

function Base.show(io::IO, s::SizeSpec)
    hwratio = if s.hwratio == float(2 / (√(5) + 1))
        "2/(√5 + 1)"
    else
        string(round(s.hwratio; sigdigits=2))
    end
    w, h = round.(typeof(float(s.width)), (s.width, s.hwratio * s.width); digits=2)
    return print(io, "w×h: $w × $h [h/w: $hwratio]")
end

"""
    MakieMaestro.RelativeSize(ratio::Real)
Size relative to the default or calculated dimensions.
"""
struct RelativeSize
    ratio::Real
    function RelativeSize(r)
        r > 0 || throw(ArgumentError("`ratio` must be positive. Got `$r`."))
        return new(r)
    end
end

"""
    FigHeight(height::Length)
    FigHeight(height::Real) # relative size to the default
Specifies the height of the exported figure.

See also [`RelativeSize`](@ref).
"""
struct FigHeight
    height::Union{Length,RelativeSize}
end
FigHeight(h::Real) = FigHeight(RelativeSize(h))

function SizeSpec(hw::Tuple)
    h, w = map(s -> s isa Real ? RelativeSize(s) : s, hw)

    logs = Dict{String,Any}("args" => InlineDict{String,Any}())

    if h isa RelativeSize
        logs["args"]["relative_height"] = h.ratio
    else
        logs["args"]["height"] = string(h)
    end

    if w isa RelativeSize
        logs["args"]["relative_width"] = w.ratio
    else
        logs["args"]["width"] = string(w)
    end

    return SizeSpec(FigHeight(h), w, logs)
end
function SizeSpec(w::Union{Real,RelativeSize})
    logs = Dict{String,Any}("args" => InlineDict{String,Any}("default_hwratio" => true))
    w = w isa Real ? RelativeSize(w) : w
    return SizeSpec(w, Themes.get_hwratio(), logs)
end
SizeSpec(w::Real, hwratio::Real) = SizeSpec(RelativeSize(w), hwratio)
function SizeSpec(w::RelativeSize, hwratio::Real, logs::Dict=Dict{String,Any}()) # 1A -> 0
    haskey(logs, "args") || (logs["args"] = InlineDict{String,Any}())
    logs["args"]["relative_width"] = w.ratio
    logs["args"]["default_width"] = true
    logs["args"]["hwratio"] = hwratio

    return SizeSpec(w.ratio * Themes.get_width(), hwratio, logs)
end
function SizeSpec(h::FigHeight)
    logs = Dict{String,Any}("args" => InlineDict())
    logs["args"]["default_hwratio"] = true

    return SizeSpec(h, Themes.get_hwratio(), logs)
end
function SizeSpec(h::FigHeight, hwratio::Real, logs::Dict=Dict{String,Any}()) # 2A -> 0
    haskey(logs, "args") || (logs["args"] = InlineDict{String,Any}())
    logs["args"]["hwratio"] = hwratio

    w = if h.height isa RelativeSize
        logs["args"]["relative_height"] = h.height.ratio
        h.height.ratio * Themes.get_width()
    else
        logs["args"]["height"] = string(h.height)
        h.height / hwratio
    end
    return SizeSpec(w, hwratio, logs)
end
function SizeSpec(h::FigHeight, w::Length, logs::Dict=Dict{String,Any}(); logwidth=true) # 2B -> 2A -> 0
    haskey(logs, "args") || (logs["args"] = InlineDict{String,Any}())
    logwidth && (logs["args"]["width"] = string(w))

    hwratio = if h.height isa RelativeSize
        logs["args"]["relative_height"] = h.height.ratio
        h.height.ratio * Themes.get_hwratio()
    else
        logs["args"]["height"] = string(h.height)
        h.height / uconvert(unit(h.height), w)
    end
    return SizeSpec(w, hwratio, logs) # 2A 
end
function SizeSpec(h::FigHeight, w::RelativeSize, logs::Dict=Dict{String,Any}()) # 2C -> 2B -> 2A -> 0
    haskey(logs, "args") || (logs["args"] = InlineDict{String,Any}())
    logs["args"]["relative_width"] = w.ratio
    logs["args"]["default_width"] = true

    return SizeSpec(h, w.ratio * Themes.get_width(); logwidth=false) # 2B
end

Base.:(==)(s1::SizeSpec, s2::SizeSpec) = s1.width == s2.width && s1.hwratio == s2.hwratio # do not compare logs
