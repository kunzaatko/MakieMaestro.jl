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
```jldoctest; teardown = :(MakieMaestro.FIGURE_DIR[] = missing)
julia> figure_dir!("/tmp")
"/tmp"

julia> MakieMaestro.get_figure_dir()
"/tmp"
```
"""
function get_figure_dir()
    if ismissing(FIGURE_DIR[])
        cwd = pwd()
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

Base.convert(f::Type{Format}, s::AbstractString) = parse(f, s)
Base.convert(f::Type{Format}, s::Symbol) = convert(f, string(s))

const FORMATS_DEFAULT = Ref{Union{Set{Format},Missing}}(missing)
"""
    export_format!(formats)
Set the default formats to export.

```jldoctest
julia> export_format!(["pdf", :eps]);

julia> export_format!("pdf", MakieMaestro.Png, :svg);

julia> export_format!(missing);
```
"""
function export_format!(formats)
    return FORMATS_DEFAULT[] =
        formats isa Missing ? missing : Set(convert.(Format, formats))
end
export_format!(formats...) = export_format!(formats)
export_format!(format::Union{Format,AbstractString,Symbol}) = export_format!((format,))

"""
    MakieMaestro.get_export_format()
Get the default export formats

# Examples
```jldoctest
julia> export_format!(:pdf)
Set{MakieMaestro.Format} with 1 element:
  MakieMaestro.Pdf

julia> MakieMaestro.get_export_format()
Set{MakieMaestro.Format} with 1 element:
  MakieMaestro.Pdf

julia> export_format!(missing);
```
"""
function get_export_format()
    ismissing(FORMATS_DEFAULT[]) && throw(
        ErrorException(
            """
            DEFAULT_FORMATS not set! Use MakieMaestro.export_format!(formats) to set the default formats for exporting before saving a figure.
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
Return the list (`Vector`) of formats to generate based on the given `backends` required `formats`. Output is in the correct order for export.

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
julia> theme = MakieMaestro.get_export_theme(CairoMakie, MakieMaestro.Png, 10u"cm", 0.8,
           Theme(;
               CairoMakie=(;pdf_version=1.1)
           ),
           Theme(;
               Scatter=(;markersize=8)
           )
       );

julia> theme.size[]
(283, 226)
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
