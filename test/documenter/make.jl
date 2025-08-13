# NOTE: Adopted from `Documenter.jl` tests <12-08-25> 
using Documenter
include("../TestUtilities.jl")
using Main.TestUtilities

examples_root = @__DIR__
builds_directory = joinpath(examples_root, "builds")
ispath(builds_directory) && rm(builds_directory, recursive=true)

simple_pages = [
  "Home" => "simple.md",
]
multi_pages = [
  "Home" => "multi.md",
]

MakieMaestro.Themes.width!(15u"cm")
makieblocks = MakieDocBlocks(;
  path="assets/figures",
  formats=[:svg]
)

function html_doc(source, build_directory, pages; warnonly=true, kwargs...)
  return @quietly makedocs(;
    debug=true,
    root=examples_root,
    build="builds/$(build_directory)",
    sitename="MakieMaestro Documenter extension",
    source,
    pages,
    doctest=false,
    format=Documenter.HTML(;
      prettyurls=false,
      canonical="https://example.com/stable",
    ),
    warnonly,
    plugins=[makieblocks],
    kwargs...
  )
end

@info("Building `makie-maestro-simple`...")
html_doc("src.simple", "makie-maestro-simple", simple_pages)

@info("Building `makie-maestro-multi`...")
html_doc("src.multi", "makie-maestro-multi", multi_pages)
