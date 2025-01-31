module MakieMaestro
using Reexport
@reexport using Unitful
using Unitful: Length

@reexport using LaTeXStrings

# NOTE: No need for using Makie, since MakieExtra already re-exports Makie <22-10-24> 
using Makie
@reexport using MakieExtra
# NOTE: We cannot reexport since there would be overlapping definitions with Makie re-exported from MakieExtra <22-10-24> 
using GLMakie, CairoMakie, WGLMakie
export GLMakie, CairoMakie, WGLMakie
# @lift = MakieExtra.@lift
# Text = MakieExtra.Text
lift = MakieExtra.lift
macro lift(a)
    MakieExtra.@lift(a)
end
width = MakieExtra.width
Text = Makie.Text
# @lift = MakieExtra.@lift
# Text = MakieExtra.Text

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
