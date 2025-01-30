# TODO: Argument for `width` should support relative width that will select the width based on the default by a factor.
# This could be done by some type that holds a factor. <25-01-25> 

# TODO: The arguments for the name should first be parsed to some type that holds the optional type and the generator or
# fixed list off names that are given to the figures that will be saved. <25-01-25> 

# TODO: Support templating for the names and DEDUCTION OF THE FORMAT FROM THE SUPPLIED NAME. For instance when function
# returns multiple figures, it should be possible to name something like `["{}_surface", "{}_heatmap"]` and interpolate
# the original name into the templates. <09-01-25> 
# TODO: Possibility to define formats in more human-like ways and transform them into the computer way using some
# parsing function. For instance it should be possible to pass ["pdf", "svg", "pdf_tex", MakieMaestro.Eps, :png] etc.
# Then workflow docs for publication figures should be changed accordingly. <09-01-25> 
# TODO: Better ways of setting the override_themes. Especially using the `Symbol`s such as `[:appendix]` in the docs.
# Then workflow docs for publication figures should be changed accordingly <09-01-25> 
# TODO: Possibility of using `skip` for defining the formats for the save <18-10-24> 
# TODO: Define other methods here based on the argument types. No name change but different width. No width and hwratio,
# but width, height instead, etc. <08-01-25>

# TODO: Currently does not support keyword arguments. How do I get these? Would it be better to store the function call
# as code? I.e. a syntax tree? Then I could call the function exactly in that way at the place where it is necessary.
# This would however be probably fragile and programmatically complex <28-01-25> 
struct FunctionSpec
    fig::Function
    args::Tuple
end

function FunctionSpec(func::Function)
    return FunctionSpec(func, ())
end

(fspec::FunctionSpec)(; kwargs...) = fspec.fig(fspec.args...; kwargs...)
Base.nameof(fspec::FunctionSpec) = nameof(fspec.fig)

struct PathSpec
    basename::Function # takes an index integer and returns the name of the figure
    formats::Set{Format}
    dirname::String # checked for validity on the file-system.

    function PathSpec(
        basename::Function, formats::Set{Format}, dirname::AbstractString
    ) # 0
        isdir(dirname) || throw(ArgumentError("`$dirname` is not a valid directory"))
        formats = if isempty(formats)
            default = get_export_formats()
            @info "Export formats not supplied. Using default formats $default."
            default
        else
            formats
        end
        return new(basename, formats, dirname)
    end
end

"""
    PathSpec(fullpath::AbstractString, formats::Set{Format})
Create a spec for formats names and the directory where the figures will be saved.
"""
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

Base.convert(f::Type{Format}, s::AbstractString) = parse(f, s)
Base.convert(f::Type{Format}, s::Symbol) = convert(f, string(s))

function PathSpec(basename::AbstractString, formats, dirname::AbstractString)
    return PathSpec(
        name_function(basename), Set(convert.(Format, formats)), dirname
    )
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
        i == 1 && @info "Using `\"$(suffix("i"))\"` name of figure `\"i\"` name. To change this, see documentation of `MakieMaestro.PathSpec`."
        return basename * (i == 0 ? "" : suffix(i))
    end
    return name
end

# FIX: Can be done much more elegantly with use of some Unions and abstract types with methods defined on them! <28-01-25> 
struct SizeSpec
    width::Length
    hwratio::Real
    function SizeSpec(w::Length=Themes.get_width(), hwratio::Real=Themes.get_hwratio()) # 0
        hwratio > 0 || throw(ArgumentError("`hwratio` must be positive. Got `$hwratio`."))
        return new(w, hwratio)
    end
end

struct RelativeSize
    ratio::Real
    function RelativeSize(r)
        r > 0 || throw(ArgumentError("`ratio` must be positive. Got `$r`."))
        return new(r)
    end
end

struct HeightLength
    height::Union{Length,RelativeSize}
end
HeightLength(h::Real) = HeightLength(RelativeSize(h))

SizeSpec(a::Real, args...) = SizeSpec(RelativeSize(a), args...)
function SizeSpec(w::RelativeSize, hwratio::Real=Themes.get_hwratio()) # 1A -> 0
    return SizeSpec(w.ratio * Themes.get_width(), hwratio)
end
function SizeSpec(h::HeightLength, hwratio::Real=Themes.get_hwratio()) # 2A -> 0
    w = if h.height isa RelativeSize
        h.height.ratio * Themes.get_width()
    else
        h.height / hwratio
    end
    return SizeSpec(w, hwratio)
end
function SizeSpec(h::HeightLength, w::Length) # 2B -> 2A -> 0
    hwratio = if h.height isa RelativeSize
        h.height.ratio * Themes.get_hwratio()
    else
        h.height / w
    end
    return SizeSpec(w, hwratio) # 2A 
end
function SizeSpec(h::HeightLength, w::RelativeSize) # 2C -> 2B -> 2A -> 0
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

function savefig(
    fig::FunctionSpec,
    name::AbstractString,
    formats::Union{Tuple,Vector,Set},
    args...;
    kwargs...,
) # 2B -> 2A -> 0
    return savefig(fig, PathSpec(name, formats), args...; kwargs...)
end

function savefig(
    fig::FunctionSpec,
    name::AbstractString,
    formats::Union{Tuple,Vector,Set},
    dir::AbstractString,
    args...;
    kwargs...,
) # 2C -> 2A -> 0
    return savefig(fig, PathSpec(name, formats, dir), args...; kwargs...)
end

function savefig(fig::FunctionSpec, path::PathSpec, args...; kwargs...) # 3A -> 0
    return savefig(fig, path, SizeSpec(args...); kwargs...)
end

export HeightLength
