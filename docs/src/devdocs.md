```@meta
CurrentModule=MakieMaestro
```

#  Developer Guide
Features provided by `MakieMaestro` are: 
- _Exporting_: uses _Theming_ and _Sizing_
- _Documenter plugin_: uses _Exporting_
- _Pluto.jl_ ([`with_backend`](@ref)): decoupled from anything else
- _Ensemble plots_: decoupled from anything else

# Exporting Figures
Top user facing interface is the [`savefig`](@ref) function.
The only other user facing functions that should be used by an average user are ones that are used to set the defaults
  for the `savefig` arguments.
These are:
- [`figure_dir!`](@ref),
- [`Themes.width!`](@ref)/[`Themes.hwratio!`](@ref) and 
- [`export_format!`](@ref).

## [`savefig`](@ref)

!!! note
    You should take a look at what are the possible input arguments to [`savefig`](@ref) and how composable it is in the
    [section about exporting figures](@ref exporting_figures) to understand what is being solved here.

The root implementation is in `src/export/savefig.jl` which calls the appropriate exporting functions based on the
  preprocessed arguments. 
The preprocessed arguments consist of:
- [`FunctionSpec`](@ref) 
  - Implemented in `src/export/function_spec.jl` 
  - Stores the arguments (and key-word arguments) that are passed to the figure function upon the figure creation,
  - Used to determine the name of the figure if the name is not provided
- [`SizeSpec`](@ref) 
  - Implemented in `src/export/size_spec.jl`
  - Used to determine the actual physical dimensions from the passed combination of arguments (width, height,
    height-width ratio)
  - Takes care of converting the physical size to the Makie units (See [`Themes.to_units`](@ref))
  - Uses the functions [`Themes.get_hwratio`](@ref) and [`Themes.get_width`](@ref) to use either the default or the set
    values from [`Themes.width!`](@ref) and [`Themes.hwratio!`](@ref)
- [`PathSpec`](@ref) 
  - implemented in `src/export/path_spec.jl` and `src/export/utils.jl` to determine the formats
  - Does not represent only one path but can represent multiple with different formats
  - Uses [`get_figure_dir`](@ref) to get the figure directory set by [`figure_dir!`](@ref)


## [`FigureLogger`](@ref)s
Loggers are types that can be used to monitor when a figure got exported and all of the associated metadata for the
figure creation. 
Currently, there the two concrete types implemented:
- [`NullLogger`](@ref) 
  - does nothing when adding an entry and stores no keys
- [`TOMLLogger`](@ref) 
  - stores the entries in a TOML file
