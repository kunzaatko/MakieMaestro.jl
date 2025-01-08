# NOTE: Here is a great explanation of how to choose the correct colorscheme for a plot: https://seaborn.pydata.org/tutorial/color_palettes.html#qualitative-color-palettes  

# FIX: I should eliminate the attributes that are not useful or not necessary to define in the given theme. In example
# the :base theme doesn't need to have font sizes <18-10-24> 

# FIX: This theme should not set the font size. It depends on the output size which is different depending on the where
# we are plotting. In Pluto the smaller font makes the labels illegible <18-10-24> 
# FIX: Adjust font sizes <21-11-23> 
THEME[][:base] = function base_theme()
    return merge_generate(
        theme_latexfonts,
        Theme(;
            figure_padding=2,
            Axis=(
                xgridvisible=false,
                ygridvisible=false,
                xticklabelsize=10,
                yticklabelsize=10,
                xtickwidth=0.7,
                ytickwidth=0.7,
                xticksize=4,
                yticksize=4,
            ),
            Lines=(; cycle=CYCLE),
            Scatter=(cycle=CYCLE, markersize=MARKERSIZE, strokewidth=0),
            Image=(; interpolate=false),
            Heatmap=(; colormap=:Spectral),
            Colorbar=(
                labelsize=10,
                ticklabelsize=10,
                leftspinevisible=false,
                rightspinevisible=false,
                topspinevisible=false,
                bottomspinevisible=false,
                width=5,
                # labelpadding=1.5,
                tickwidth=0.7,
                ticksize=4,
            ),
            Legend=(
                labelsize=10,
                nbanks=1,
                framevisible=false,
                tellwidth=false,
                tellheight=false,
            ),
        ),
    )
end

THEME[][:raster] = Theme()
THEME[][:vector] = Theme(;
# NOTE: `rasterize=10` is a hack that enables to save with CairoMakie
# https://github.com/MakieOrg/Makie.jl/issues/1909 (makes the figures significantly larger) <16-11-23> 
# Image=(; rasterize=10),
)

THEME[][:size] = function size_theme(width::Length=get_width(), hwratio=get_hwratio())
    width_pts, height_pts = figsize(width, hwratio)
    # TODO: Is this necessary? <17-10-24> 
    # if w_pts < 250
    #     return Theme(;
    #         size=(w_pts, h_pts),
    #         # figure_padding=10
    #     )
    # else
    return Theme(; size=(width_pts, height_pts))
    # end
end

# TODO: Add Axis3 to BASE_THEME and only change what is not same <22-12-23> 
# TODO: https://docs.makie.org/stable/how-to/save-figure-with-transparency/#glmakie <20-11-23> 
THEME[][:glmakie] = Theme(; figure_padding=3)
THEME[][:wglmakie] = Theme(;)

# FIX: This is maybe not necessary anymore and it only adds memory in the saved image <16-10-24> 
THEME[][:cairomakie] = Theme(;
    backgroundcolor=:transparent, CairoMakie=(; pdf_version="1.5")
) #= px_per_unit=20, =#

# TODO: There should be a function for combining the themes based on the keys to the dictionary and the arguments
# supplied to the theme generating function if it is a generator <18-10-24> 
# FIX: Is this done? <23-10-24> 
THEME[][:interactive] = function interactive_theme(width_ratio=0.8, hwratio=get_hwratio())
    return merge_generate(
        THEME[][:glmakie],
        THEME[][:size](width_ratio * to_units(get_width()), hwratio),
        THEME[][:base],
    )
end
