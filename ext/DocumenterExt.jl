module DocumenterExt
using Documenter, MakieMaestro
using Documenter.MarkdownAST, Documenter.IOCapture

abstract type MakieExportPath end

"""
    explicit_path(p::MakieExportPath, node, page, doc)

Return the explicit path `MakieExportPath` for the current block.
"""
function explicit_path(
    p::MakieExportPath, ::Documenter.Node, ::Documenter.Page, ::Documenter.Document
)
    throw(error("Explicit path is not implemeted for type $(typeof(p))"))
end

struct ExplicitPath <: MakieExportPath
    path::String
    function ExplicitPath(path::String)
        if !isdir(path)
            @info "MakieCodeBlock: Creating figure directory at `$path`"
            mkpath(path)
        end
        return new(path)
    end
end

function explicit_path(
    p::ExplicitPath, node::MarkdownAST.Node, page::Documenter.Page, doc::Documenter.Document
)
    # TODO: Warn if the export path is not in the assets directory <07-05-25> 
    return p.path
end

const DEFAULT_PATH = "assets/figs/"
struct AutoPath <: MakieExportPath end
function explicit_path(
    ::AutoPath, node::MarkdownAST.Node, page::Documenter.Page, doc::Documenter.Document
)
    path = joinpath(Documenter.currentdir(), "src", DEFAULT_PATH)
    if !isdir(path)
        @info "MakieCodeBlock: Creating figure directory at `$path`"
        mkpath(path)
    end
    return path
end

# TODO: Identities of the codeblocks should be merged with the `@example` block identities and the values from them used
# for the figure function <07-05-25>
# TODO: There is a plugin retriever that gets the plugin if it exists and therefore the options can be gathered for the
# exporting of the figure. <07-05-25> 
"""
    MakieCodeBlocks <: Documenter.Plugin
Documenter plugin that is used for storing the options for the makie code blocks.
"""
struct MakieCodeBlocks <: Documenter.Plugin
    figure_dir::MakieExportPath
    export_format::Vector{Symbol}

    # TODO: Format spec should be used <07-05-25> 
    function MakieCodeBlocks(figure_dir::MakieExportPath, export_format::Vector{Symbol})
        isempty(export_format) &&
            throw(ArgumentError("At least one export format must be specified"))
        return new(figure_dir, export_format)
    end
    MakieCodeBlocks() = new(AutoPath(), [:svg, :pdf])
end
function MakieCodeBlocks(figure_dir::String, export_format::Vector{Symbol}=[:svg, :pdf])
    return MakieCodeBlocks(ExplicitPath(figure_dir), export_format)
end

function get_figure_dir(p::MakieCodeBlocks, node, page, doc)
    return explicit_path(p.figure_dir, node, page, doc)
end

# Code adapted from `DocumenterDiagrams.jl`

"""
    MakieFigureExpander <: Documenter.Expanders.ExpanderPipeline

An expander pipeline for generating Makie figures from code `@makie` code blocks and expanding them into the
documentation as images.

See [`Documenter.Expanders.ExpanderPipeline`](@extref).
"""
abstract type MakieFigureExpander <: Documenter.Expanders.ExpanderPipeline end

# TODO: Implement this <07-05-25> 
const Option{T} = Union{Nothing,T}
@kwdef struct MakieBlockOptions
    name::Option{String} = nothing
end

"""
    MakieBlock

A block of code that contains a julia script generating a Makie figure which is then added to the documentation.
"""
struct MakieBlock <: Documenter.AbstractDocumenterBlock
    codeblock::MarkdownAST.CodeBlock # Makie figure code block
    basename::String                 # basename for the export
    dir::String                      # Dir for the export
    formats::Vector{Symbol}          # Formats for export
    code::String                     # Code of the figure
    options::MakieBlockOptions       # Options to the block
end

"""
    GeneratedMakieImage
A Makie block for which the image has already been generated.
"""
struct GeneratedMakieImage <: Documenter.AbstractDocumenterBlock
    local_image::Documenter.LocalImage
end

# Parsing
Documenter.Selectors.order(::Type{MakieFigureExpander}) = 10.5

function Documenter.Selectors.matcher(::Type{MakieFigureExpander}, node, page, doc)
    return Documenter.iscode(node, r"^@makie")
end

# NOTE: Using code from the @example expander in Documenter.jl:
# https://github.com/JuliaDocs/Documenter.jl/blob/3806ff5057ab855c80b5c53d41b512e8dc3c42b4/src/expander_pipeline.jl?plain=1#L806-L905
# <07-05-25> 

function Documenter.Selectors.runner(::Type{MakieFigureExpander}, node, page, doc)
    block = node.element

    options = match(r"@makie(.*)$", block.info)

    figure_block_options = MakieBlockOptions()

    # TODO: Options should include a `name` then used for the figure name in the path and `caption` <07-05-25> 
    if !isnothing(options)
        options = strip(options.match)
        # TODO: Parse options <07-05-25> 
        # merge(figure_block_options, options)
        @warn "Options for Makie code blocks are not implemented yet"
    end

    plugin = Documenter.getplugin(doc, MakieCodeBlocks)

    basename = "makie_figure_" * string(hash(block.code)) # TODO: allow override with `figure_block_options`
    dir = get_figure_dir(plugin, node, page, doc)
    path = joinpath(dir, basename)

    formats = plugin.export_format # TODO: allow merge with `figure_block_options` <07-05-25> 

    makie_block = MakieBlock(
        block,                    # codeblock
        basename,                 # basename
        dir,                      # explicit path of the export figure without the name
        formats,                  # formats for export
        block.code,               # code
        figure_block_options,
    )

    # The sandboxed module -- either a new one or a cached one from this page.
    mod = Documenter.get_sandbox_module!(
        page.globals.meta,
        "atexample",
        makie_block.options.name;
        share_default_module=Documenter.share_default_module(page),
    )

    lines = Documenter.find_block_in_file(makie_block.code, page.source)
    @debug "Evaluating @makie block:\n$(makie_block.code)"

    code =
        "using MakieMaestro\n" * # TODO: Make this a plugin option similarly to the `@Example` prepare in documenter <07-05-25> 
        "using MakieMaestro: PathSpec\n" *
        "function $(makie_block.basename)()\n" *
        makie_block.code *
        "\nend\n" *
        "savefig($(makie_block.basename), PathSpec(\"$(makie_block.basename)\", $(makie_block.formats), \"$(makie_block.dir)\"))\n"

    # linenumbernode = Documenter.LineNumberNode(
    #     lines === nothing ? 0 : lines.first, basename(page.source)
    # )

    for (ex, _str) in Documenter.parseblock(
        code,
        doc,
        page;
        keywords=false,#  linenumbernode=linenumbernode
    )
        c = IOCapture.capture(; rethrow=InterruptException) do
            cd(page.workdir) do
                Core.eval(mod, ex)
            end
        end
        if c.error
            bt = Documenter.remove_common_backtrace(c.backtrace)
            Documenter.@docerror(
                doc,
                :example_block, # TODO: Add a new tag that can be here for my `makie_block`. Otherwise it does not compile <07-05-25> 
                """
                failed to run `@makie` block in $(Documenter.locrepr(page.source, lines))
                ```$(makie_block.codeblock.info)
                $(makie_block.code)
                ```
                """,
                exception = (c.value, bt)
            )
            return nothing
        end
    end

    prefered_formats = [:svg, :png, :pdf]
    format = prefered_formats[findfirst(x -> x in makie_block.formats, prefered_formats)] # TODO: allow the user to pick a preferred format

    # FIX: This should use the internal `extension` method to determine the extension for the format <07-05-25> 
    document_path = joinpath(makie_block.dir, makie_block.basename * "." * string(format))
    makie_generated = GeneratedMakieImage(Documenter.LocalImage(document_path))
    node.element = makie_generated

    return nothing
end

function Documenter.HTMLWriter.domify(
    ctx::Documenter.HTMLWriter.DCtx, node::MarkdownAST.Node, image::GeneratedMakieImage
)
    return Documenter.HTMLWriter.domify(ctx, node, image.local_image)
end

function Documenter.MDFlatten.mdflatten(
    io::IOBuffer, node::MarkdownAST.Node, image::GeneratedMakieImage
)
    return Documenter.MDFlatten.mdflatten(io, node, image.local_image)
end

end
