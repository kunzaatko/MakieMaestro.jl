using CodeTracking

"""
    FunctionSpec(fig, args)
Specification of the function generating the figure with its arguments.

Can be called with additional keyword arguments. The arguments are passed from the `args` field.
"""
struct FunctionSpec
    fig::Function
    args::Tuple
    logs::Dict{String,Any}
end

function FunctionSpec(func::Function)
    return FunctionSpec(func, ())
end

# TODO: Log the location of the function that creates the figure <15-08-25> 
function FunctionSpec(func::Function, args::Tuple)
    logs = Dict{String,Any}()
    logs["nargs"] = length(args)
    if length(args) > 0
        logs["argtypes"] = [string(nameof(typeof(a))) for a in args]
    end
    return FunctionSpec(func, args, logs)
end

function (fspec::FunctionSpec)(; kwargs...)
    try
        fig = fspec.fig(fspec.args...; kwargs...)
        fspec.logs["nkwargs"] = length(kwargs)
        fspec.logs["kwargs"] = InlineDict(
            string(k) => v isa Int ? Int64(v) : repr(v) for (k, v) in kwargs
        )
        return fig
    catch e
        # NOTE: An error that may occur with the argument cascade is that we call the function with arguments that were
        # passed for the SizeSpec. Warn the user about that the errors indicate that this may be the case. <31-01-25>
        if (e isa Unitful.DimensionError || e isa MethodError) && any(a -> a isa Length, fspec.args)
            @warn """\
            An error occured when calling the figure function. You may have passed arguments intended for the \
            `SizeSpec` to the figure function. You may need to pass the first argument explicitely as \
            `MakieMaestro.FunctionSpec(fig_function)`.
            """
        end
        rethrow()
    end
end
function Base.nameof(fspec::FunctionSpec)
    fspec.logs["usednameof"] = true
    return nameof(fspec.fig)
end

logs(fspec::FunctionSpec) = fspec.logs

"""
    uniqueid(fspec::FunctionSpec; kwargs...) 
Generate a unique content digest for the `fspec` when called with `kwargs`.

The digest is a stable SHA-256 hex `String` computed from the source code of the figure function (via `CodeTracking`),
its positional arguments and the `kwargs`. It only changes when the figure-producing inputs change and it is stable
across Julia sessions, so it can be persisted as a cache key. Functions defined in different places but with the same
source text and arguments digest identically.

Useful for caching the figures that do not change their definitions so that they do not have to be re-generated when
re-exported.

See also [`uniqueids`](@ref).
```jldoctest; setup=:(using MakieMaestro: uniqueid, FunctionSpec)
julia> f(args...; kwargs...) = lines(args...; kwargs...);

julia> fspec1 = FunctionSpec(f, (1:10, 1:10));

julia> fspec2 = FunctionSpec(f, (1:10, 1:10));

julia> fspec3 = FunctionSpec(f, (1:20, 1:20));

julia> @assert uniqueid(fspec1) == uniqueid(fspec2)

julia> @assert uniqueid(fspec1) != uniqueid(fspec1; axis=(;title="Line")) 

julia> @assert uniqueid(fspec1) != uniqueid(fspec3)
```
"""
function uniqueid(fspec::FunctionSpec; kwargs...)
    return figure_digest(fspec; kwargs...).digest
end

"""
    uniqueids(fspec::FunctionSpec; kwargs...)
Returns a named tuple of the component digests (the figure code, the source text digest, the positional arguments and
the `kwargs`) for the `fspec` when called with `kwargs`. The `code` digest falls back to the function name and
argument types when no source text is available for the function (in which case `code_string` is `nothing`).

See also [`uniqueid`](@ref).
```jldoctest; setup=:(using MakieMaestro: uniqueids, FunctionSpec)
julia> f(args...; kwargs...) = lines(args...; kwargs...);

julia> fspec1 = FunctionSpec(f, (1:10, 1:10));

julia> fspec2 = FunctionSpec(f, (1:10, 1:10));

julia> @assert uniqueids(fspec1).code == uniqueids(fspec2).code

julia> @assert uniqueids(fspec1; axis=(;title="Line")).kwargs != uniqueids(fspec2).kwargs

julia> fspec3 = FunctionSpec(f, (1:20, 1:20));

julia> @assert uniqueids(fspec1).code == uniqueids(fspec3).code

julia> @assert uniqueids(fspec1).args != uniqueids(fspec3).args
```
"""
function uniqueids(fspec::FunctionSpec; kwargs...)
    code_string = try
        CodeTracking.code_string(fspec.fig, typeof.(fspec.args))
    catch
        nothing
    end
    code_string_id = isnothing(code_string) ? nothing : sha256hex(code_string)
    code_id = something(
        code_string_id,
        sha256hex(
            string(nameof(fspec.fig), "::", join(string.(typeof.(fspec.args)), "::"))
        ),
    )
    args_io = IOBuffer()
    for (i, arg) in enumerate(fspec.args)
        digest_value!(args_io, "arg$i", arg)
    end
    kwargs_io = IOBuffer()
    for k in sort(collect(keys(kwargs)))
        digest_value!(kwargs_io, string(k), kwargs[k])
    end
    return (
        code=code_id,
        code_string=code_string_id,
        args=bytes2hex(sha256(take!(args_io))),
        kwargs=bytes2hex(sha256(take!(kwargs_io))),
    )
end

Base.:(==)(f1::FunctionSpec, f2::FunctionSpec) = f1.fig == f2.fig && f1.args == f2.args
