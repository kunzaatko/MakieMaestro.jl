using MakieMaestro
using Documenter, DocumenterInterLinks

# NOTE: When updating, must update also in `test/runtests.jl` and `test/fix_doctests.jl`<18-12-24> 
DocMeta.setdocmeta!(
    MakieMaestro, :DocTestSetup, :(using MakieMaestro;
    using Logging; # NOTE: This does not need to be in the `make.jl` of docs. We want `@warn ` to function there <19-12-24> 
    Logging.disable_logging(Logging.Warn)); recursive=true
)

# NOTE: Links can be explored trough the REPL with `links(query)`
links = InterLinks(
    "Unitful" => "https://painterqubits.github.io/Unitful.jl/stable/",
    "Julia" => "https://docs.julialang.org/en/v1/",
    # "Makie" => "https://docs.makie.org/stable/", # NOTE: Makie documentation does not generate an objects.inv file
    # for some reason <26-01-25> 
    # "MakieExtra" => "https://github.com/JuliaAPlavin/MakieExtra.jl" # NOTE: MakieExtra.jl does not have
    # a documentation page apart from the example notebook <26-01-25> 
)

makedocs(;
    modules=[MakieMaestro],
    authors="Martin Kunz <martinkunz@email.cz> and contributors",
    sitename="MakieMaestro.jl",
    format=Documenter.HTML(;
        canonical="https://kunzaatko.github.io/MakieMaestro.jl",
        edit_link="trunk",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Workflows" => [
            "Publication Figures" => "workflows/savefig.md",
            "Pluto.jl" => "workflows/pluto.md",
            "Documenter.jl" => "workflows/documenter.md",
        ],
        "Reference" => "reference.md",
    ],
    plugins=[links],
)

deploydocs(; repo="github.com/kunzaatko/MakieMaestro.jl", devbranch="trunk")
