"""
    MakieDocBlocks(;path=@__DIR__ * "assets/figs/", formats=[:svg, :pdf], cache=true)
Create the plugin for generating [`Documenter`](@extref Documenter :doc:`index`) figures from blocks of code in the
documentation pages.

The rendered figures are cached in a content-addressed store outside of the build directory (by default
`<docs>/cached/figures`), so that unchanged `@makie` blocks are not re-rendered on repeated builds. Set `cache=false`
to disable caching or pass a directory path to select the store location. Caching can also be disabled per block with
the `cache=false` block option.
"""
function MakieDocBlocks(; path=eval(@__DIR__) * "assets/figs/", formats=[:svg, :pdf], cache=true)
    DocumenterExt = Base.get_extension(@__MODULE__, :DocumenterExt)
    !isnothing(DocumenterExt) || throw(error("Documenter is not loaded"))
    return DocumenterExt.MakieCodeBlocks(path, formats; cache)
end

export MakieDocBlocks
