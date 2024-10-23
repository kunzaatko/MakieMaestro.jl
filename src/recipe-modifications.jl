using ColorTypes

module Recipes

# TODO: Add these tests <16-10-24> 
# Recipes.image(rand(RGBf, 10, 10)) # should not have a `:viridis` colormap
# Recipes.image!(rand(10, 10)) # should have a `:viridis` colormap
# Recipes.image!(ax, rand(10, 10)) # should have a DataAspect independently on the aspect of the Axis set
# Recipes.image(f[1, 1], rand(10, 10)) # should work
# Recipes.image(rand(10, 10)) # should work
# Recipes.image(rand(10, 10); axis=(; aspect=AxisAspect(1.5))) # check the aspect

image = () -> ()
image! = () -> ()

end

"""
	Recipes.image!(args...; decorations=false, interpolate=false, axis=(; aspect=DataAspect()), colormap=:viridis, kwargs...)

Modified `image!` recipe that enables the user to set `axis` attributes even with the mutating function and has different defaults.

- `decorations` -- hide the axis decorations if set to `false`
"""
function Recipes.image!(
    ax,
    args...;
    decorations=false,
    interpolate=false,
    _axis=(; aspect=Makie.DataAspect()),
    colormap=if length(args) == 1 && args[1] isa AbstractMatrix{<:Colorant}
        nothing
    else
        :viridis
    end,
    axis=(;),
    kwargs...,
)
    if !isnothing(colormap)
        plt = Makie.image!(ax, args...; interpolate, colormap, kwargs...)
    else
        plt = Makie.image!(ax, args...; interpolate, kwargs...)
    end

    if !decorations
        hidedecorations!(ax)
    end

    axis = Dict(pairs(merge(_axis, axis)))
    for (k, v) in axis
        setproperty!(ax, k, v)
    end

    return plt
end

"""
	Recipes.image(f)

Helper for setting the prefered options (`interpolate`, `ax.aspect`, _decorations_) for the image recipe.
"""
function Recipes.image(args...; _axis=(; aspect=Makie.DataAspect()), axis=(;), kwargs...)
    axis = merge(_axis, axis)

    figarg, pargs = Makie.plot_args(args...)
    attributes = Dict{Symbol,Any}(kwargs..., :axis => axis)
    figkws = Makie.fig_keywords!(attributes)

    plot = Plot{Makie.default_plot_func(Image, pargs)}(pargs, attributes)
    figax = Makie.create_axis_like(plot, figkws, figarg)
    ax = figax isa Makie.FigureAxis ? figax.axis : figax

    Recipes.image!(ax, pargs...; kwargs...)
    return Makie.figurelike_return(figax, plot)
end
