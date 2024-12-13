using Makie: Makie

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

"""
    mosaic(datas::AbstractVector; 
            nrows, ncols,
           plt=Recipes.image!, ax_func! = identity, linkaxes=true, vargs...)
    mosaic(datas::Stack, args...; vargs...)
    mosaic(datas::AbstractMatrix; vargs...)

Create a grid-like arrangement of plots.

# Arguments
- `datas`: Vector, 3D array, or matrix of data to be plotted
- `nrows` / `ncols`: Number of rows / columns
- `plt`: Plotting function to apply (default: `image!`)  
- `ax!`: Function to modify axis properties (default: identity)
- `linkaxes`: Boolean to control axis linking (default: true)
- `vargs...`: Additional plotting arguments passed to the plotting function

The function creates a Makie Figure object with a grid of plots, applies the specified 
plotting function to each data element, and returns the resulting figure. It supports 
vectorized arguments that match the data length and automatically handles tuple-packed data.

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
    datas::AbstractVector;
    nrows=nothing,
    ncols=nothing,
    plt=Recipes.image!,
    (ax!)=identity,
    axis=(;),
    linkaxes=true,
    vargs...,
)
    if isnothing(nrows) && isnothing(ncols)
        forced_dim = :nrows
        nrows = 1
        ncols = ceil(Int, length(datas) / nrows)
    elseif isnothing(ncols)
        forced_dim = :nrows
        @assert nrows isa Integer "`ncols` must be an integer"
        ncols = ceil(Int, length(datas) / nrows)
    elseif isnothing(nrows)
        forced_dim = :ncols
        @assert ncols isa Integer "`nrows` must be an integer"
        nrows = ceil(Int, length(datas) / ncols)
    else
        forced_dim = :none
        @assert nrows * ncols == length(datas) "Data length must match nrows * ncols"
    end

    f = Makie.Figure(;)
    # TODO: Filter the others out and apply them in the axis creations <17-11-24> 
    v_axis_vargs = filter(v -> v isa Vector && length(v) == length(datas), axis)
    ax = [Makie.Axis(f[i, j]) for i in 1:nrows, j in 1:ncols]

    for k in keys(v_axis_vargs)
        for (i, v) in enumerate(v_axis_vargs[k])
            setproperty!(ax[i], k, v)
        end
    end

    if forced_dim == :nrows
        delete!.(ax[(length(datas) + 1):end]) # remove the empty axes
    elseif forced_dim == :ncols
        rest = ncols * nrows - length(datas)
        if rest != 0
            delete!.(ax[(end - rest + 1):end, end]) # remove the empty axes
        end
    end

    vector_vargs = filter(v -> v isa Vector && length(v) == length(datas), vargs)
    for (ind, (a, data)) in enumerate(zip(ax[:], datas))
        a_vargs = NamedTuple(
            map((k, v) -> k => v[ind], zip(keys(vector_vargs), vector_vargs))
        )
        if data isa Tuple # unpack the data if it is a tuple
            plt(a, data...; a_vargs..., vargs...)
        else
            plt(a, data; a_vargs..., vargs...)
        end
        ax!(a)
    end
    Makie.linkaxes!(ax...)
    return f
end
const Stack = AbstractArray{T,3} where {T}
function mosaic(datas::Stack; vargs...)
    return mosaic(eachslice(datas; dims=3); vargs...)
end
function mosaic(datas::AbstractMatrix; vargs...)
    return mosaic(datas[:]; nrows=size(datas, 1), ncols=size(datas, 2), vargs...)
end
