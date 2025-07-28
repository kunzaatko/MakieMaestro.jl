function fig_function_w_kwargs(lims::Tuple{Real,Real}=(0, 1); N=100)
    f = Figure()
    ax = Axis(f[1, 1])
    xs = LinRange(lims..., N)
    lines!(ax, xs, sin.(xs))
    return f
end

fig_function(lims::Tuple{Real,Real}=(0, 1)) = fig_function_w_kwargs(lims)

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
        if !haskey(ENV, "GITHUB_ACTIONS") # NOTE: tmp directories do not work as expected in the CI <31-01-25> 
            temp_dir = mkdir(joinpath(tempdir(), "mm_test_dir/"))
            cd(temp_dir)
            @test PathSpec("testpdf") isa PathSpec
            rm(temp_dir; recursive=true)
        end
        @test MakieMaestro.Pdf in PathSpec(joinpath(dir, "testpdf")).formats
        @test PathSpec("test", dir) isa PathSpec

        @test_throws ArgumentError PathSpec(
            joinpath(dir, "test.{png,svgpdf}"), # invalid extension
        )

        @test PathSpec("test", [:png, "svg", MakieMaestro.PdfTex], dir) isa PathSpec
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
    # NOTE: Prepare 
    fig_dir = joinpath(tempdir(), "test_fig_dir")
    mkdir(fig_dir)
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
        issamefig(a, b) =
            success(`cmp --quiet $(joinpath(fig_dir, a)) $(joinpath(fig_dir, b))`)

        # Basic methods
        savefig(fig_function)
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        savefig(fig_function_w_kwargs)
        @test figexists("fig_function_w_kwargs.pdf")
        rmfig("fig_function_w_kwargs.pdf")

        # TODO: Add note to the documentation about the need to add the comma in order for the argument to be
        # parsed as a tuple and not normal parens <30-01-25> 
        savefig(fig_function, ((-π, π),))
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        if Sys.which("cmp") !== nothing # Check if UNIX system command exists
            savefig(fig_function, ["svg"])
            # NOTE: Comparison may not be made with `pdf` because the file is not the same even with the same
            # figure <30-01-25> 
            # NOTE: Different `N`. Should not be the same as `fig_function`
            savefig(fig_function_w_kwargs, ["svg"]; N=300)
            @test !issamefig("fig_function_w_kwargs.svg", "fig_function.svg")
            # NOTE: Same `N`. Should be the same as `fig_function`
            savefig(fig_function_w_kwargs, ["svg"]; N=100)
            @test issamefig("fig_function_w_kwargs.svg", "fig_function.svg")
            rmfig.(("fig_function_w_kwargs.svg", "fig_function.svg"))
        end

        if Sys.which("inkscape") !== nothing
            savefig(fig_function, ["pdf_tex"])
            @test figexists("fig_function.pdf_tex")
            rmfig("fig_function.pdf_tex")
        end

        # Multiple formats
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

        # Specifying the figure directory
        alt_fig_dir = joinpath(tempdir(), "alt_fig_dir")
        mkdir(alt_fig_dir)
        savefig(fig_function, "name1", alt_fig_dir)
        savefig(fig_function, "name2", ["pdf"], alt_fig_dir)
        savefig(fig_function, joinpath(alt_fig_dir, "name3"), ["pdf"])
        savefig(fig_function, joinpath(alt_fig_dir, "name4.pdf"))
        @test any(
            figexists.(("name1.pdf", "name2.pdf", "name3.pdf", "name4.pdf"))
        ) == false
        @test all(
            isfile.(
                map(
                    n -> joinpath(alt_fig_dir, n),
                    ["name1.pdf", "name2.pdf", "name3.pdf", "name4.pdf"],
                )
            ),
        )
        rm.(
            map(
                n -> joinpath(alt_fig_dir, n),
                ["name1.pdf", "name2.pdf", "name3.pdf", "name4.pdf"],
            )
        )
        rm(alt_fig_dir; recursive=true)

        # Sizing 
        savefig(fig_function, 100u"cm")
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        if Sys.which("cmp") !== nothing # Check if UNIX system command exists
            savefig(fig_function, "orig_size.svg")

            savefig(
                fig_function, "relative_size_one.svg", MakieMaestro.RelativeSize(1)
            )
            savefig(fig_function, "relative_size_one_notyping.svg", 1)
            @test issamefig("orig_size.svg", "relative_size_one.svg")
            @test issamefig("orig_size.svg", "relative_size_one_notyping.svg")

            savefig(fig_function, "width_same.svg", MakieMaestro.Themes.get_width())
            @test issamefig("orig_size.svg", "width_same.svg")

            savefig(
                fig_function,
                "hwratio_same.svg",
                1,
                MakieMaestro.Themes.get_hwratio(),
            )
            @test issamefig("orig_size.svg", "hwratio_same.svg")

            rmfig.((
                "orig_size.svg",
                "relative_size_one.svg",
                "width_same.svg",
                "hwratio_same.svg",
            ))
        end

        # NOTE: Warns that the error may be thrown due to SizeSpec arguments being passed to
        # fig_function <31-01-25> 
        using Logging
        Logging.disable_logging(Logging.Info) # NOTE: Must enable logging after DocTests
        # l = TestLogger()
        # Logging.with_logger(l) do
        #     try
        @test_logs (:warn,) @test_throws MethodError savefig(
            fig_function, (100u"cm", 0.6)
        )
        @test_logs (:warn,) @test_throws MethodError savefig(
            fig_function, (0.7, 10u"cm")
        )
        Logging.disable_logging(Logging.Warn)
        @test_nowarn savefig(FunctionSpec(fig_function), (10u"cm", 10u"cm"))
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        savefig(fig_function, FigHeight(100u"cm"))
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        savefig(fig_function, 100u"cm", 0.6)
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")

        savefig(fig_function, FigHeight(100u"cm"), 0.6)
        @test figexists("fig_function.pdf")
        rmfig("fig_function.pdf")
    end

    # NOTE: Destroy
    rm(fig_dir; recursive=true)
    export_format!(missing)
    MakieMaestro.Themes.WIDTH_DEFAULT[] = missing
end
