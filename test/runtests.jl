using MakieMaestro
using Test, Documenter
using Aqua

include("./tools.jl")

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
            using MakieMaestro.Themes: merge_generate, ThemeGenerator, get_theme, THEME
            # @test BASE_THEME isa ThemeGenerator
            @test THEME[][:base] isa ThemeGenerator
            @test THEME[][:size] isa ThemeGenerator
            @test THEME[][:format_ticks] isa ThemeGenerator
            @test merge_generate(THEME[][:size](5u"cm", 0.5)) isa Theme

            # NOTE: Test correct precedence  
            @test merge_generate(THEME[][:size](5u"cm", 0.5), THEME[][:size](10u"cm", 0.5))[:size][] == THEME[][:size](10u"cm", 0.5)[:size][]
            # NOTE: This is inconsistent in the MakieCore package. The precedence is reversed from the `merge` on
            # dictionaries. https://github.com/MakieOrg/Makie.jl/issues/1939
            @test_broken Base.merge(THEME[][:size](5u"cm", 0.5), THEME[][:size](10u"cm", 0.5)) == THEME[][:size](10u"cm", 0.5)

            @test get_theme(:base, :rotate_labels, :orange_title) isa Theme
            @test get_theme([:base, :rotate_labels, :orange_title]) isa Theme

            @test issame(get_theme(:orange_title), get_theme([:orange_title]))
            @test issame(get_theme(:base, :rotate_labels, :orange_title), get_theme([:base, :rotate_labels, :orange_title]))
        end
    end
end
