# TODO: Better ways of setting the override_themes. Especially using the `Symbol`s such as `[:appendix]` in the docs.
# Then workflow docs for publication figures should be changed accordingly <09-01-25> 
# TODO: Possibility of using `skip` for defining the formats for the save <18-10-24> 

"""
    FunctionSpec(fig, args)
Specification of the function generating the figure with its arguments.

Can be called with additional keyword arguments. The arguments are passed from the `args` field.
"""
struct FunctionSpec
    fig::Function
    args::Tuple
end

function FunctionSpec(func::Function)
    return FunctionSpec(func, ())
end

function (fspec::FunctionSpec)(; kwargs...)
    try
        return fspec.fig(fspec.args...; kwargs...)
    catch e
        # NOTE: An error that may occur with the argument cascade is that we call the function with arguments that were
        # passed for the SizeSpec. Warn the user about that the errors indicate that this may be the case. <31-01-25>  
        if (e isa Unitful.DimensionError || e isa MethodError) &&
            (fspec.args[1] isa Length || fspec.args[2] isa Length)
            @warn "An error occured when calling the figure function. You may have passed arguments intended for the `SizeSpec` to the figure function. You may need to pass the first argument explicitely as `MakieMaestro.FunctionSpec(fig_function)`."
        end
        rethrow()
    end
end
Base.nameof(fspec::FunctionSpec) = nameof(fspec.fig)

"""
    PathSpec(basename, [formats], [dirname])
    PathSpec(fullpath, [formats])
Specification of where and which format to use for exporting a figure.

- `basename` is internally a function that takes an index integer and returns the name of the figure. The function is
    created either by a suffix or by parsing the supplied string (see examples below).
- `formats` is a set or collection of formats wanted for the export.
- `dirname` is the directory where the figure will be saved (checked for existence upon creation).

# Examples
```jldoctest; setup=:(using MakieMaestro: PathSpec)
julia> PathSpec("some_file.pdf", ".")
./some_file.pdf

julia> PathSpec("some_file.{svg,eps}", "..")
../some_file.{eps,svg}

julia> PathSpec("some_file.png", "non_existent_dir")
ERROR: ArgumentError: `non_existent_dir` is not a valid directory
[...]

julia> PathSpec("some_file",["pdf", :svg], "..")
../some_file.{pdf,svg}```
"""
struct PathSpec
    basename::Function # takes an index integer and returns the name of the figure
    formats::Set{Format}
    dirname::String # checked for validity on the file-system.

    function PathSpec(basename::Function, formats::Set{Format}, dirname::AbstractString) # 0
        isdir(dirname) || throw(ArgumentError("`$dirname` is not a valid directory"))
        formats = if isempty(formats)
            default = get_export_format()
            @info "Export formats not supplied. Using default formats $default."
            default
        else
            formats
        end
        return new(basename, formats, dirname)
    end
end

function Base.show(io::IO, s::PathSpec)
    extensions = sort([extension(f)[2:end] for f in s.formats])
    ext_string =
        (length(extensions) > 1 ? "{" : "") *
        join(extensions, ",") *
        (length(extensions) > 1 ? "}" : "")
    return print(io, "$(joinpath(s.dirname,s.basename(0))).$ext_string")
end

function PathSpec(fullpath::AbstractString, formats) # 1A ?-> 0 
    dirname, basename = Base.Filesystem.dirname(fullpath),
    Base.Filesystem.basename(fullpath)
    dirname = isempty(dirname) ? get_figure_dir() : dirname
    !isempty(basename) ||
        throw(ArgumentError("Basename of the path cannot be empty. Got `$fullpath`"))
    isempty(splitext(basename)[2]) ||
        @warn "Basename has an extension $(splitext(basename)[2]). This is probably not intensional. Did you mean to supply `formats`?"
    return PathSpec(basename, formats, dirname)
end
function PathSpec(basename::AbstractString, dirname::AbstractString)
    # PERF: Not optimal... Joining strings unnecessarily for later parsing. Should be inexpensive. Avoids necessity to
    # check extension in this method also. <30-01-25> 
    return PathSpec(joinpath(dirname, basename))
end

function PathSpec(basename::AbstractString, formats, dirname::AbstractString)
    return PathSpec(name_function(basename), Set(convert.(Format, formats)), dirname)
end

"""
    PathSpec(fullspec::AbstractString)
"""
function PathSpec(fullspec::AbstractString) # 1B -> 1A -> 0
    fullpath, ext_string = splitext(fullspec)
    if contains(ext_string, ",")
        ext_string = rstrip(ext_string)
        (ext_string[1:2] == ".{" && ext_string[end] == '}') || throw(
            ArgumentError(
                "Invalid name format (missing curly braces). Expected `name.{format1,format2,...}`. Got `$ext_string`.",
            ),
        )
        extensions = split(ext_string[3:(end - 1)], ",")
        formats = Set([parse(Format, strip(ext)) for ext in extensions])
    elseif isempty(ext_string)
        formats = Set()
    else
        formats = Set([parse(Format, ext_string[2:end])])
    end
    return PathSpec(fullpath, formats)
end

# TODO: More options for naming with templates and documentation <28-01-25> 
function name_function(basename::AbstractString; suffix=i -> "_$i")
    function name(i)
        i == 1 &&
            @info "Using `\"$(suffix("i"))\"` name of figure `\"i\"` name. To change this, see documentation of `MakieMaestro.PathSpec`."
        return basename * (i == 0 ? "" : suffix(i))
    end
    return name
end

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
    function SizeSpec(w::Length=Themes.get_width(), hwratio::Real=Themes.get_hwratio()) # 0
        hwratio > 0 || throw(ArgumentError("`hwratio` must be positive. Got `$hwratio`."))
        return new(w, hwratio)
    end
end

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
    return SizeSpec(FigHeight(h), w)
end
SizeSpec(w::Real) = SizeSpec(RelativeSize(w))
SizeSpec(w::Real, hwratio::Real) = SizeSpec(RelativeSize(w), hwratio)
function SizeSpec(w::RelativeSize, hwratio::Real=Themes.get_hwratio()) # 1A -> 0
    return SizeSpec(w.ratio * Themes.get_width(), hwratio)
end
function SizeSpec(h::FigHeight, hwratio::Real=Themes.get_hwratio()) # 2A -> 0
    w = if h.height isa RelativeSize
        h.height.ratio * Themes.get_width()
    else
        h.height / hwratio
    end
    return SizeSpec(w, hwratio)
end
function SizeSpec(h::FigHeight, w::Length) # 2B -> 2A -> 0
    hwratio = if h.height isa RelativeSize
        h.height.ratio * Themes.get_hwratio()
    else
        h.height / uconvert(unit(h.height), w)
    end
    return SizeSpec(w, hwratio) # 2A 
end
function SizeSpec(h::FigHeight, w::RelativeSize) # 2C -> 2B -> 2A -> 0
    return SizeSpec(h, w.ratio * Themes.get_width()) # 2B
end

# NOTE: Argument augmentation cascade for `savefig` ↓ 

function savefig(fig::Function, args...; kwargs...)
    return savefig(fig, (), args...; kwargs...)
end

function savefig(fig::Function, fig_args::Tuple, args...; kwargs...) # 1A -> 0
    return savefig(FunctionSpec(fig, fig_args), args...; kwargs...)
end

function savefig(fig::FunctionSpec, fullspec::AbstractString, args...; kwargs...) # 2A -> 0
    return savefig(fig, PathSpec(fullspec), args...; kwargs...)
end

function savefig(fig::FunctionSpec, args...; kwargs...) # 2B -> 2A -> 0
    return savefig(fig, String(nameof(fig)), args...; kwargs...)
end

# TODO: Look into the possibility of using 
# const FormatSpec = Union{String, Symbol, Format}
# const Formats = Union{FormatSpec, AbstractVector{<:FormatSpec}, AbstractSet{<:FormatSpec}, Tuple{Vararg{FormatSpec}}} 
# same as in with `Chars` in julia `Base` module. <28-01-25> 

# NOTE: `Tuple` as a sequence of formats is not included in these two methods because it can be confused with the
# `SizeSpec` `(w,h)` tuple. <31-01-25>
function savefig(
    fig::FunctionSpec, name::AbstractString, formats::Union{Vector,Set}, args...; kwargs...
) # 2B -> 2A -> 0
    return savefig(fig, PathSpec(name, formats), args...; kwargs...)
end

function savefig(
    fig::FunctionSpec,
    name::AbstractString,
    formats::Union{Vector,Set},
    dir::AbstractString,
    args...;
    kwargs...,
) # 2C -> 2A -> 0
    return savefig(fig, PathSpec(name, formats, dir), args...; kwargs...)
end

function savefig(
    fig::FunctionSpec, name::AbstractString, dir::AbstractString, args...; kwargs...
) # 2D -> 2A -> 0
    return savefig(fig, PathSpec(name, dir), args...; kwargs...)
end

function savefig(fig::FunctionSpec, path::PathSpec, args...; kwargs...) # 3A -> 0
    return savefig(fig, path, SizeSpec(args...); kwargs...)
end

export FigHeight
