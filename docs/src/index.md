```@meta
CurrentModule = MakieMaestro
```

# MakieMaestro
[MakieMaestro](https://github.com/kunzaatko/MakieMaestro.jl) attempts to add features for [Makie](https://github.com/MakieOrg/Makie.jl) to 
- Simplify theming consistency. This includes using different themes across different back-ends. See [Theming and Sizing](@ref).
- Make it easy to save-figures in different formats using different themes and with various back-ends to a given output
    directory. This also includes saving figures in all selected formats with one command. See [Exporting figures](@ref).
- Enable saving figures for a given physical size to be included in a document. See [Theming and Sizing](@ref).
- Simplifies overriding the theme for a specific case (e.g. margin figures, offset axes etc.) using _override themes_
    and functions that generate them. See [Theming and Sizing](@ref).

!!! note "Word of Warning"
    Some of the features of this package may be opinionated (with theming being the most obvious example). It is made
    with the intent of optimizing __my__ workflows, but with the hope and expectation that it will in fact be useful
    to others as well since the way I use [`Makie.jl`](https://docs.makie.org/stable/) does not differ significantly
    from others.

See also: [MakieExtra.jl](https://github.com/JuliaAPlavin/MakieExtra.jl)
