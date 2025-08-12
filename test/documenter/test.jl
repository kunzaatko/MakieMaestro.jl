using Base: get_extension
using Combinatorics
using Logging
using Documenter
using Random

ext = get_extension(MakieMaestro, :DocumenterExt)
@assert !isnothing(ext)
@testset "MakieBlockOptions named" begin
  @test ext.MakieBlockOptions(name="name1") == parse(ext.MakieBlockOptions, " name1")
  @test ext.MakieBlockOptions(name="name1") == parse(ext.MakieBlockOptions, " name1;")
  @test ext.MakieBlockOptions(name="name2", basename="basename1") == parse(ext.MakieBlockOptions, " name2; basename=\"basename1\"")
end

@testset "MakieBlockOptoins parsing" begin
  using MakieMaestro.Themes
  Themes.width!(Themes.A4_WIDTH)
  Themes.hwratio!(2 / (√(5) + 1))

  FORMAT_KW = [
    ((; formats=[:png, :pdf]), "formats = [:png, :pdf]"),
    ((; formats=[:png]), "formats = :png"),
  ]
  THEME_KW = [
    ((; theme=[:some]), "theme = :some"),
    ((; theme=[:some1, :some2]), "theme = [:some1, :some2]"),
  ]
  ALT_KW = [
    ((; alt="alt1"), "alt = \"alt1\""),
  ]
  BASENAME_KW = [
    ((; basename="basename1"), "basename = \"basename1\""),
  ]
  CAPTION_KW = [
    ((; caption="caption1"), "caption = \"caption1\""),
  ]
  SIZE_KW = [
    ((; size=MakieMaestro.SizeSpec(10u"cm")), "size = 10u\"cm\""),
    ((; size=MakieMaestro.SizeSpec((15u"cm", 10u"cm"))), "size = (15u\"cm\", 10u\"cm\")"),
    ((; size=MakieMaestro.SizeSpec((15u"cm", 0.5))), "size = (15u\"cm\", 0.5)"),
    ((; size=MakieMaestro.SizeSpec((0.5, 2))), "size = (0.5, 2)"),
    ((; size=MakieMaestro.SizeSpec((2, 10u"cm"))), "size = (2, 10u\"cm\")"),
  ]
  arg_combs = filter(collect(combinations([FORMAT_KW..., THEME_KW..., ALT_KW..., BASENAME_KW..., CAPTION_KW..., SIZE_KW...]))) do c
    all(g -> length(intersect(c, g)) <= 1, (FORMAT_KW, THEME_KW, ALT_KW, BASENAME_KW, CAPTION_KW, SIZE_KW))
  end

  @testset "MakieBlockOptions option parsing $(join([kw[2] for kw in c], ","))" for c in first(Random.shuffle(arg_combs), 40)
    Random.shuffle!(c)
    arg_string = " A; " * join([kw[2] for kw in c], ",")
    correct_opts = merge(merge((kw[1] for kw in c)...), (; name="A"))
    correct_out = ext.MakieBlockOptions(; correct_opts...)
    parsed_out = parse(ext.MakieBlockOptions, arg_string)
    for f in fieldnames(typeof(parsed_out))
      @test getfield(parsed_out, f) == getfield(correct_out, f)
    end
  end
end

if (@__MODULE__) === Main && !@isdefined examples_root
  include("make.jl")
elseif (@__MODULE__) !== Main && isdefined(Main, :examples_root)
  using Documenter
  const examples_root = Main.examples_root
elseif (@__MODULE__) !== Main && !isdefined(Main, :examples_root)
  error("examples/make.jl has not been loaded into Main.")
end

figdir(doc) = joinpath(builds_directory, doc, "assets/figures")
@testset "simple" begin
  let dir = figdir("makie-maestro-simple")
    @test isdir(dir)
    figures = readdir(abspath(dir))
    @test length(figures) == 1
    @test endswith(figures[1], ".svg")
    @test startswith(figures[1], "makie_")
  end
end

@testset "multi" begin
  let dir = figdir("makie-maestro-multi")
    @test isdir(dir)
    figures = readdir(abspath(dir))
    @test all(f -> any(endswith(f, ext) for ext in [".svg", ".png", ".pdf"]), figures)
    @test length(filter(Base.Fix2(startswith, "makie_A_"), figures)) == 1
    @test length(filter(Base.Fix2(startswith, "makie_B_"), figures)) == 0
    @test length(filter(Base.Fix2(startswith, "cos"), figures)) == 1
    @test length(filter(Base.Fix2(startswith, "formats"), figures)) == 2
    @test length(filter(Base.Fix2(startswith, "makie_D_"), figures)) == 2
    @test length(filter(Base.Fix2(startswith, "noname"), figures)) == 1

    @test length(filter(Base.Fix2(startswith, "formats"), figures)) > 0

    let formats = filter(Base.Fix2(startswith, "formats"), figures)
      @test length(filter(Base.Fix2(endswith, ".pdf"), formats)) == 1
      @test length(filter(Base.Fix2(endswith, ".png"), formats)) == 1
      @test length(filter(Base.Fix2(endswith, ".svg"), formats)) == 0
    end
  end
end

# TODO: Return helpful errors for errors that happen in the blocks instead of just throwing when the plotting does not
# work <12-08-25> 
