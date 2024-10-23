module MakieMaestro
using Reexport
@reexport using Unitful
using Unitful: Length

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

# TODO: Update the theme to be generated depending on the ***_DEFAULT as it cannot be set beforehand <17-10-24> 

# TODO: Add the Pluto snippet that I use for the backend function <16-10-24> 
# FIX: Define WIDTH_DEFAULT and HWRATIO_DEFAULT <15-10-24> 
# FIX: The cache location should be parametrized <15-10-24> 
# TODO: Add the `L` function <15-10-24> 

include("theme.jl")
include("save-fig.jl")
include("shortcuts.jl")
include("recipe-modifications.jl")
include("pluto-helpers.jl")

function __init__()
    Unitful.register(Units)
    return nothing
end

export savefig, L, fftvis
end
