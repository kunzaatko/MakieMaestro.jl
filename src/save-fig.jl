# TODO: Add the functionality using the getters and update the function to the current API <17-10-24> 
using CairoMakie, GLMakie, Serialization

const FIGURE_DIR = Ref{Union{Missing,String}}(missing)
"""
    figure_dir!(dir)
Set the figure directory

# Examples
```jldoctest
julia> figure_dir!(".");
```
"""
function figure_dir!(dir::AbstractString)
    isdir(dir) || throw(ArgumentError("$dir is not a valid directory"))
    return FIGURE_DIR[] = abspath(dir)
end

"""
    MakieMaestro.get_figure_dir()
Get the figure directory

# Examples
```jldoctest
julia> figure_dir!("/tmp")
"/tmp"

julia> MakieMaestro.get_figure_dir()
"/tmp"
```
"""
function get_figure_dir()
    if ismissing(FIGURE_DIR[])
        cwd = abspath(".")
        @warn "Figure directory not set. Using default value: You may set it by calling `MakieMaestro.figure_dir!(dir)`. Using current working directory \"$cwd\""
        return cwd
    else
        return FIGURE_DIR[]
    end
end

@enum Format Png Svg Eps Pdf PdfTex
const FORMATS = Set([Png, Svg, Eps, Pdf, PdfTex])
extension_pairs = [Svg => "svg", Pdf => "pdf", Eps => "eps", Png => "png"]
const EXTENSIONS = Dict([extension_pairs..., PdfTex => "pdf"]) # NOTE: For uniqueness, it is necessary to separate `PdfTex` since it has the same extension as `Pdf`, but within the parsing context, we want to recognise "pdf" as `Pdf`.  
const EXTENSIONS_REVERSE = Dict(reverse.(extension_pairs))

function Base.parse(::Type{Format}, x::AbstractString)
    x == "pdf_tex" && return PdfTex
    x in values(EXTENSIONS) && return EXTENSIONS_REVERSE[x]
    throw(ArgumentError("$x is not a valid format"))
end

# TODO: Should this be Pdf as the default or should this be explicitly left to the user to specify? <28-01-25> 
const FORMATS_DEFAULT = Ref{Union{Set{Format},Missing}}(missing)
# TODO: Should accept various options for the format definitions. `String`/`Symbol`/`Format` <28-01-25> 
"""
    default_formats!(formats)
Set the default formats to export.
"""
function default_formats!(formats)
    return FORMATS_DEFAULT[] = formats
end

"""
    MakieMaestro.get_default_formats()
Get the default export formats

# Examples
```jldoctest
julia> default_formats!(Set([MakieMaestro.Pdf]))
Set{MakieMaestro.Format} with 1 element:
  MakieMaestro.Pdf

julia> MakieMaestro.get_default_formats()
Set{MakieMaestro.Format} with 1 element:
  MakieMaestro.Pdf

julia> default_formats!(missing);
```
"""
function get_default_formats()
    ismissing(FORMATS_DEFAULT[]) && throw(
        ErrorException(
            """
            DEFAULT_FORMATS not set! Use MakieMaestro.default_formats!(formats) to set the default formats for exporting before saving a figure.
            """,
        ),
    )
    return FORMATS_DEFAULT[]
end

"""
    MakieMaestro.isvectorgraphic(x::Format)
Return `true` if `x` is a vector graphic format, `false` otherwise.

# Examples
```jldoctest
julia> MakieMaestro.isvectorgraphic(MakieMaestro.Pdf)
true

julia> MakieMaestro.isvectorgraphic(MakieMaestro.Png)
false
```
"""
isvectorgraphic(x) = x ∈ [Svg, Eps, PdfTex, Pdf] ? true : false

"""
    MakieMaestro.skip(skips::Vararg{Union{Symbol,Format}})
Return a `Set{Format}` of allowed formats by excluding specified formats or format groups.

Useful for customizing the output formats when saving figures,
allowing you to easily exclude certain format types or groups of formats.

# Arguments
- `skips`: Variable number of arguments specifying formats or format groups to exclude.
           Can be individual `Format` types or symbols `:raster` or `:vector`.

# Examples
```jldoctest
julia> @assert MakieMaestro.skip(:raster) == Set([MakieMaestro.PdfTex, MakieMaestro.Eps, MakieMaestro.Svg, MakieMaestro.Pdf])

julia> @assert MakieMaestro.skip(:vector) == Set([MakieMaestro.Png])

julia> @assert MakieMaestro.skip(MakieMaestro.Pdf, MakieMaestro.Svg) == Set([MakieMaestro.PdfTex, MakieMaestro.Png, MakieMaestro.Eps])
```
"""
function skip(skips::Vararg{Union{Symbol,Format}})
    deny = Set()
    for s in skips
        if s == :raster
            push!(deny, Png)
            continue
        elseif s == :vector
            foreach(f -> push!(deny, f), [Pdf, Eps, PdfTex, Svg])
        else
            push!(deny, s)
        end
    end
    return setdiff(FORMATS, deny)
end

"""
    MakieMaestro.extension(format::Format)
Return the string of the extension from the given `format`.

# Examples
```jldoctest
julia> MakieMaestro.extension(MakieMaestro.Png)
".png"

julia> MakieMaestro.extension(MakieMaestro.PdfTex)
".pdf"
```
"""
function extension(format::Format)::String
    return "." * EXTENSIONS[format]
end

"""
    MakieMaestro.backend_formats(backend::Module,...)
Return the set of compatible formats for given `backend`s.

# Examples
```jldoctest
julia> @assert Set([ MakieMaestro.Png, MakieMaestro.Eps, MakieMaestro.Svg, MakieMaestro.Pdf ]) ⊆ MakieMaestro.backend_formats(CairoMakie) 

julia> @assert MakieMaestro.backend_formats(GLMakie) == Set([MakieMaestro.Png])
```
"""
function backend_formats(backends::Vararg{Module})::Set{Format}
    formats = union(
        map(b -> b == CairoMakie ? Set([Svg, Pdf, Eps, Png]) : Set([Png]), backends)...
    )
    if CairoMakie in backends && Sys.which("inkscape") !== nothing
        push!(formats, PdfTex)
    end
    return formats
end

"""
    MakieMaestro.get_formats(backends::Vector{Module}, formats::Set{Format})
Return the set of formats to generate based on the given `backends` required `formats`. Output is in the correct order for export.

# Examples
```jldoctest
julia> (Sys.which("inkscape") === nothing) || MakieMaestro.Svg ∈ MakieMaestro.get_formats([CairoMakie], Set([MakieMaestro.PdfTex])) # Added Svg so the PdfTex is possible to create
true

julia> MakieMaestro.get_formats([GLMakie], Set([MakieMaestro.Pdf]))
ERROR: ArgumentError: None of the backends Module[GLMakie] support the formats Set(MakieMaestro.Format[MakieMaestro.Pdf])
[...]

julia> MakieMaestro.get_formats([CairoMakie, GLMakie], Set([MakieMaestro.Png, MakieMaestro.Svg]))
2-element Vector{MakieMaestro.Format}:
 Svg::Format = 1
 Png::Format = 0
```
"""
function get_formats(backends::Vector{Module}, formats::Set{Format})
    if PdfTex in formats && !(Svg in formats)
        @warn "PdfTex can only be used if Svg is also generated. Adding Svg to allowed formats."
        push!(formats, Svg)
    end
    backend_pruned_formats = intersect(backend_formats(backends...), formats)
    backend_pruned_formats == formats || throw(
        ArgumentError(
            "None of the backends $backends support the formats $(setdiff(formats, backend_pruned_formats))",
        ),
    )

    formats = collect(intersect(backend_formats(backends...), formats))
    sort!(formats; by=f -> f == Svg ? 1 : 2) # NOTE: pdf_tex is reliant on svg so it has to go first
    return formats
end

"""
    MakieMaestro.choose_backend(backends::Vector{Module}, f::Format)
Select the best backend from `backends` to export a figure in the format `f`.

Prefers `CairoMakie` for most formats unless the format is `Png` and `GLMakie` is available.

# Examples
```jldoctest
julia> MakieMaestro.choose_backend([CairoMakie, GLMakie], MakieMaestro.Svg)
CairoMakie

julia> MakieMaestro.choose_backend([WGLMakie], MakieMaestro.Eps)
ERROR: None of the backends support the format Eps
[...]
```
"""
function choose_backend(backends::Vector{Module}, f::Format)
    if CairoMakie ∈ backends
        return CairoMakie
    elseif f == Png && GLMakie ∈ backends
        return GLMakie
    else
        throw(ErrorException("None of the backends support the format $f"))
    end
end

"""
    MakieMaestro.get_themes(backend::Module, format::Format)
Get the modification themes associated with the `backend` and `format`.

# Examples
```jldoctest
julia> MakieMaestro.get_themes(CairoMakie, MakieMaestro.PdfTex)
2-element Vector{Symbol}:
 :cairomakie
 :vector

julia> MakieMaestro.get_themes(GLMakie, MakieMaestro.Png)
2-element Vector{Symbol}:
 :glmakie
 :raster
```
"""
function get_themes(backend::Module, format::Format)
    backend_theme(b) = b == CairoMakie ? :cairomakie : :glmakie
    format_theme(x) = isvectorgraphic(x) ? :vector : :raster
    return [backend_theme(backend), format_theme(format)]
end

"""
    MakieMaestro.get_export_theme(backend, format, width, hwratio, override_theme...)
Create the final export theme applied when generating the figure.

# Examples
```jldoctest
julia> MakieMaestro.get_export_theme(CairoMakie, MakieMaestro.Png, 10u"cm", 0.8,
           Theme(;
               CairoMakie=(;pdf_version=1.1)
           ),
           Theme(;
               Scatter=(;markersize=8)
           )
       )
Attributes with 12 entries:
  Axis => Attributes with 8 entries:
    xgridvisible => false
    xticklabelsize => 10
    xticksize => 4
    xtickwidth => 0.7
    ygridvisible => false
    yticklabelsize => 10
    yticksize => 4
    ytickwidth => 0.7
  backgroundcolor => transparent
  CairoMakie => Attributes with 1 entry:
    pdf_version => 1.1
  Colorbar => Attributes with 9 entries:
    bottomspinevisible => false
    labelsize => 10
    leftspinevisible => false
    rightspinevisible => false
    ticklabelsize => 10
    ticksize => 4
    tickwidth => 0.7
    topspinevisible => false
    width => 5
  figure_padding => 2
  fonts => Attributes with 4 entries:
    bold => FTFont (family = NewComputerModern, style = 10 Bold)
    bolditalic => FTFont (family = NewComputerModern, style = 10 Bold Italic)
    italic => FTFont (family = NewComputerModern, style = 10 Italic)
    regular => FTFont (family = NewComputerModern Math, style = Regular)
  Heatmap => Attributes with 1 entry:
    colormap => Spectral
  Image => Attributes with 1 entry:
    interpolate => false
  Legend => Attributes with 5 entries:
    framevisible => false
    labelsize => 10
    nbanks => 1
    tellheight => false
    tellwidth => false
  Lines => Attributes with 1 entry:
    cycle => Cycle([[:color]=>:color, [:marker]=>:marker], true)
  Scatter => Attributes with 3 entries:
    cycle => Cycle([[:color]=>:color, [:marker]=>:marker], true)
    markersize => 8
    strokewidth => 0
  size => (283, 226)
```
"""
function get_export_theme(backend, format, width, hwratio, override_theme...)
    return Themes.get_theme(
        :base,
        get_themes(backend, format)...,
        Themes.gen(:size)(width, hwratio),
        override_theme...,
    )
end

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

(fspec::FunctionSpec)() = fspec.fig(fspec.args...)
Base.nameof(fspec::FunctionSpec) = nameof(fspec.fig)

struct PathNameFormatSpec
    basename::Function # takes an index integer and returns the name of the figure
    formats::Set{Format}
    dirname::String # checked for validity on the file-system.

    function PathNameFormatSpec(
        basename::Function, formats::Set{Format}, dirname::AbstractString
    ) # 0
        isdir(dirname) || throw(ArgumentError("`$dirname` is not a valid directory"))
        formats = if isempty(formats)
            default = get_default_formats()
            @info "Export formats not supplied. Using default formats $default."
            default
        else
            formats
        end
        return new(basename, formats, dirname)
    end
end

"""
    PathNameFormatSpec(fullpath::AbstractString, formats::Set{Format})
Create a spec for formats names and the directory where the figures will be saved.
"""
function PathNameFormatSpec(fullpath::AbstractString, formats) # 1A ?-> 0 
    dirname, basename = Base.Filesystem.dirname(fullpath),
    Base.Filesystem.basename(fullpath)
    dirname = isempty(dirname) ? get_figure_dir() : dirname
    !isempty(basename) ||
        throw(ArgumentError("Basename of the path cannot be empty. Got `$fullpath`"))
    isempty(splitext(basename)[2]) ||
        @warn "Basename has an extension $(splitext(basename)[2]). This is probably not intensional. Did you mean to supply `formats`?"
    return PathNameFormatSpec(basename, formats, dirname)
end

Base.convert(f::Type{Format}, s::AbstractString) = parse(f, s)
Base.convert(f::Type{Format}, s::Symbol) = convert(f, string(s))

function PathNameFormatSpec(basename::AbstractString, formats, dirname::AbstractString)
    return PathNameFormatSpec(
        name_function(basename), Set(convert.(Format, formats)), dirname
    )
end

"""
    PathNameFormatSpec(fullspec::AbstractString)
"""
function PathNameFormatSpec(fullspec::AbstractString) # 1B -> 1A -> 0
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
    return PathNameFormatSpec(fullpath, formats)
end

# TODO: More options for naming with templates and documentation <28-01-25> 
function name_function(basename::AbstractString; suffix=i -> "_$i")
    return i::Int -> basename * (i == 0 ? "" : suffix(i))
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
    return savefig(fig, PathNameFormatSpec(fullspec), args...; kwargs...)
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
    return savefig(fig, PathNameFormatSpec(name, formats), args...; kwargs...)
end

function savefig(
    fig::FunctionSpec,
    name::AbstractString,
    formats::Union{Tuple,Vector,Set},
    dir::AbstractString,
    args...;
    kwargs...,
) # 2C -> 2A -> 0
    return savefig(fig, PathNameFormatSpec(name, formats, dir), args...; kwargs...)
end

function savefig(fig::FunctionSpec, path::PathNameFormatSpec, args...; kwargs...) # 3A -> 0
    return savefig(fig, path, SizeSpec(args...); kwargs...)
end

"""
    savefig(fig_function, [name(s)], [format(s)], [size], [dir]; <keyword arguments>)

Save the figure output by `fig_function` with themes applied and various formats in `dir` with as `name`

If `PdfTex` format is requested, __Inkscape__ is used to convert the `SVG` file to `PDF` with text in LaTeX.

# Arguments
* `fig_function::Function`: function that generates the figure (or figures) to save
* `width::Length`: physical width of the exported figure *(default: `MakieMaestro.Themes.get_width()`)*
* `hwratio::Real`: height to width ratio *(default: `MakieMaestro.Themes.get_hwratio()`)*
* `name::String` / `name::Vector{String}`: file basename *(default: `nameof(fig_function)`)*
* `dir::String`: path to figure directory *(default: `MakieMaestro.get_figure_dir()`)*

## Keyword arguments
* `backends=CairoMakie`
* `override_theme=Theme()`
* `formats=Set([Pdf])`
* `fig_function_args=()`
* `[update]` _(default: determine by the backend)_
"""
function savefig(
    fig_function::Function,
    name::Union{AbstractString,Vector{AbstractString}}=String(nameof(fig_function)),
    width::Length=Themes.get_width(),
    hwratio::Number=Themes.get_hwratio(),
    dir::AbstractString=get_figure_dir();
    backends=CairoMakie,
    override_theme=Theme(),
    formats=Set([Pdf]), # skip = [:eps, :pdf_tex, :svg, :raster], # :svg, :pdf, :pdf_tex, :eps, :png, :raster, :vector
    fig_function_args=(), # TODO: These should be varargs at the end of `savefig`s arguments <18-10-24> 
    varargs...,
)
    override_theme = override_theme isa Theme ? [override_theme] : override_theme
    backends = backends isa Module ? [backends] : backends

    formats = get_formats(backends, formats)

    for f in formats
        b = choose_backend(backends, f)
        export_theme = get_export_theme(b, f, width, hwratio, override_theme...)
        with_theme(export_theme) do
            fig = fig_function(fig_function_args...) # NOTE: Figure function must be called with the theme defined for theming to work <08-01-25> 
            if fig isa Vector # If there are multiple figures returned by the function, we need to create the names and save them individually
                if !(name isa Vector)
                    @info "Using `\"_i\"` for the figure `\"i\"` name. If the function returns multiple figures and you want to name them differently, you must provide multiple names."
                    name = [name * "_$i" for i in 1:length(fig)]
                else
                    @assert length(fig) == length(name) "number of figures (`$(length(fig))`) does not match number of names (`$(length(name))`)"
                end
                for (fi, n) in zip(fig, name)
                    _savefig(fi, n, f, b, dir; varargs...)
                end
            else
                _savefig(fig, name, f, b, dir; varargs...)
            end
        end
    end
end

const SavableFigure = Union{Makie.Figure,Makie.FigureAxisPlot,Makie.FigureAxis}

# FIX: `@extref` to `Makie.Axis` when `objects.inv` are in the Makie documentation <26-01-25> 
"""
    _savefig(fig, name, format, backend, dir; update)
Save figure `fig` with `backend` and `name` in `dir` with `format`.

This is an internal function that gets called at the end of the saving stack with all of the arguments already fully
determined. `update` should be `true` if the [`Axis`](https://docs.makie.org/stable/reference/blocks/axis#axis) is
created separately from the plot inside in order to set the correct viewing limits for the figure.
"""
function _savefig(
    fig::SavableFigure,
    name::AbstractString,
    format::Format,
    backend::Module,
    dir::AbstractString;
    update=(backend == CairoMakie ? true : false),
    varargs...,
)
    path = joinpath(dir, name * extension(format))
    @info "Building figure `$(basename(path) * (format == PdfTex ? "_tex" : ""))` in $dir"
    if format == PdfTex
        _savepdftex(joinpath(dir, name * ".svg"), path)
    else
        Makie.save(path, fig; backend, update, varargs...)
    end
end

"""
    _savepdftex(svgpath, outputpath; wait=true)
Run the command for creating a `PDFTEX` figure using Inkscape.

Internal function to convert `SVG` figures to `PDFTEX` (`PDF`+`LaTeX`) format assuming that the `SVG` already exists. If `wait` then the command in ran as blocking.
"""
function _savepdftex(svgpath, outputpath; wait=true)
    cmd_parts = [
        "inkscape",
        svgpath,
        "--export-type=pdf",
        "--export-latex",
        "--export-filename",
        outputpath,
    ]
    inkscape_cmd = Cmd(cmd_parts)
    return run(inkscape_cmd; wait)
end

export savefig, figure_dir!, default_formats!
