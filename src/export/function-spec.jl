using InteractiveUtils, CodeTracking

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
        if (e isa Unitful.DimensionError || e isa MethodError) &&
            (fspec.args[1] isa Length || fspec.args[2] isa Length)
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
Generate a unique ID for the `fspec` when called with `kwargs`.

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
    ids = uniqueids(fspec; kwargs...)
    return hash((ids.code, ids.args, ids.kwargs))
end

"""
    uniqueids(fspec::FunctionSpec; kwargs...)
Returns a named tuple of the unique IDs for the `fspec` when called with `kwargs`.

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
    code_string = CodeTracking.code_string(fspec.fig, typeof.(fspec.args))
    code_typed = hash(string(@code_typed optimize = false fspec.fig(fspec.args; kwargs...)))
    code_lowered = string(@code_lowered fspec.fig(fspec.args; kwargs...))

    code_string_id = hash(code_string)
    code_typed_id = hash(code_typed)
    code_lowered_id = hash(code_lowered)

    code_id = !isnothing(code_string) ? code_string_id : code_typed_id
    args_id = hash(fspec.args)
    kwargs_id = hash(kwargs)
    return (;
        code=code_id,
        code_string=code_string_id,
        code_typed=code_typed_id,
        code_lowered=code_lowered_id,
        args=args_id,
        kwargs=kwargs_id,
    )
end

Base.:(==)(f1::FunctionSpec, f2::FunctionSpec) = f1.fig == f2.fig && f1.args == f2.args
