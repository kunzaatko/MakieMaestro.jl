# TODO: Change to centring the images in the documentation. Note that this cannot be done by using raw HTML because of
# a bug in adding the paths of the images. <03-02-25> 
using Documenter, DocumenterInterLinks
using MakieMaestro

# NOTE: When updating, must update also in `test/runtests.jl` and `test/fix_doctests.jl`<18-12-24> 
DocMeta.setdocmeta!(
    MakieMaestro, :DocTestSetup, :(
        include(joinpath(@__DIR__, "..", "test/doctestsetup.jl"));
        using MakieMaestro;
        using Logging; # NOTE: This does not need to be in the `make.jl` of docs. We want `@warn ` to function there <19-12-24> 
        Logging.disable_logging(Logging.Warn)
    ); recursive=true
)

# NOTE: Links can be explored through the REPL with `links(query)`
links = InterLinks(
    "Unitful" => "https://juliaphysics.github.io/Unitful.jl/stable/",
    "Julia" => "https://docs.julialang.org/en/v1/",
    "Documenter" => "https://documenter.juliadocs.org/stable/",
    "Makie" => "https://docs.makie.org/stable/",
    "Literate" => "https://fredrikekre.github.io/Literate.jl/v2/"
)

MakieMaestro.Themes.width!(15u"cm")
makieblocks = MakieDocBlocks(;
    path="assets/figures",
    formats=[:svg, :png, :pdf]
)

makedocs(;
    modules=[MakieMaestro],
    authors="Martin Kunz <martinkunz@email.cz> and contributors",
    sitename="MakieMaestro.jl",
    format=Documenter.HTML(;
        canonical="https://kunzaatko.github.io/MakieMaestro.jl",
        edit_link="trunk",
        size_threshold=1_000_000,
        assets=["assets/favicon.ico"],
    ),
    pages=[
        "Home" => "index.md",
        "Workflows" => [
            "Publication Figures" => "workflows/savefig.md",
            "Pluto.jl" => "workflows/pluto.md",
            "Documenter.jl" => "workflows/documenter.md",
            "Ensemble Recipes" => "workflows/mosaic.md",
        ],
        "Reference" => "reference.md",
        "API Index" => "reference_index.md"
    ],
    plugins=[
        links,
        makieblocks
    ],
    warnonly=[:missing_docs],
    doctest=false # tests run in `test/runtests.jl`
)

deploydocs(; repo="github.com/kunzaatko/MakieMaestro.jl", devbranch="trunk")

if !haskey(ENV, "GITHUB_ACTIONS")
    build_path = joinpath(@__DIR__, "build")
    cached_path = joinpath(@__DIR__, "cached")
    @info "Making cached docs at $cached_path"
    cp(build_path, cached_path; force=true)
end
