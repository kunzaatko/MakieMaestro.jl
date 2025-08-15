using TOML, InterfaceFunctions
using Base: IdSet

"""
    InlineDict{K,V}
A light wrapper around the `parent::AbstractDict` that tells the logger to log inline.
"""
struct InlineDict{K,V,AD<:AbstractDict{K,V}} <: AbstractDict{K,V}
    parent::AD
end
function InlineDict{K}(args...) where {K}
    parent = Dict{K}(args...)
    return InlineDict{K,eltype(values(parent)),typeof(parent)}(parent)
end
function InlineDict{K,V}(args...) where {K,V}
    parent = Dict{K,V}(args...)
    return InlineDict{K,V,typeof(parent)}(parent)
end
InlineDict(args...) = InlineDict(Dict(args...))

Base.parent(d::InlineDict) = d.parent
Base.get(d::InlineDict, args...) = get(parent(d), args...)
Base.setindex!(d::InlineDict, args...) = setindex!(parent(d), args...)
Base.haskey(d::InlineDict, args...) = haskey(parent(d), args...)
Base.length(d::InlineDict) = length(parent(d))
Base.iterate(d::InlineDict, args...) = iterate(parent(d), args...)

"""
    FigureLogger
An abstract type that can log the figures that are created in a directory.
"""
abstract type FigureLogger end

"""
    add_entry(logger::FigureLogger, key::String, data::AbstractDict; update=true, keep=true)
Add the entry `data` under the `key` in the log file.
"""
@interface add_entry(
    logger::FigureLogger, key::String, data::AbstractDict; update=true, keep=true
)

"""
    NullLogger
A logger that does nothing.
"""
struct NullLogger <: FigureLogger end
add_entry(logger::NullLogger, args...; kwargs...) = nothing

"""
    TOMLLogger
A logger that logs the figure data in a TOML file.
"""
@kwdef struct TOMLLogger <: FigureLogger
    dir::AbstractString
    basename::AbstractString = "figure-logs"
    function TOMLLogger(dir::AbstractString, basename::AbstractString)
        isdir(dir) || throw(ArgumentError("$dir is not a valid directory"))
        return new(dir, basename)
    end
end

"""
    logs_path(l::TOMLLogger)
Get the path of the log file used by `l`
"""
logs_path(l::TOMLLogger) = joinpath(l.dir, l.basename * ".toml")

"""
    inlineids(d::AbstractDict)
Collect the [`InlineDict`](@ref) into an [`IdSet`](@extref Julia `Base.IdSet`).
"""
inlineids(d::AbstractDict) = inlineids!(d)
function inlineids!(d, inline=IdSet{InlineDict}())
    d isa InlineDict && push!(inline, d)
    for v in values(d)
        if v isa AbstractDict
            inlineids!(v, inline)
        end
    end
    return inline
end

# FIX: Inline is not preserved: https://github.com/JuliaLang/TOML.jl/issues/56 <15-08-25> 
"""
    add_entry(logger::TOMLLogger, key::String, data::AbstractDict; update=true, merge=true)
Add the entry `data` under the `key` in the log file.

If `update` is `true`, the entry under `key` will be updated if it already exists. If `merge` is `true`, the `data` will
be merged with the existing entry.
"""
function add_entry(
    logger::TOMLLogger, key::String, data::AbstractDict; update=true, merge=true
)
    log = logs_path(logger)
    !isfile(log) && touch(log)
    log_data = try
        TOML.tryparsefile(log)
    catch e
        @error "An error while parsing the TOML log at $log" exception = e
        rethrow(e)
    end
    !update && haskey(log_data, key) && return nothing

    if merge && haskey(log_data, key)
        merge!(log_data[key], data)
    else
        log_data[key] = data
    end

    try
        open(log, "w") do io
            if VERSION >= v"1.11"
                TOML.print(io, log_data; sorted=true, inline_tables=inlineids(log_data))
            else
                TOML.print(io, log_data; sorted=true)
            end
        end
    catch e
        @error "An error while writing the TOML log at $log" exception = e
        rethrow(e)
    end
end
