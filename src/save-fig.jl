# TODO: Add the functionality using the getters and update the function to the current API <17-10-24> 
using CairoMakie, GLMakie, Serialization

const FIGURE_DIR = Ref{Union{Missing,String}}(missing)
"""
    figure_dir!(dir)
Set the figure directory
"""
function figure_dir!(dir::AbstractString)
    isdir(dir) || throw(ArgumentError("$dir is not a valid directory"))
    return FIGURE_DIR[] = abspath(dir)
end

"""
    get_figure_dir()
Get the figure directory
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

include("./cache.jl")
if !isdefined(@__MODULE__, :UPDATE)
    global UPDATE = false
end

@enum Format Png Svg Eps Pdf PdfTex
const FORMATS = Set([Png, Svg, Eps, Pdf, PdfTex])
const EXTENSIONS = Dict(
    Svg => ".svg", Pdf => ".pdf", Eps => ".eps", PdfTex => ".pdf", Png => ".png"
)

"""
    vectorgraphic(x)

Determine if the given format is a vector graphic format.

# Arguments
- `x`: The format to check.

# Returns
`true` if the format is a vector graphic format (Svg, Png, Eps, or PdfTex), `false` otherwise.

# Examples
```julia
vectorgraphic(Svg)   # returns true
vectorgraphic(Jpg)   # returns false
```
"""
vectorgraphic(x) = x ∈ [Svg, Png, Eps, PdfTex] ? true : false

"""
    skip(skips::Vararg{Union{Symbol,Format}})

Generate a set of allowed formats by excluding specified formats or format groups.

# Arguments
- `skips`: Variable number of arguments specifying formats or format groups to exclude.
           Can be individual `Format` types or symbols `:raster` or `:vector`.

# Returns
A `Set` of allowed `Format` types after excluding the specified formats.

# Examples
```julia
skip(:raster)  # Excludes Png format
skip(:vector)  # Excludes Png, Eps, PdfTex, and Svg formats
skip(Png, Svg) # Excludes Png and Svg formats specifically
```

This function is useful for customizing the output formats when saving figures,
allowing you to easily exclude certain format types or groups of formats.
"""
function skip(skips::Vararg{Union{Symbol,Format}})
    deny = Set()
    for s in skips
        if s == :raster
            push!(deny, Png)
            continue
        elseif s == :vector
            foreach(f -> push!(deny, f), [Png, Eps, PdfTex, Svg])
        else
            push!(deny, s)
        end
    end
    return setdiff(FORMATS, deny)
end

function extension(format::Format)
    return EXTENSIONS[format]
end

function backend_formats(backend::Vararg{Module})
    formats = union(
        map(b -> b == CairoMakie ? Set([Svg, Pdf, Eps, Png]) : Set([Png]), backend)...
    )
    backend == CairoMakie && Sys.which("inkscape") !== nothing && push!(formats, PdfTex)
    return formats
end

function choose_backend(backends::Vector{Module}, f::Format)
    if CairoMakie ∈ backends
        return CairoMakie
    elseif f == Png && GLMakie ∈ backends
        return GLMakie
    else
        throw(ErrorException("None of the backends support the format $f"))
    end
end

function get_theme_types(backend, format)
    backend_theme(b) = b == CairoMakie ? :cairomakie : :glmakie
    format_theme(x) = vectorgraphic(x) ? :vector : :raster
    return [format_theme(format), backend_theme(backend), :base]
end

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
    # cache_file=joinpath(dir, "cache.bin"),
    backends=CairoMakie,
    override_theme=Theme(),
    theme_dict=Themes.THEME[],
    formats=Set([Pdf]), # skip = [:eps, :pdf_tex, :svg, :raster], # :svg, :pdf, :pdf_tex, :eps, :png, :raster, :vector
    fig_function_args=(), # TODO: These should be varargs at the end of `savefig`s arguments <18-10-24> 
    update=false,
    varargs...,
)
    # if !isfile(cache_file)
    #     @info "Creating cache file at `$cache_file`"
    #     cache = Dict()
    #     touch(cache_file)
    #     serialize(cache_file, cache)
    # end

    # FIX: This does not work, since the figure function changes pointer when recompiling <17-08-24> 
    # cache = deserialize(cache_file)
    # fig_key = hash((fig_function, name, dir))
    # fig_state = hash_code(fig_function, typeof.(fig_function_args))
    # if !UPDATE
    #     if haskey(cache, fig_key)
    #         if cache[fig_key] == fig_state
    #             @info "Figure function did not change from last save. Skipping figure `$name`..."
    #             return nothing
    #         else
    #             @info "Updating figure `$name` in cache..."
    #             cache[fig_key] = fig_state
    #             serialize(cache_file, cache)
    #         end
    #     else
    #         @info "Saving figure `$name` in cache..."
    #         cache[fig_key] = fig_state
    #         serialize(cache_file, cache)
    #     end
    # else
    #     @info "Updating figure `$name` in cache..."
    #     cache[fig_key] = fig_state
    #     serialize(cache_file, cache)
    # end

    # skip
    # matrix 

    override_theme = override_theme isa Theme ? [override_theme] : override_theme
    backends = backends isa Module ? [backends] : backends

    formats = collect(intersect(backend_formats(backends...), formats))

    sort!(formats; by=f -> f == Svg ? 1 : 2) # NOTE: pdf_tex is reliant on svg so it has to go first
    PdfTex in formats &&
        @assert Svg in formats "PdfTex can only be used if Svg is also generated. Add Svg to allowed formats."

    # TODO: The arguments to the distinct backends should instead be passed in as a single dict that holds backends and
    # their default themes. This Dict should be possible to be set similarly as the constants for the saving such as
    # DEFAULT_WIDTH, DEFAULT_HWRATIO, etc. <18-10-24> 

    for f in formats
        b = choose_backend(backends, f)
        local figure_theme = Themes.get_theme(
            override_theme..., theme_dict[:size](width, hwratio), get_theme_types(b, f)...
        )
        with_theme(figure_theme) do
            fig = fig_function(fig_function_args...)
            if fig isa Vector
                @assert name isa Vector "If the function returns multiple figures you must provide multiple names"
                @assert length(fig) == length(name) "number of figures (`$(length(fig))`) does not match number of names (`$(length(name))`)"
                for (fi, n) in zip(fig, name)
                    savefig(fi, n, f, b, dir; hwratio, varargs, update)
                end
            else
                savefig(fig, name, f, b, dir; hwratio, varargs, update)
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
