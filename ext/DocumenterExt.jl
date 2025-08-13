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

# TODO: Implement a caching for unchanged blocks (same code hash, same options) since the builds are reproducible. It
# can saved a lot of time for many-figured pages and enable faster turn based development. It should be implemented at
# the package level and an option should be present that disables it for the block. <13-08-25> 

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

Currently implements parsing of `name`, `formats`, `basename`, `caption`, `alt`, `size`, `theme`
"""
function Base.parse(::Type{MakieBlockOptions}, s::AbstractString)
    matched = match(r"(?:\s+([^\s;]+))?\s*(;.*)?$(?:\s+([^\s;]+))?\s*(;.*)?$", s)
    isnothing(matched) && throw(error("Invalid `@makie` options syntax"))
    name, kwargs = matched.captures
    formats = basename = caption = alt = size = theme = nothing
    if !isnothing(kwargs)
        stringkw_regex(name) = Regex(raw"(?:\s*" * name * raw"\s*=\s*\"([^\"]+)\".*)")

        basename_match = match(stringkw_regex("basename"), kwargs)
        alt_match = match(stringkw_regex("alt"), kwargs)
        caption_match = match(stringkw_regex("caption"), kwargs)

        basename, caption, alt = map((basename_match, caption_match, alt_match)) do m
            !isnothing(m) ? string(first(m.captures)) : nothing
        end

        symbol_regex = raw"(?<symbol>:[^\s,]+)"
        vector_regex = raw"(?<vector>\[[^\]]+\])"
        endofkw_regex = raw"[^,$]*"
        formats_match = match(
            Regex(
                raw"(?:\s*formats\s*=\s*(" *
                vector_regex *
                "|" *
                symbol_regex *
                ")" *
                endofkw_regex *
                ")",
            ),
            kwargs,
        )
        size_match = match(
            Regex(
                raw"(?:\s*size\s*=\s*(?<tuple>\([^\)]+\))|(?<length>\d[\d\.]+u\"[A-Za-z]+\")" *
                endofkw_regex *
                ")",
            ),
            kwargs,
        )
        theme_match = match(
            Regex(
                raw"(?:\s*theme\s*=\s*(" *
                vector_regex *
                "|" *
                symbol_regex *
                ")" *
                endofkw_regex *
                ")",
            ),
            kwargs,
        )

        # NOTE: `RegexMatch`es can be converted to `NamedTuple` in version >= 1.11 and return nothing for
        # non-matches. Should be updated when this is supported by the `lts` version of Julia <12-08-25> 
        formats, theme = map(
            m -> begin
                if isnothing(m)
                    nothing
                else
                    v, s = m["vector"], m["symbol"]
                    if !isnothing(v) # vector formats/themes
                        expr = Meta.parse(v)
                        eval(:($expr))
                    else
                        @assert s != ""
                        expr = Meta.parse(s)
                        [eval(:($expr))]
                    end
                end
            end, (formats_match, theme_match)
        )
        size = let m = size_match
            if isnothing(m)
                nothing
            else
                t, l = m["tuple"], m["length"]
                if !isnothing(t) # tuple format for size
                    expr = Meta.parse(t)
                    size = eval(:($expr))
                    size = MakieMaestro.SizeSpec(size)
                else
                    @assert l != ""
                    expr = Meta.parse(l)
                    size = eval(:($expr))
                    size = MakieMaestro.SizeSpec(size)
                end
            end
        end
    end

    return MakieBlockOptions(; name, formats, basename, caption, alt, size, theme)
end

"""
    MakieBlock
A block of code that contains a julia script generating a Makie figure which is then added to the documentation.
"""
struct MakieBlock <: Documenter.AbstractDocumenterBlock
    codeblock::MarkdownAST.CodeBlock # Makie figure code block
    basename::String                 # basename for the export
    funcname::String                 # name of the function... Cannot collide with a function in the evaluation module 
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
    options::MakieBlockOptions
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

    options = isnothing(options) ? "" : options
    block_options = parse(MakieBlockOptions, options.match)

    plugin = Documenter.getplugin(doc, MakieCodeBlocks)

    name = ifelse(isnothing(block_options.name), "", block_options.name)
    formats = ifelse(
        isnothing(block_options.formats), plugin.export_format, block_options.formats
    )  # TODO: allow merge with `figure_block_options` <07-05-25> 

    # FIX: `funcname` must be a valid identifier, so we need to filter things that are allowed in the `name` but not in
    # julia identifiers such as `"-"` <13-08-25> 
    basename, funcname = if block_options.basename == nothing
        name_string = "makie_" * (name != "" ? name * "_" : "") * string(hash(block.code))
        (name_string, name_string)
    else
        name_string = block_options.basename
        (name_string, name_string * "_" * string(hash(block.code)))
    end

    build = build_path(plugin, page, doc)

    makie_block = MakieBlock(
        block,         # codeblock
        basename,      # basename
        funcname,      # funcname
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

    theme_string = let theme = makie_block.options.theme
        isnothing(theme) ? "" : "; override_theme=$(theme)"
    end
    pathspec_string = "PathSpec(\"$(makie_block.basename)\", $(makie_block.formats), \"$(makie_block.build)\")"
    size_string = let size = makie_block.options.size
        isnothing(size) ? "" : ", $(repr(size))"
    end
    savefig_string = "savefig($(makie_block.funcname), $pathspec_string $size_string $theme_string)\n"

    code =
        "using MakieMaestro\n" *
        "using MakieMaestro: PathSpec, SizeSpec\n" *
        "function $(makie_block.funcname)()\n" *
        makie_block.code *
        "\nend\n" *
        savefig_string

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

    @info "MakieCodeBlocks: Saved figure `$(makie_block.basename)` to `$(makie_block.build)`"

    prefered_formats = [:svg, :png, :pdf]
    format = prefered_formats[findfirst(x -> x in makie_block.formats, prefered_formats)] # TODO: allow the user to pick a preferred format

    # FIX: This should use the internal `extension` method to determine the extension for the format <07-05-25> 
    document_path = joinpath(
        ref_path(plugin, page, doc), makie_block.basename * "." * string(format)
    )

    @info "MakieCodeBlocks: Reference of figure `$(makie_block.basename)` at `$(document_path)`"
    makie_generated = GeneratedMakieImage(
        Documenter.LocalImage(document_path), makie_block.options
    )
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
