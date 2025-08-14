function savefig(fig::Function, args...; kwargs...)
    return savefig(fig, (), args...; kwargs...)
end

function savefig(fig::Function, fig_args::Tuple, args...; kwargs...) # 1A -> 0
    return savefig(FunctionSpec(fig, fig_args), args...; kwargs...)
end

function savefig(fig::FunctionSpec, fullspec::AbstractString, args...; kwargs...) # 2A -> 0
    return savefig(fig, PathSpec(fullspec), args...; kwargs...)
end

function savefig(fig::FunctionSpec, args...; kwargs...) # 2B -> 2A -> 0
    return savefig(fig, String(nameof(fig)), args...; kwargs...)
end

# TODO: Look into the possibility of using 
# const FormatSpec = Union{String, Symbol, Format}
# const Formats = Union{FormatSpec, AbstractVector{<:FormatSpec}, AbstractSet{<:FormatSpec}, Tuple{Vararg{FormatSpec}}} 
# same as in with `Chars` in julia `Base` module. <28-01-25> 

# NOTE: `Tuple` as a sequence of formats is not included in these two methods because it can be confused with the
# `SizeSpec` `(w,h)` tuple. <31-01-25>
function savefig(
    fig::FunctionSpec, name::AbstractString, formats::Union{Vector,Set}, args...; kwargs...
) # 2B -> 2A -> 0
    return savefig(fig, PathSpec(name, formats), args...; kwargs...)
end

function savefig(
    fig::FunctionSpec,
    name::AbstractString,
    formats::Union{Vector,Set},
    dir::AbstractString,
    args...;
    kwargs...,
) # 2C -> 2A -> 0
    return savefig(fig, PathSpec(name, formats, dir), args...; kwargs...)
end

function savefig(
    fig::FunctionSpec, name::AbstractString, dir::AbstractString, args...; kwargs...
) # 2D -> 2A -> 0
    return savefig(fig, PathSpec(name, dir), args...; kwargs...)
end

function savefig(fig::FunctionSpec, path::PathSpec, args...; kwargs...) # 3A -> 0
    return savefig(fig, path, SizeSpec(args...); kwargs...)
end
