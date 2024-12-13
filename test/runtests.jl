using MakieMaestro
using Test, Documenter
using Aqua

@testset "MakieMaestro.jl" begin
    if haskey(ENV, "RUNTESTS_FULL") || haskey(ENV, "GITHUB_ACTIONS")
        @testset "Code quality (Aqua.jl)" begin
            Aqua.test_all(MakieMaestro; ambiguities=false)
            # Aqua.test_all(
            #     TransferFunctions;
            #     ambiguities=(; exclude=VERSION >= v"1.11" ? [checkindex, checkbounds] : []),
            #     # ambiguities=VERSION >= v"1.1" ? (; broken=true) : false
            # )
        end
    else
        @info "Skipping Aqua.jl quality tests. For a full run set `ENV[\"RUNTESTS_FULL\"]=true`."
    end

    # FIX: When running locally, do not ask for SSH key password <10-12-23> 
    if haskey(ENV, "RUNTESTS_FULL") && (
        !haskey(ENV, "GITHUB_ACTIONS") ||
        haskey(ENV, "RUNNER_OS") && ENV["RUNNER_OS"] == "Linux"
    )
        @testset "DocTests" begin
            # NOTE: Better than doc-testing in `make.jl` because, I can track the coverage
            DocMeta.setdocmeta!(
                MakieMaestro, :DocTestSetup, :(using MakieMaestro); recursive=true
            )
            doctest(MakieMaestro)
        end
    else
        @info "Skipping Documenter.jl doctests. For a full run set `ENV[\"RUNTESTS_FULL\"]=true`."
    end
    @testset "Theming" begin
        @testset "merge_generate" begin
            using MakieMaestro.Themes: merge_generate, ThemeGenerator, BASE_THEME, get_theme, THEME
            # @test BASE_THEME isa ThemeGenerator
            @test THEME[][:base] isa ThemeGenerator
            @test THEME[][:size] isa ThemeGenerator
            @test THEME[][:format_ticks] isa ThemeGenerator
        end
    end
end
