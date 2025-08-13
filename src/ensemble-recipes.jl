using Makie: Makie

# FIX: documentation for the `mosaic` and `mosaic!` functions is outdated <28-07-25> 

# TODO: Should return Figure or Axis figure similar to `image!` in this package <17-03-25> 

# FIX: Does not work for plotting functions that expect a 3D axis such as `surface!` <17-11-24> 
# TODO: Add unit tests <17-11-24> 
# stack = rand(RGB, 10, 10, 9)
# mosaic(stack; nrows = 2)
# mosaic(stack; ncols = 2)
# mosaic(stack; axis = (;title = map(string, 1:9)))
# mat = [rand(RGB, 10, 10) for i in 1:3, j in 1:3]
# mosaic(mat; axis = (; title = map(string, 1:9)))
# mosaic([(1:10, rand(10)) for i in 1:9]; ncols = 2, plt=lines!)
# mat2 = [rand(10, 10) for i in 1:3, j in 1:3]
# mosaic(mat2; axis = (; title = map(string, 1:9)), plt=surface!)
# mosaic(mat2; axis = (; title = map(string, 1:9)), plt=heatmap!)

# TODO: The base method should instead take a plotting function that can take any iterable data and plot it into the
# supplied axis or GridCell or indexed figure if not supplied. This would allow the user to specify the axes or the
# layout <22-07-25> 

# TODO: Add support for vector like `kwargs` with length of number of data <28-07-25> 
# TODO: Now there is support for single function multiple data. Add support for multiple functions single data <28-07-25> 
function mosaic!(fn::Function, axs::AbstractArray{<:Makie.AbstractAxis}, data...; kwargs...)
    @assert length(data) == length(axs) "Number of `data`s is not equal to the length of `axs`"
    plts = map(axs, data) do a, d
        fn(a, d; kwargs...)
    end
    return plts
end

function mosaic!(axs::AbstractArray{<:Makie.AbstractAxis}, data...)
    return mosaic!(Makie.plot!, axs, data...)
end

const FigureLike = Union{Makie.Figure,Makie.GridPosition,Makie.GridSubposition}

function create_axes!(
    f::FigureLike, naxes; nrows=nothing, ncols=nothing, axis=(;), linkaxes=true
)
    if isnothing(nrows) && isnothing(ncols)
        forced_dim = :nrows
        nrows = 1
        ncols = ceil(Int, naxes / nrows)
    elseif isnothing(ncols)
        forced_dim = :nrows
        @assert nrows isa Integer "`ncols` must be an integer"
        ncols = ceil(Int, naxes / nrows)
    elseif isnothing(nrows)
        forced_dim = :ncols
        @assert ncols isa Integer "`nrows` must be an integer"
        nrows = ceil(Int, naxes / ncols)
    else # specified both `nrows` and `ncols`
        forced_dim = :none
        @assert nrows * ncols == naxes "Data length must match nrows * ncols"
    end

    axis_multi = filter(v -> v isa Vector && length(v) == naxes, axis)
    axis_single = filter(v -> !(v isa Vector) || length(v) != naxes, axis)

    if forced_dim == :nrows
        ax_inds = sort!([
            (i, j) for i in 1:nrows, j in 1:ncols if ((i - 1) * ncols) + j <= naxes
        ])
    elseif forced_dim == :ncols
        ax_inds = sort!([
            (i, j) for i in 1:nrows, j in 1:ncols if ((j - 1) * nrows) + i <= naxes
        ])
    else
        ax_inds = [(i, j) for i in 1:nrows, j in 1:ncols]
    end

    @assert length(ax_inds) == naxes

    ax = [Makie.Axis(f[i...]; axis_single...) for i in ax_inds]

    # TODO: Could be done in the construction <28-07-25> 
    for k in keys(axis_multi)
        for (i, v) in enumerate(axis_multi[k])
            setproperty!(ax[i], k, v)
        end
    end

    if linkaxes
        Makie.linkaxes!(ax...)
    end
    return ax
end

"""
    mosaic([fn::Function=plot!], data...; <keyword-args>)
    mosaic([fn::Function=plot!], datas::AbstractMatrix; <keyword-args>)

Create a grid-like arrangement of plots. If passed a `Matrix` of objects to plot, the number of rows and columns is
preserved in the grid.

# Arguments
- `nrows` / `ncols`: Number of rows / columns
- `linkaxes`: Boolean to control axis linking (default: true)
- `vargs...`: Additional plotting arguments are passed to the plotting function

# Returns
- A Makie Figure object containing the mosaic of plots that have linked axes

# Examples
```julia
# Basic usage with vector of matrices
data = [rand(10,10) for i in 1:4]
fig = mosaic(data, 2, 2)

# Using with a 3D array
data3d = rand(10,10,4) 
fig = mosaic(data3d)

# Using with a matrix
datamat = [rand(2,3) for _ in 1:3, _ in 1:4]
fig = mosaic(datamat)
```
"""
function mosaic(
    fn::Function,
    f::FigureLike,
    data::Vararg;
    nrows=nothing,
    ncols=nothing,
    axis=(;),
    linkaxes=true,
    kwargs...,
)
    ax = create_axes!(
        f, length(data); nrows=nrows, ncols=ncols, axis=axis, linkaxes=linkaxes
    )
    isinteractive() && display(f)

    return f, ax, mosaic!(fn, ax, data...; kwargs...)
end

function mosaic(args...; figure=(;), kwargs...)
    return mosaic(Makie.Figure(; figure...), args...; kwargs...)
end

function mosaic(fn::Function, args...; figure=(;), kwargs...)
    return mosaic(fn, Makie.Figure(; figure...), args...; kwargs...)
end

function mosaic(f::FigureLike, args...; kwargs...)
    return mosaic(Makie.plot!, f, args...; kwargs...)
end

const Stack = AbstractArray{T,3} where {T}
function mosaic(datas::Stack; vargs...)
    return mosaic(eachslice(datas; dims=3); vargs...)
end
function mosaic(datas::AbstractMatrix; vargs...)
    return mosaic(datas[:]; nrows=size(datas, 1), ncols=size(datas, 2), vargs...)
end
