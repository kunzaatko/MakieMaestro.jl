# TODO: Overload ± to select a window around a index <06-03-25> 
# TODO: Get the defaults figure dir and size and export format from the environment or the .env file <14-07-25> 
module MakieMaestro
using Reexport
@reexport using Unitful
using Unitful: Length

@reexport using LaTeXStrings
@reexport using Makie
# not reexported of type with MakieExtra <07-03-25> 
@reexport using Makie: @lift, Text, lift, width

# NOTE: We cannot reexport since there would be overlapping definitions with Makie re-exported from MakieExtra <22-10-24> 
using CairoMakie, GLMakie, WGLMakie
export CairoMakie, GLMakie, WGLMakie

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
include("documentation.jl")

function __init__()
    if ccall(:jl_generating_output, Cint, ()) == 0   # if we're not precompiling...
        Unitful.register(Units)

        if @isdefined PlutoRunner  # running inside Pluto
            WGLMakie.activate!()
        elseif isinteractive() # running in REPL
            GLMakie.activate!()
        end
    end

    return nothing
end

end
