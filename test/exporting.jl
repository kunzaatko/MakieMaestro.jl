using Logging

function fig_function_w_kwargs(lims::Tuple{Real,Real}=(0, 1); N=100)
    f = Figure()
    ax = Axis(f[1, 1])
    xs = LinRange(lims..., N)
    lines!(ax, xs, sin.(xs))
    return f
end

fig_function(lims::Tuple{Real,Real}=(0, 1)) = fig_function_w_kwargs(lims)

figs_function(lims::Tuple{Real,Real}=(0, 1)) = (fig_function_w_kwargs(lims), fig_function_w_kwargs(lims))

@testset "Caching" begin
    using MakieMaestro: uniqueids, uniqueid, FunctionSpec
    f1(args...; kwargs...) = lines(args...; kwargs...)
    fspec1 = FunctionSpec(f1, (1:10, 1:10))
    @test uniqueid(fspec1) == uniqueid(fspec1)
    @test uniqueid(fspec1; axis=(; title="Line")) != uniqueid(fspec1)
    @test uniqueids(fspec1; axis=(; title="Line")).args == uniqueids(fspec1).args
    @test uniqueids(fspec1; axis=(; title="Line")).code_lowered == uniqueids(fspec1).code_lowered
    @test uniqueids(fspec1; axis=(; title="Line")).code_typed != uniqueids(fspec1).code_typed
    @test uniqueids(fspec1; axis=(; title="Line")).kwargs != uniqueids(fspec1).kwargs
    @test uniqueid(fspec1) == 0x2f12f969fb9de155

    f2(args...; kwargs...) = lines(args...; kwargs...)
    fspec2 = FunctionSpec(f2, (1:10, 1:10))
    @test uniqueid(fspec1) != uniqueid(fspec2)

    f3(args...; kwargs...) = scatter(args...; kwargs...)
    fspec3 = FunctionSpec(f3, (1:10, 1:10))
    @test uniqueid(fspec1) != uniqueid(fspec3)
end

@testset "format" begin
    using MakieMaestro: Format, extension

    @test parse(Format, "png") == MakieMaestro.Png
    @test_throws ArgumentError parse(Format, "pngx")
    @test parse(Format, "pdf") == MakieMaestro.Pdf

    @test extension(MakieMaestro.Pdf) == ".pdf"
    @test extension(MakieMaestro.PdfTex) == ".pdf"
end

@testset "Argument transformation cascade" begin
    @testset "FunctionSpec" begin
        using MakieMaestro: FunctionSpec
        @test FunctionSpec(fig_function) isa FunctionSpec
        fspec_1 = FunctionSpec(fig_function)
        @test FunctionSpec(fig_function, ((-π, π),)) isa FunctionSpec
        fspec_2 = FunctionSpec(fig_function, ((-π, π),))
        @test fspec_1() isa Figure
        @test fspec_2() isa Figure
        @test nameof(fspec_1) == nameof(fspec_2) == :fig_function

        @test FunctionSpec(fig_function_w_kwargs) isa FunctionSpec
        fspec_3 = FunctionSpec(fig_function_w_kwargs)
        @test FunctionSpec(fig_function_w_kwargs, ((-π, π),)) isa FunctionSpec
        fspec_4 = FunctionSpec(fig_function_w_kwargs, ((-π, π),))
        @test fspec_3() isa Figure
        @test fspec_4(; N=300) isa Figure
    end

    @testset "PathSpec" begin
        using MakieMaestro
        using MakieMaestro: PathSpec

        with_logger(NullLogger()) do
            @test_throws ArgumentError PathSpec(
                "test", Set([MakieMaestro.Png]), "testdir"
            ) # NOTE: Non-existent directory
            dir = pwd()
            @test PathSpec("test.pdf", dir) isa PathSpec
            @test PathSpec(joinpath(dir, "test.png")) isa PathSpec
            pnfs_1 = PathSpec(joinpath(dir, "test.png"))
            @test MakieMaestro.Png in pnfs_1.formats
            @test pnfs_1.dirname == dir
            @test pnfs_1.basename(0) == "test"
            @test pnfs_1.basename(1) == "test_1"
            @test pnfs_1.basename(2) == "test_2"

            @test PathSpec(joinpath(dir, "test.{png,svg,pdf,pdf_tex}")) isa PathSpec
            @test PathSpec(joinpath(dir, "test.{png, svg, pdf, pdf_tex}")) isa PathSpec # NOTE: With spaces
            pnfs_2 = PathSpec(joinpath(dir, "test.{png,svg,pdf,pdf_tex}"))
            @test Set([
                MakieMaestro.Png,
                MakieMaestro.Svg,
                MakieMaestro.Pdf,
                MakieMaestro.PdfTex,
            ]) ⊆ pnfs_2.formats

            @test_throws ArgumentError PathSpec(joinpath(dir, "test.{pdf, png"))
            @test_throws ArgumentError PathSpec(joinpath(dir, "test.pdf, png}"))
            @test_throws ErrorException PathSpec(joinpath(dir, "testpdf")) # no default format set

            export_format!(Set([MakieMaestro.Pdf]))
            MakieMaestro.FIGURE_DIR[] = missing
            temp_path = joinpath(tempdir(), "mm_test_dir/")
            isdir(temp_path) || mkdir(temp_path)
            @test cd(temp_path) do
                PathSpec("testpdf") isa PathSpec
            end
            rm(temp_path; recursive=true)
            @test MakieMaestro.Pdf in PathSpec(joinpath(dir, "testpdf")).formats
            @test PathSpec("test", dir) isa PathSpec

            @test_throws ArgumentError PathSpec(
                joinpath(dir, "test.{png,svgpdf}"), # invalid extension
            )

            @test PathSpec("test", [:png, "svg", MakieMaestro.PdfTex], dir) isa PathSpec
        end
    end

    @testset "sizing" begin
        using MakieMaestro: SizeSpec, RelativeSize
        using MakieMaestro.Themes
        width!(MakieMaestro.Themes.A4_WIDTH)

        @test RelativeSize(0.5) isa RelativeSize
        @test_throws ArgumentError RelativeSize(-0.5)

        @test SizeSpec() isa SizeSpec
        @test SizeSpec(30u"cm") isa SizeSpec
        @test SizeSpec(RelativeSize(0.5)) isa SizeSpec
        @test SizeSpec(0.5) isa SizeSpec
        @test SizeSpec(0.5) == SizeSpec(RelativeSize(0.5))
        @test SizeSpec(30u"cm", 0.5) isa SizeSpec
        @test SizeSpec(0.5, 0.5) isa SizeSpec
        @test_throws ArgumentError SizeSpec(0.5, -0.5) isa SizeSpec

        @test FigHeight(0.5) isa FigHeight
        @test FigHeight(30u"cm") isa FigHeight

        @test SizeSpec(FigHeight(30u"cm"), 0.5) isa SizeSpec
        @test SizeSpec(FigHeight(0.5), 0.5) isa SizeSpec
    end
end

@testset "`savefig`" begin
    # setup
    fig_dir = joinpath(tempdir(), "test_fig_dir")
    isdir(fig_dir) || mkdir(fig_dir)
    figure_dir!(fig_dir)
    width!(0.8MakieMaestro.Themes.A4_WIDTH)

    @test MakieMaestro.Pdf in export_format!(Set([MakieMaestro.Pdf]))

    @testset "utils" begin
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

    @testset "method availability" begin
        figexists(name) = isfile(joinpath(fig_dir, name))
        rmfig(name) = rm(joinpath(fig_dir, name))
        # NOTE: Comparison may not be made with `pdf` because the file is not the same even with the same figure <30-01-25> 
        issamefig(a, b) = success(`cmp --quiet $(joinpath(fig_dir, a)) $(joinpath(fig_dir, b))`)

        with_logger(NullLogger()) do
            @testset "Basic methods" begin
                # function without kwargs
                savefig(fig_function)
                @test figexists("fig_function.pdf")
                rmfig("fig_function.pdf")

                # function with kwargs
                savefig(fig_function_w_kwargs)
                @test figexists("fig_function_w_kwargs.pdf")
                rmfig("fig_function_w_kwargs.pdf")

                # arguments to the figure function
                savefig(fig_function, ((-π, π),))
                @test figexists("fig_function.pdf")
                rmfig("fig_function.pdf")

                if Sys.which("cmp") !== nothing # Check if UNIX system command exists
                    savefig(fig_function, ["svg"])
                    savefig(fig_function_w_kwargs, ["svg"]; N=300)

                    # figure function gets the kwargs
                    @test !issamefig("fig_function_w_kwargs.svg", "fig_function.svg")

                    rmfig.(("fig_function_w_kwargs.svg", "fig_function.svg"))
                end

                if Sys.which("inkscape") !== nothing
                    savefig(fig_function, ["pdf_tex"])
                    @test figexists("fig_function.pdf_tex")
                    rmfig("fig_function.pdf_tex")
                end
            end

            @testset "Multiple formats" begin
                savefig(fig_function, ["svg", MakieMaestro.Pdf])
                @test all(figexists.(("fig_function.svg", "fig_function.pdf")))
                rmfig.(("fig_function.svg", "fig_function.pdf"))

                savefig(fig_function, "name.{pdf,png}")
                @test all(figexists.(("name.pdf", "name.png")))
                rmfig.(("name.pdf", "name.png"))

                # Specifying a different name
                savefig(fig_function, "other_name")
                @test figexists("other_name.pdf")
                rmfig("other_name.pdf")

                savefig(fig_function, "other_name", ["svg", :pdf])
                @test all(figexists.(("other_name.pdf", "other_name.svg")))
                rmfig.(("other_name.pdf", "other_name.svg"))
            end

            @testset "Setting the figure directory " begin
                alt_fig_dir = joinpath(tempdir(), "alt_fig_dir")
                isdir(alt_fig_dir) || mkdir(alt_fig_dir)

                savefig(fig_function, "name1", alt_fig_dir)
                savefig(fig_function, "name2", ["pdf"], alt_fig_dir)
                savefig(fig_function, joinpath(alt_fig_dir, "name3"), ["pdf"])
                savefig(fig_function, joinpath(alt_fig_dir, "name4.pdf"))

                @test all(!figexists, ("name1.pdf", "name2.pdf", "name3.pdf", "name4.pdf"))
                @test all(isfile.((joinpath(alt_fig_dir, n) for n in ["name1.pdf", "name2.pdf", "name3.pdf", "name4.pdf"])))

                rm.((joinpath(alt_fig_dir, n) for n in ["name1.pdf", "name2.pdf", "name3.pdf", "name4.pdf"]))
                rm(alt_fig_dir; recursive=true) # cleanup
            end

            @testset "Sizing" begin
                savefig(fig_function, 100u"cm")
                @test figexists("fig_function.pdf")
                rmfig("fig_function.pdf")

                # explicitly using the default values to test whether they are used
                @testset "Default size values" begin
                    if Sys.which("cmp") !== nothing # Check if UNIX system command exists
                        savefig(fig_function, "orig_size.svg")
                        savefig(fig_function, "relative_size_one.svg", MakieMaestro.RelativeSize(1))
                        savefig(fig_function, "relative_size_one_notyping.svg", 1)
                        @test issamefig("orig_size.svg", "relative_size_one.svg")
                        @test issamefig("orig_size.svg", "relative_size_one_notyping.svg")

                        savefig(fig_function, "width_same.svg", MakieMaestro.Themes.get_width())
                        @test issamefig("orig_size.svg", "width_same.svg")

                        savefig(fig_function, "hwratio_same.svg", 1, MakieMaestro.Themes.get_hwratio())
                        @test issamefig("orig_size.svg", "hwratio_same.svg")

                        rmfig.(("orig_size.svg", "relative_size_one.svg", "width_same.svg", "hwratio_same.svg")) # cleanup
                    end
                end
            end
        end

        # Warning that the error may be thrown due to SizeSpec arguments being passed to fig_function
        Logging.disable_logging(Logging.Info) # NOTE: Must enable logging after tests for warn
        @test_logs (:warn,) @test_throws MethodError savefig(
            fig_function, (100u"cm", 0.6)
        )
        @test_logs (:warn,) @test_throws MethodError savefig(
            fig_function, (0.7, 10u"cm")
        )
        Logging.disable_logging(Logging.Warn)

        # explicit FunctionSpec does not warn
        @test_nowarn savefig(FunctionSpec(fig_function), (10u"cm", 10u"cm"))
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        # height + default hwratio
        savefig(fig_function, FigHeight(100u"cm"))
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        # width + hwratio
        savefig(fig_function, 100u"cm", 0.6)
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        # height + hwratio
        savefig(fig_function, FigHeight(100u"cm"), 0.6)
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        # Multiple figures from a single function
        savefig(figs_function, [:svg])
        @test figexists("figs_function_1.svg") && figexists("figs_function_2.svg")
        rmfig.(("figs_function_1.svg", "figs_function_2.svg"))
    end

    # teardown
    rm(fig_dir; recursive=true)
    export_format!(missing)
    MakieMaestro.Themes.WIDTH_DEFAULT[] = missing
    MakieMaestro.FIGURE_DIR[] = missing
end
