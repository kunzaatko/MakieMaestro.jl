using MakieMaestro
using Documenter

# NOTE: When updating, must update also in `test/runtests.jl` and `test/fix_doctests.jl`<18-12-24> 
DocMeta.setdocmeta!(
    MakieMaestro, :DocTestSetup, :(using MakieMaestro;
    using Logging; # NOTE: This does not need to be in the `make.jl` of docs. We want `@warn ` to function there <19-12-24> 
    Logging.disable_logging(Logging.Warn)); recursive=true
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
        "Workflow" => "workflow.md",
        "Manual" => "manual.md",
        "Reference" => "reference.md",
    ],
)

deploydocs(; repo="github.com/kunzaatko/MakieMaestro.jl", devbranch="trunk")
