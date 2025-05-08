module DocumenterExt
using Documenter, MakieMaestro
using Documenter.MarkdownAST, Documenter.IOCapture

abstract type MakieExportPath end

"""
    build_path(p::MakieExportPath, page, doc)

Return the path where to _build_ the figure in the block.
"""
function build_path(::MakieExportPath, args...) end

"""
    ref_path(p::MakieExportPath, page, doc)
Return the path where to _reference_ the figure in the block.
"""
function ref_path(p::MakieExportPath, page::Documenter.Page, doc::Documenter.Document)
    return joinpath(".", normpath(relpath(build_path(p, page, doc), doc.user.build)))
end

"""
   DirectPath(path::String) 
Specifying the direct path from the build/source root
"""
struct DirectPath <: MakieExportPath
    path::String
end

function build_path(p::DirectPath, ::Documenter.Page, doc::Documenter.Document)
    build_path = normpath(joinpath(pwd(), doc.user.build, p.path))
    if !isdir(build_path)
        @info "MakieCodeBlocks: Creating figure directory at `$(build_path)`"
        mkpath(build_path)
    end
    return build_path
end

"""
    RelativePath(path::String)
Specifying the relative path from the Documenter.page where the `@makie` block is located.
"""
struct RelativePath <: MakieExportPath
    path::String
end
function build_path(p::RelativePath, page::Documenter.Page, ::Documenter.Document)
    build_path = normpath(joinpath(pwd(), dirname(page.build), p.path))
    if !isdir(build_path)
        @info "MakieCodeBlocks: Creating figure directory at `$(build_path)`"
        mkpath(build_path)
    end
    return build_path
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
end
function MakieCodeBlocks(
    figure_dir::String="assets/figs", export_format::Vector{Symbol}=[:svg, :pdf]
)
    return MakieCodeBlocks(DirectPath(figure_dir), export_format)
end

build_path(p::MakieCodeBlocks, args...) = build_path(p.figure_dir, args...)
ref_path(p::MakieCodeBlocks, args...) = ref_path(p.figure_dir, args...)

# Code adapted from `DocumenterDiagrams.jl`

"""
    MakieFigureBlocks <: Documenter.Expanders.NestedExpanderPipeline

An expander pipeline for generating Makie figures from code `@makie` code blocks and expanding them into the
documentation as images.

See [`Documenter.Expanders.NestedExpanderPipeline`](@extref).
"""
abstract type MakieFigureBlocks <: Documenter.Expanders.NestedExpanderPipeline end

# TODO: Add functionality of "caption", "alt text", "dimensions", "theme"  <08-05-25> 
const Option{T} = Union{Nothing,T}
@kwdef struct MakieBlockOptions
    name::Option{String} = nothing
    formats::Option{Vector{Symbol}} = nothing
    basename::Option{String} = nothing
    caption::Option{String} = nothing
    alt::Option{String} = nothing
    size::Option{MakieMaestro.SizeSpec} = nothing
    theme::Option{Vector{Symbol}} = nothing
end

"""
    parse(::Type{MakieBlockOptions}, s)
Block options that are located after the `@makie` code identifier.
"""
function Base.parse(::Type{MakieBlockOptions}, s::AbstractString)
    matched = match(r"(?:\s+([^\s;]+))?\s*(;.*)?$(?:\s+([^\s;]+))?\s*(;.*)?$", s)
    isnothing(matched) && throw(error("Invalid `@makie` options syntax"))
    name, kwargs = matched.captures
    formats = basename = caption = alt = size = theme = nothing
    if !isnothing(kwargs)
        # TODO: Test before going forward <08-05-25> 
        formats_match = match(r".*(?:\s*formats\s*=\s*([^;]+)).*", kwargs)
        basename_match = match(r".*(?:\s*basename\s*=\s*\"([^\"]+)\").*", kwargs)
        caption_match = match(r".*(?:\s*caption\s*=\s*\"([^\"]+)\").*", kwargs)
        formats, basename, caption =
            map((formats_match, basename_match, caption_match)) do m
                !isnothing(m) ? string(first(m.captures)) : nothing
            end
        @warn "Options for Makie code blocks are not fully implemented yet! Only `name` works reliably."
    end

    return MakieBlockOptions(; name, basename, caption, alt, size, theme)
end

"""
    MakieBlock

A block of code that contains a julia script generating a Makie figure which is then added to the documentation.
"""
struct MakieBlock <: Documenter.AbstractDocumenterBlock
    codeblock::MarkdownAST.CodeBlock # Makie figure code block
    basename::String                 # basename for the export
    build::String                    # Dir for the export
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

# Same as `ExampleBlocks`
Documenter.Selectors.order(::Type{MakieFigureBlocks}) = 8.0

function Documenter.Selectors.matcher(::Type{MakieFigureBlocks}, node, page, doc)
    return Documenter.iscode(node, r"^@makie")
end

# NOTE: Using code from the @example expander in Documenter.jl:
# https://github.com/JuliaDocs/Documenter.jl/blob/3806ff5057ab855c80b5c53d41b512e8dc3c42b4/src/expander_pipeline.jl?plain=1#L806-L905
# <07-05-25> 

function Documenter.Selectors.runner(::Type{MakieFigureBlocks}, node, page, doc)
    block = node.element

    options = match(r"@makie(.*)$", block.info)

    # TODO: Options should include a `name` then used for the figure name in the path and `caption` <07-05-25> 
    options = isnothing(options) ? "" : options
    block_options = parse(MakieBlockOptions, options.match)

    plugin = Documenter.getplugin(doc, MakieCodeBlocks)

    name = ifelse(isnothing(block_options.name), "", block_options.name)
    formats = ifelse(
        isnothing(block_options.formats), plugin.export_format, block_options.formats
    )  # TODO: allow merge with `figure_block_options` <07-05-25> 

    basename = "makie_" * name * string(hash(block.code)) # TODO: allow override with `figure_block_options`
    build = build_path(plugin, page, doc)

    makie_block = MakieBlock(
        block,         # codeblock
        basename,      # basename
        build,         # explicit path of the export figure without the name
        formats,       # formats for export
        block.code,    # code
        block_options, # code block options
    )
    identifier = name == "" ? string(hash(block.code)) : name
    # The sandboxed module -- either a new one or a cached one from this page.
    mod = Documenter.get_sandbox_module!(
        page.globals.meta,
        "atexample",
        identifier;
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
        "savefig($(makie_block.basename), PathSpec(\"$(makie_block.basename)\", $(makie_block.formats), \"$(makie_block.build)\"))\n"

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

    @info "Saved figure `$(makie_block.basename)` to `$(makie_block.build)`"

    prefered_formats = [:svg, :png, :pdf]
    format = prefered_formats[findfirst(x -> x in makie_block.formats, prefered_formats)] # TODO: allow the user to pick a preferred format

    # FIX: This should use the internal `extension` method to determine the extension for the format <07-05-25> 
    document_path = joinpath(
        ref_path(plugin, page, doc), makie_block.basename * "." * string(format)
    )

    @info "Reference of figure `$(makie_block.basename)` at `$(document_path)`"
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
