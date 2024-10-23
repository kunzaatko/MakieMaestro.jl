```@meta
CurrentModule = MakieMaestro
```

# MakieMaestro
[MakieMaestro](https://github.com/kunzaatko/MakieMaestro.jl) attempts to add features for [Makie](https://github.com/MakieOrg/Makie.jl) to 
- Simplify theming consistency. This includes using different themes across different back-ends.
- Make it easy to save-figures in different formats using different themes and with various back-ends to a given output
  directory. This also includes saving figures in all selected formats with one command.
- Enable saving figures for a given physical size to be included in a document.
- Simplifies overriding the theme for a specific case (e.g. margin figures, offset axes etc.) using _override themes_
and functions that generate them

!!! danger "Warning"
    Most of the features of this package is opinionated including the theming. It is made with the priority of
    optimizing __my__ [workflow]().

See also: [MakieExtra.jl](https://github.com/JuliaAPlavin/MakieExtra.jl)

```@index
```

```@autodocs
Modules = [MakieMaestro]
```
