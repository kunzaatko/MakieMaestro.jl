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

        @testset "format" begin
            using MakieMaestro: Format, extension

            @test parse(Format, "png") == MakieMaestro.Png
            @test_throws ArgumentError parse(Format, "pngx")
            @test parse(Format, "pdf") == MakieMaestro.Pdf

            @test extension(MakieMaestro.Pdf) == ".pdf"
            @test extension(MakieMaestro.PdfTex) == ".pdf"
        end

        @testset "Argument transformation stack" begin
            @testset "FunctionSpec" begin
                using MakieMaestro: FunctionSpec
                function fig_function(lims::Tuple{Real,Real}=(0, 1))
                    f = Figure()
                    ax = Axis(f[1, 1])
                    xs = LinRange(lims..., 100)
                    lines!(ax, xs, sin.(xs))
                    return f
                end
                @test FunctionSpec(fig_function) isa FunctionSpec
                fspec_1 = FunctionSpec(fig_function)
                @test FunctionSpec(fig_function, ((-π, π),)) isa FunctionSpec
                fspec_2 = FunctionSpec(fig_function, ((-π, π),))
                @test fspec_1() isa Figure
                @test fspec_2() isa Figure
                @test nameof(fspec_1) == nameof(fspec_2) == :fig_function

                function fig_function_w_kwargs(lims::Tuple{Real,Real}=(0, 1); N=100)
                    f = Figure()
                    ax = Axis(f[1, 1])
                    xs = LinRange(lims..., N)
                    lines!(ax, xs, sin.(xs))
                    return f
                end

                @test FunctionSpec(fig_function_w_kwargs) isa FunctionSpec
                fspec_3 = FunctionSpec(fig_function_w_kwargs)
                # FIX: Better type for the arguments of the function <27-01-25> 
                # @test FunctionSpec(fig_function_w_kwargs, ((-π, π); N = 300)) isa FunctionSpec
                # fspec_4 = FunctionSpec(fig_function_w_kwargs, ((-π, π); N = 300))
                @test fspec_3() isa Figure
                # @test fspec_4() isa Figure
            end

            @testset "PathNameFormatSpec" begin
                using MakieMaestro
                using MakieMaestro: PathNameFormatSpec

                @test_throws ArgumentError PathNameFormatSpec(
                    "test", Set([MakieMaestro.Png]), "testdir"
                ) # NOTE: Non-existent directory
                dir = pwd()
                @test PathNameFormatSpec(joinpath(dir, "test.png")) isa PathNameFormatSpec
                pnfs_1 = PathNameFormatSpec(joinpath(dir, "test.png"))
                @test MakieMaestro.Png in pnfs_1.formats
                @test pnfs_1.dirname == dir
                @test pnfs_1.basename(0) == "test"
                @test pnfs_1.basename(1) == "test_1"
                @test pnfs_1.basename(2) == "test_2"

                @test PathNameFormatSpec(joinpath(dir, "test.{png,svg,pdf,pdf_tex}")) isa
                    PathNameFormatSpec
                @test PathNameFormatSpec(joinpath(dir, "test.{png, svg, pdf, pdf_tex}")) isa
                    PathNameFormatSpec # NOTE: With spaces
                pnfs_2 = PathNameFormatSpec(joinpath(dir, "test.{png,svg,pdf,pdf_tex}"))
                @test Set([
                    MakieMaestro.Png,
                    MakieMaestro.Svg,
                    MakieMaestro.Pdf,
                    MakieMaestro.PdfTex,
                ]) ⊆ pnfs_2.formats

                @test_throws ArgumentError PathNameFormatSpec(
                    joinpath(dir, "test.{pdf, png")
                )
                @test_throws ArgumentError PathNameFormatSpec(
                    joinpath(dir, "test.pdf, png}")
                )
                @test_throws ErrorException PathNameFormatSpec(joinpath(dir, "testpdf")) # no default format set

                default_formats!(Set([MakieMaestro.Pdf]))
                @test PathNameFormatSpec("testpdf") isa PathNameFormatSpec
                @test MakieMaestro.Pdf in
                    PathNameFormatSpec(joinpath(dir, "testpdf")).formats

                @test_throws ArgumentError PathNameFormatSpec(
                    joinpath(dir, "test.{png,svgpdf}"), # invalid extension
                )

                @test PathNameFormatSpec(
                    "test", [:png, "svg", MakieMaestro.PdfTex], dir
                ) isa PathNameFormatSpec
            end
        end
        @testset "sizing" begin
            using MakieMaestro: SizeSpec, RelativeSize, HeightLength
            using MakieMaestro.Themes
            width!(MakieMaestro.Themes.A4_WIDTH)

            @test RelativeSize(0.5) isa RelativeSize
            @test_throws ArgumentError RelativeSize(-0.5)

            # TODO: Add tests for expected final values <28-01-25> 
            @test SizeSpec() isa SizeSpec
            @test SizeSpec(30u"cm") isa SizeSpec
            @test SizeSpec(RelativeSize(0.5)) isa SizeSpec
            @test SizeSpec(0.5) isa SizeSpec
            @test SizeSpec(0.5) == SizeSpec(RelativeSize(0.5))
            @test SizeSpec(30u"cm", 0.5) isa SizeSpec
            @test SizeSpec(0.5, 0.5) isa SizeSpec
            @test_throws ArgumentError SizeSpec(0.5, -0.5) isa SizeSpec

            @test HeightLength(0.5) isa HeightLength
            @test HeightLength(30u"cm") isa HeightLength

            @test SizeSpec(HeightLength(30u"cm"), 0.5) isa SizeSpec
            @test SizeSpec(HeightLength(0.5), 0.5) isa SizeSpec
        end
    end
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
