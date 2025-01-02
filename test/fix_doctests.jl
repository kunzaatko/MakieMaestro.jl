using Pkg
Pkg.activate(@__DIR__)
using MakieMaestro
# TODO: Warn on uncommitted changes... The workflow should be to commit, run, and commit --amend <19-12-24> 
using Documenter

# NOTE: When updating, must update also in `docs/make.jl` & 'test/runtests.jl'<18-12-24> 
DocMeta.setdocmeta!(
    MakieMaestro, :DocTestSetup, :(using MakieMaestro;
    using Logging; # NOTE: This does not need to be in the `make.jl` of docs. We want `@warn ` to function there <19-12-24> 
    Logging.disable_logging(Logging.Warn)); recursive=true
)
doctest(MakieMaestro; fix=true)
