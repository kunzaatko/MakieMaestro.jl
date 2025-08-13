"""
    MakieDocBlocks(;path=@__DIR__ * "assets/figs/", formats=[:svg, :pdf])
Create the plugin for generating Documenter figures from blocks of code in the documentation pages.
"""
function MakieDocBlocks(; path=eval(@__DIR__) * "assets/figs/", formats=[:svg, :pdf])
    DocumenterExt = Base.get_extension(@__MODULE__, :DocumenterExt)
    !isnothing(DocumenterExt) || throw(error("Documenter is not loaded"))
    return DocumenterExt.MakieCodeBlocks(path, formats)
end

export MakieDocBlocks
