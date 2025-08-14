# TODO: At the end of the arguments cascade should be themes that are passed in the override instead of it being
# a keyword argument. <29-01-25> 
using CairoMakie, GLMakie

# Helpers for setting the directory, specifying formats for export and selecting the theme
include("utils.jl")

# Argument formation cascade for the final function
include("arguments.jl")

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
* `kwargs...` -- Any additional keyword arguments are supplied to the figure function as keyword arguments.
"""
function savefig(
    fig::FunctionSpec,
    path::PathSpec,
    size::SizeSpec;
    backends=CairoMakie,
    override_theme=Theme(),
    update=missing,
    kwargs...,
)
    override_theme = override_theme isa Theme ? [override_theme] : override_theme
    backends = backends isa Module ? [backends] : backends

    formats = get_formats(backends, path.formats) # from backends and wanted, ordered in the export order

    for fmt in formats
        b = choose_backend(backends, fmt)
        export_theme = get_export_theme(b, fmt, size.width, size.hwratio, override_theme...)
        with_theme(export_theme) do
            export_fig = fig(; kwargs...) # NOTE: Figure function must be called with the theme defined for theming to work <08-01-25> 
            if export_fig isa Vector || export_fig isa Tuple
                for (i, fig) in enumerate(export_fig)
                    _savefig(fig, path.basename(i), fmt, b, path.dirname; update)
                end
            else
                _savefig(export_fig, path.basename(0), fmt, b, path.dirname; update)
            end
        end
    end
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

export savefig, figure_dir!, export_format!
