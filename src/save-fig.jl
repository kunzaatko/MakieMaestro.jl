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
const EXTENSIONS = Dict(
    Svg => ".svg", Pdf => ".pdf", Eps => ".eps", PdfTex => ".pdf", Png => ".png"
)

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
    return EXTENSIONS[format]
end

"""
    MakieMaestro.backend_formats(backend::Module,...)
Return the set of compatible formats for given `backend`s.

# Examples
```jldoctest
julia> @assert MakieMaestro.backend_formats(CairoMakie) == Set([ MakieMaestro.Png, MakieMaestro.Eps, MakieMaestro.Svg, MakieMaestro.Pdf ])

julia> @assert MakieMaestro.backend_formats(GLMakie) == Set([MakieMaestro.Png])
```
"""
function backend_formats(backend::Vararg{Module})::Set{Format}
    formats = union(
        map(b -> b == CairoMakie ? Set([Svg, Pdf, Eps, Png]) : Set([Png]), backend)...
    )
    backend == CairoMakie && Sys.which("inkscape") !== nothing && push!(formats, PdfTex)
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
3-element Vector{Symbol}:
 :base
 :cairomakie
 :vector

julia> MakieMaestro.get_themes(GLMakie, MakieMaestro.Png)
3-element Vector{Symbol}:
 :base
 :glmakie
 :raster
```
"""
function get_themes(backend::Module, format::Format)
    backend_theme(b) = b == CairoMakie ? :cairomakie : :glmakie
    format_theme(x) = isvectorgraphic(x) ? :vector : :raster
    return [:base, backend_theme(backend), format_theme(format)]
end

# FIX: The documentation is wrong here. We already use something different than the constants for every possible theme <13-12-24> 
# TODO: Document the possibility of using `skip` for defining the formats for the save <18-10-24> 
# TODO: Logic for picking a backend from the set backends for a give figure with a format <18-10-24> 
# TODO: Method that uses width and height instead of the width and hwratio. This will be done by defining another method
# for `size_theme` function or the `figure_size` function in the `Themes` module <18-10-24> 
"""
    savefig(fig_function, name, dir; <keyword arguments>)

Save a figure output by `fig_function` in with themes applied and various formats in `dir` with the file name `name`

# Parameters:
* `fig_function`: function that generates the figure or figures to save
* `name`: name of the file to save the figure as or vector of names if multiple figures are returned
* `dir`: relative or absolute path to the project directory (default: `FIGURE_DIR`)

Save a figure in the selected formats. If `:pdf_tex` format is requested, Inkscape is used to convert the SVG file to
PDF with text in LaTeX.

# Keyword arguments:
* `hwratio=HWRATIO_DEFAULT`
* `width=WIDTH_DEFAULT`
* `backend=CairoMakie`
* `override_theme=Theme()`
* `size_theme=SIZE_THEME`
* `base_theme=BASE_THEME`
* `vector_theme=VECTOR_THEME`
* `raster_theme=RASTER_THEME`
* `gl_theme=GL_THEME`
* `cairo_theme=CAIRO_THEME`
* `skip=[:eps, :pdf_tex, :svg, :raster]` - other options are `:svg`, `:pdf`, `:pdf_tex`, `:eps`, `:png`, `:raster`, `:vector`
* `fig_function_args=()`
* `update=false`
"""
function savefig(
    fig_function::Function,
    name::Union{AbstractString,Vector{AbstractString}}=String(nameof(fig_function)),
    width::Length=Themes.get_width(),
    hwratio::Number=Themes.get_hwratio(),
    dir::AbstractString=get_figure_dir();
    backends=CairoMakie,
    override_theme=Theme(),
    theme_dict=Themes.THEME[], # FIX: This should be removed. It should not be the case that someone is able to use some different theming dictionary. That person would need to write every key that is necessary for the generation. Instead it is possible to use `Themes.update_theme!` to use their own values for the predefined theming scheme. <13-12-24> 
    formats=Set([Pdf]), # skip = [:eps, :pdf_tex, :svg, :raster], # :svg, :pdf, :pdf_tex, :eps, :png, :raster, :vector
    fig_function_args=(), # TODO: These should be varargs at the end of `savefig`s arguments <18-10-24> 
    update=false,
    varargs...,
)
    # FIX: `hwratio` not working!!! Maybe because of `https://github.com/MakieOrg/Makie.jl/issues/1939` <16-11-24> 

    override_theme = override_theme isa Theme ? [override_theme] : override_theme
    backends = backends isa Module ? [backends] : backends

    formats = collect(intersect(backend_formats(backends...), formats))

    sort!(formats; by=f -> f == Svg ? 1 : 2) # NOTE: pdf_tex is reliant on svg so it has to go first
    PdfTex in formats &&
        @assert Svg in formats "PdfTex can only be used if Svg is also generated. Add Svg to allowed formats."

    # TODO: The arguments to the distinct backends should instead be passed in as a single dict that holds backends and
    # their default themes. This Dict should be possible to be set similarly as the constants for the saving such as
    # DEFAULT_WIDTH, DEFAULT_HWRATIO, etc. <18-10-24> 

    # TODO: Warn if there is no available format for a given backend <16-11-24> 
    for f in formats
        b = choose_backend(backends, f)
        local figure_theme = Themes.get_theme(
            override_theme..., theme_dict[:size](width, hwratio), get_themes(b, f)...
        )
        with_theme(figure_theme) do
            fig = fig_function(fig_function_args...)
            if fig isa Vector
                @assert name isa Vector "If the function returns multiple figures you must provide multiple names"
                @assert length(fig) == length(name) "number of figures (`$(length(fig))`) does not match number of names (`$(length(name))`)"
                for (fi, n) in zip(fig, name)
                    savefig(fi, n, f, b, dir; varargs, update)
                end
            else
                savefig(fig, name, f, b, dir; varargs, update)
            end
        end
    end
end

const SavableFigure = Union{Makie.Figure,Makie.FigureAxisPlot,Makie.FigureAxis}

# FIX: This should instead be a method override for every format individually <18-10-24> 
function savefig(
    fig::SavableFigure,
    name::AbstractString,
    format::Format,
    backend::Module,
    dir::AbstractString;
    wait=true,
    update=false,
    varargs...,
)
    path = joinpath(dir, name * extension(format))
    if format == PdfTex
        @info "Building figure at `$(basename(path))_tex`"
        svgpath = joinpath(dir, name * ".svg")
        cmd_parts = [
            "inkscape",
            svgpath,
            "--export-type=pdf",
            "--export-latex",
            "--export-filename",
            path,
        ]
        # FIX: How to send the output to /dev/null in Julia? <21-11-23> 
        # if !wait
        #     append!(cmd_parts, ["&>/dev/null"])
        # end
        inkscape_cmd = Cmd(cmd_parts)
        run(inkscape_cmd; wait)
    else
        @info "Building figure `$(basename(path))` in $dir"
        if backend == CairoMakie
            # if vectorgraphic(format)
            Makie.save(path, fig; backend, update, varargs...)
            # else
            #     Makie.save(path, fig; backend, update=false, px_per_unit=20, varargs...)
            # end
        end
        backend == GLMakie && Makie.save(path, fig; backend, update=false, varargs...)
    end
end

function savefig(figs::Vector{SavableFigure}, args...; varargs...)
    return foreach(f -> savefig(f, args...; varargs...), figs)
end

export savefig, figure_dir!
