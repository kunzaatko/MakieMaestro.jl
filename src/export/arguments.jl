# TODO: Better ways of setting the override_themes. Especially using the `Symbol`s such as `[:appendix]` in the docs.
# Then workflow docs for publication figures should be changed accordingly <09-01-25> 
# TODO: Possibility of using `skip` for defining the formats for the save <18-10-24> 

include("function-spec.jl")
include("path-spec.jl")
include("size-spec.jl")

include("savefig-arguments-cascade.jl")

export FigHeight
