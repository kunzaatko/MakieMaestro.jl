@testset "Constants" begin
    using MakieMaestro.Themes
    @test Themes.A4_HEIGHT == 297u"mm"
    @test Themes.A11_WIDTH == 18u"mm" # Test for rounding down

    @test Themes.A3_HEIGHT == Themes.A2_WIDTH == 420u"mm"
    @test Themes.B6_WIDTH == 125u"mm"
    @test Themes.C10_HEIGHT == 40u"mm"
end
@testset "merge_generate" begin
    using MakieMaestro.Themes: merge_generate, ThemeGenerator, get_theme, THEME
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
