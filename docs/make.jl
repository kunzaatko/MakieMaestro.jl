using MakieMaestro
using Documenter

DocMeta.setdocmeta!(MakieMaestro, :DocTestSetup, :(using MakieMaestro); recursive=true)

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
        "Workflow" => "workflow.md"
    ],
)

deploydocs(;
    repo="github.com/kunzaatko/MakieMaestro.jl",
    devbranch="trunk",
)
