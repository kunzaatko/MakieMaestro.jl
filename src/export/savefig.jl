# TODO: At the end of the arguments cascade should be themes that are passed in the override instead of it being
# a keyword argument. <29-01-25> 
using CairoMakie, GLMakie, Dates

include("utils.jl") # Helpers for setting the directory, specifying formats for export and selecting the theme

include("arguments.jl") # Argument formation cascade for the final function
include("logger.jl") # Logging of the exported figures and options
include("cache.jl") # Digest computation and content-addressed caching of the exported figures

"""
    create_logger(logger, figdir)
Create a logger based on the `logger` argument and the figure directory `figdir`.

If logger is `true`, a default logger is created, if `logger` is an `AbstractString`, a `TOMLLogger` at that path. If
`logger` is `false` the `NullLogger` is created.
"""
function create_logger(logger, path)
    if logger == true
        return TOMLLogger(; dir=path)
    elseif logger isa FigureLogger
        return logger
    elseif logger isa AbstractString
        dirname, basename = Base.Filesystem.dirname(logger),
        Base.Filesystem.basename(logger)
        if isempty(dirname)
            return TOMLLogger(; basename)
        elseif isempty(basename)
            return TOMLLogger(dirname, basename)
        else
            return TOMLLogger(dirname, basename)
        end
    else
        logger = NullLogger()
    end
end

"""
    savefig(fig, [path], [size]; <keyword arguments>)
Save the figure `fig` at `path` with `size`. 

Themes are applied from the [`:base`](@ref Themes.get_theme) theme and you can supply any number of overrides, either
[predefined](@ref Themes.theme_keys) or you own with the `override_theme` keyword.

The arguments `fig`, `path` and `size` may be specified in a number of different ways as shown below in __Arguments__ or
in the case of `path` and `size` be left with their default values (see [`Themes.width!`](@ref),
[`Themes.hwratio!`](@ref), [`figure_dir!`](@ref) and [`export_format!`](@ref)). For a clearer picture of how to supply
the arguments, see __Examples__ in the documentation, but as a rule of thumb, any sensible way to define the export
arguments should work granted that they are in the correct order.

# Arguments

* `fig` -- figure(s) generating function 
!!! info
    `fig_func::Function, (arg1, arg2,...)`, `() -> fig_func(arg1, arg2,...)` or `fig_func` (if it is possible to call it
    without any arguments). This is the only argument that is necessary to provide. See all possible signatures at
    [`FunctionSpec`](@ref).

* `path`: basename, directory and formats
!!! info
    `name, [formats], [dir]` or `path`. For example `"protein_density_heatmap", [:svg, :pdf, :pdf_tex],
    "~/ImporantProject/"` or equivalently `"~/ImporantProject/protein_density_heatmap.{svg, pdf, pdf_tex}"`. See all
    possible signatures at [`PathSpec`](@ref).
!!! tip 
    If not supplied, the name is inferred from `nameof(fig_func)`, `formats` are taken from
    [`MakieMaestro.get_export_format`](@ref) (see also [`export_format!`](@ref)) and `dir` is taken from
    [`MakieMaestro.get_figure_dir`](@ref) (see also [`figure_dir!`](@ref)).
!!! warning 
    If `PdfTex` format is requested, `Inkscape` is used to convert the `SVG` file to `PDF` with text in LaTeX. Due to
    that `incscape` must be an executable on your system if you want to use the `PdfTex` format.

* `size`: physical dimensions of the figure
!!! info
    `20.5u"cm", 0.6`, `FigHeight(5u"inch"), 8u"inch"`, `0.5, 1.5` (relative width, hwratio), `HeightLength(0.3), 0.4`
    (relative height, hwratio). A combination of _width_, _height_ and/or _hwratio_, such that the size is completely
    determined from these and the default values (see [`Themes.hwratio!`](@ref) and [`Themes.width!`](@ref)). See all
    possible signatures at [`SizeSpec`](@ref).

## Keyword arguments
* `backends=CairoMakie` -- Backend used for exporting
* `override_theme=Theme()` -- Theme(s) that will be used to style  the figure
* `[update]` -- _(default: determine by the backend)_
* `cache=true` -- Reuse previously rendered figures from a content-addressed cache store
  ([`FigureCacheStore`](@ref)) whenever the digest of the figure-producing inputs (function source, arguments,
  keyword arguments) and the resolved export options (basename, backend, format, size, themes) is unchanged. `false`
  disables the cache and an `AbstractString` selects the store directory. The default store directory is the hidden
  `.figurecache` directory inside the figure directory, unless set globally with [`figure_cache_dir!`](@ref). When all
  requested formats are cached, the figure function is not called at all.
* `figdigest` -- Digest of the figure-producing inputs. When provided (e.g. by the `@makie` Documenter block expander,
  which owns the block code text), it is used instead of computing the digest from the function source.
* `kwargs...` -- Any additional keyword arguments are supplied to the figure function as keyword arguments.

!!! warning
    The cache digest covers the figure code, its arguments and the resolved export options. Changes to the
    _environment_ (Julia, Makie or backend versions), to global state that the figure function reads, or to the
    contents of data files that it opens are _not_ detected. Pass `cache=false` for such figures, or delete the cache
    store to force a re-render.
"""
function savefig(
    fig::FunctionSpec,
    path::PathSpec,
    size::SizeSpec;
    backends=CairoMakie,
    override_theme=Theme(),
    log=true,
    update=missing,
    cache=true,
    figdigest=missing,
    kwargs...,
)
    # TODO: Add logfilter kwarg that is passed to the logger <15-08-25> 
    # NOTE: The cache store directory can be set with the `cache` keyword (or globally with `figure_cache_dir!`). The
    # digests of the figures are logged in the figure entry under `figure.digest` and `backends.<format>.digest`.

    override_theme = override_theme isa Theme ? [override_theme] : override_theme
    backends = backends isa Module ? [backends] : backends
    logger = create_logger(log, path.dirname)
    store = figure_cache_store(cache, path.dirname)

    logging_data = Dict{String,Any}()

    # TODO: Logging for PathSpec <15-08-25> 
    # TODO: Log the figure name and the lines it is defined at if they exist <15-08-25> 

    formats = get_formats(backends, path.formats) # from backends and wanted, ordered in the export order

    # Digest of the figure-producing inputs. A provided `figdigest` (e.g. from the `@makie` block expander, which owns
    # the block code text) takes precedence; otherwise the digest is computed from the function source.
    digest_info = Dict{String,Any}()
    fig_digest = nothing
    if !isnothing(store) || figdigest isa AbstractString
        digest_pair = if figdigest isa AbstractString
            (digest=String(figdigest), info=Dict{String,Any}("code_source" => "provided"))
        else
            figure_digest(fig; kwargs...)
        end
        fig_digest, digest_info = digest_pair.digest, digest_pair.info
    end

    logging_data["cwd"] = pwd()
    logging_data["figure"] = logs(fig)
    merge!(logging_data["figure"], digest_info)
    isnothing(fig_digest) || (logging_data["figure"]["digest"] = fig_digest)
    logging_data["formats"] = string.(formats)
    logging_data["size"] = Dict{String,Any}("final" => string(size))
    merge!(logging_data["size"], logs(size))
    logging_data["backends"] = InlineDict{String,Any}()
    logging_data["exportduration"] = InlineDict{String,Any}()
    logging_data["reused"] = false

    fsize = Themes.figsize(size.width, size.hwratio)

    # Per-format digests of the rendered output and cache lookups for the base (index 0) figure. When every requested
    # format is already in the cache store, the figure function is not called at all. Figures at indices > 0 (a
    # `Vector` or `Tuple` of figures) are looked up lazily once their number is known.
    digests = Dict{Format,String}()
    themes = Dict{Format,Vector{String}}()
    reused = Dict{Format,Bool}()
    for fmt in formats
        b = choose_backend(backends, fmt)
        themes[fmt] = theme_tags(b, fmt, override_theme)
        digests[fmt] = isnothing(fig_digest) ? "" :
            renderdigest(fig_digest, path.basename(0), b, fmt, fsize, themes[fmt])
        reused[fmt] = false
        if !isnothing(store)
            target = joinpath(path.dirname, path.basename(0) * extension(fmt))
            reused[fmt] = cache_lookup!(store, digests[fmt], target)
        end
    end
    logging_data["reused"] = !isempty(formats) && all(values(reused))

    for fmt in formats
        b = choose_backend(backends, fmt)

        logging_data["backends"][string(fmt)] = InlineDict{String,Any}(
            "backend" => string(b), "reused" => reused[fmt], "digest" => digests[fmt]
        )

        logging_data["modified"] = InlineDict(
            "date" => Dates.Date(now()), "time" => Dates.Time(now())
        )

        if reused[fmt]
            @info "Reusing cached figure `$(path.basename(0) * extension(fmt))` in $(path.dirname)"
            continue
        end

        export_theme = get_export_theme(b, fmt, size.width, size.hwratio, override_theme...)

        time = @timed with_theme(export_theme) do
            export_fig = fig(; kwargs...) # NOTE: Figure function must be called with the theme defined for theming to work <08-01-25> 
            figures =
                export_fig isa Vector || export_fig isa Tuple ?
                enumerate(export_fig) : ((0, export_fig),)
            for (i, subfig) in figures
                name = path.basename(i)
                target = joinpath(path.dirname, name * extension(fmt))
                digest = isnothing(fig_digest) ? "" :
                    renderdigest(fig_digest, name, b, fmt, fsize, themes[fmt])
                # NOTE: The index-0 entry has already been looked up before the figure function was called.
                if !isnothing(store) && i != 0 && cache_lookup!(store, digest, target)
                    @info "Reusing cached figure `$(basename(target))` in $(path.dirname)"
                    continue
                end
                _savefig(subfig, name, fmt, b, path.dirname; update)
                if !isnothing(store)
                    cache_store!(
                        store, digest, target,
                        cache_entry_info(
                            fig_digest, digest_info, name, b, fmt, fsize, themes[fmt]
                        ),
                    )
                end
            end
        end

        logging_data["exportduration"][string(fmt)] = time.time
    end
    if length(logging_data["exportduration"]) > 1
        logging_data["exportduration"]["total"] = sum(
            values(logging_data["exportduration"])
        )
    end
    map!(x -> round(x; sigdigits=3), values(logging_data["exportduration"]))

    # NOTE: Cached retrievals are recorded in the store index (`lastsaved` timestamps) and in this figure log via the
    # `reused` flags.
    return add_entry(logger, path.basename(0), logging_data)
end

# TODO: Add a type and conversion for the output type of `mosaic` <14-08-25> 
const SavableFigure = Union{Makie.Figure,Makie.FigureAxisPlot,Makie.FigureAxis}

"""
    _savefig(fig, name, format, backend, dir; update)
Save figure `fig` with `backend` and `name` in `dir` with `format`.

Internal function that gets called at the end of the exporting stack with all of the arguments already fully determined
and the figure created with the theme activated. `update` should be `true` if the [`Axis`](@extref Makie Axis) is
created separately from the plots contained in the axis in order to set the correct viewing limits for the figure.
"""
function _savefig(
    fig::SavableFigure,
    name::AbstractString,
    format::Format,
    backend::Module,
    dir::AbstractString;
    update=missing,
    varargs...,
)
    update = ismissing(update) ? (backend == CairoMakie ? true : false) : update
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

Internal function to convert `SVG` figures to `PDFTEX` (`PDF`+`LaTeX`) format assuming that the `SVG` already exists. If
`wait` then the command in ran as blocking.
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

export savefig, figure_dir!, export_format!, figure_cache_dir!
