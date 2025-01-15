using MakieMaestro
using Test, Documenter, CompatHelperLocal
using Aqua

include("./tools.jl")

@testset "MakieMaestro.jl" begin
    @testset "Code quality" begin
        @testset "Aqua.jl" begin
            if haskey(ENV, "RUNTESTS_FULL") || haskey(ENV, "GITHUB_ACTIONS")
                Aqua.test_all(MakieMaestro; ambiguities=false)
            else
                @info "Skipping Aqua.jl quality tests. For a full run set `ENV[\"RUNTESTS_FULL\"]=true`."
            end
        end
        @testset "Ambiguities" begin
            @test length(Test.detect_ambiguities(MakieMaestro)) == 0
        end
        @testset "Compat" begin
            CompatHelperLocal.@check(checktest = false)
        end
    end
    @testset "DocTests" begin
        # NOTE: Show for `Unitful.jl` does nm⁻¹ on macOS and nm^-1 on Linux. This is necessary, since the `jldoctest` is only one
        if !haskey(ENV, "GITHUB_ACTIONS") ||
           haskey(ENV, "RUNNER_OS") && ENV["RUNNER_OS"] == "Linux"
            # NOTE: Better than doc-testing in `make.jl` because, I can track the coverage
            # NOTE: When updating, must update also in `docs/make.jl` and  `test/fix_doctests.jl`<18-12-24> 
            DocMeta.setdocmeta!(
                MakieMaestro,
                :DocTestSetup,
                :(using MakieMaestro;
                using Logging; # NOTE: This does not need to be in the `make.jl` of docs. We want `@warn ` to function there <19-12-24> 
                Logging.disable_logging(Logging.Warn));
                recursive=true,
            )
            doctest(MakieMaestro)
        end
    end
    @testset "Theming" begin
        @testset "merge_generate" begin
            using MakieMaestro.Themes: merge_generate, ThemeGenerator, get_theme, THEME
            # @test BASE_THEME isa ThemeGenerator
            @test THEME[][:base] isa ThemeGenerator
            @test THEME[][:size] isa ThemeGenerator
            @test THEME[][:format_ticks] isa ThemeGenerator

            f_themegenerator = () -> Theme(; figure_padding=3)
            @test f_themegenerator isa ThemeGenerator
            @test theme_latexfonts isa ThemeGenerator
            @test issame(
                merge_generate(f_themegenerator, theme_latexfonts),
                Theme(; figure_padding=3, fonts=theme_latexfonts()[:fonts]),
            )
            @test merge_generate(THEME[][:size](5u"cm", 0.5)) isa Theme

            # NOTE: Test correct precedence  
            @test issame(
                merge_generate(THEME[][:size](5u"cm", 0.5), THEME[][:size](10u"cm", 0.5)),
                THEME[][:size](10u"cm", 0.5),
            )
            # NOTE: This is inconsistent in the MakieCore package. The precedence is reversed from the `merge` on
            # dictionaries. https://github.com/MakieOrg/Makie.jl/issues/1939
            @test_broken Base.merge(
                THEME[][:size](5u"cm", 0.5), THEME[][:size](10u"cm", 0.5)
            ) == THEME[][:size](10u"cm", 0.5)

            @test get_theme(:base, :rotate_labels, :orange_title) isa Theme
            @test get_theme([:base, :rotate_labels, :orange_title]) isa Theme

            @test issame(get_theme(:orange_title), get_theme([:orange_title]))
            @test issame(
                get_theme(:base, :rotate_labels, :orange_title),
                get_theme([:base, :rotate_labels, :orange_title]),
            )
        end
    end
    @testset "Exporting" begin
        @testset "theme" begin end
        @testset "`savefig`" begin
            @test MakieMaestro.get_formats([CairoMakie], Set([MakieMaestro.Png])) ==
                  [MakieMaestro.Png] # Allowed formats
            if Sys.which("inkscape") !== nothing
                @test MakieMaestro.Svg in
                      MakieMaestro.get_formats([CairoMakie], Set([MakieMaestro.PdfTex])) # Added necessary Svg format
            end
            @test_throws ArgumentError MakieMaestro.get_formats(
                [GLMakie], Set([MakieMaestro.Pdf])
            )
        end
    end
end
