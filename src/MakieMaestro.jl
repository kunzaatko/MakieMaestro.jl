# TODO: Overload ± to select a window around a index <06-03-25> 
module MakieMaestro
using Reexport
@reexport using Unitful
using Unitful: Length

@reexport using LaTeXStrings

# NOTE: No need for using Makie, since MakieExtra already re-exports Makie <22-10-24> 
@reexport using MakieExtra

# not reexported of type with MakieExtra <07-03-25> 
@reexport using Makie: lift, width, Text, @lift

# NOTE: We cannot reexport since there would be overlapping definitions with Makie re-exported from MakieExtra <22-10-24> 
using GLMakie, CairoMakie, WGLMakie
export GLMakie, CairoMakie, WGLMakie

module Units
    using Unitful
    Unitful.register(@__MODULE__)
    @unit pt "pt" Point (1//72)u"inch" false
end

include("theme/theme.jl")
include("export/savefig.jl")
include("shortcuts.jl")
include("recipe-modifications.jl")
include("pluto-helpers.jl")

function __init__()
    Unitful.register(Units)

    if @isdefined PlutoRunner  # running inside Pluto
        WGLMakie.activate!()
    elseif isinteractive() # running in REPL
        GLMakie.activate!()
    end

    return nothing
end
end
