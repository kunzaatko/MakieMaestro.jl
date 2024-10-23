# TODO: Add an override theme for Title. It is useful in the interactive setting. Also a override theme for title not
# visible which is useful for a figure with multiple axes but I do not want to save them with the axis titles. <22-10-24> 
# TODO: fix the notebooks and the scripts that are already done with the old system <18-10-24> 
using OffsetArrays, LaTeXStrings

function format_ticks(ticks)
    if ticks isa Vector{<:Real}
        if all(isinteger, ticks)
            return latexstring.(Int64.(ticks))
        else
            return latexstring.(ticks)
        end
    else
        return ticks
    end
end

THEME[][:format_ticks] = Theme(;
    Axis=(; xtickformat=format_ticks, ytickformat=format_ticks)
)

# TODO: Make a default for the offset tick locations based on the Makie tick locations framework <18-10-24> 
THEME[][:offset_ticks] = function offset_ticks(arr::OffsetArray, offset_tick_locations)
    offsets = arr.offsets
    parent_tick_locations =
        map(offset_tick_locations, offsets) do ax_offset_ticks, ax_offset
            ax_offset_ticks .- ax_offset
        end

    return Theme(;
        Axis=(;
            xticks=(parent_tick_locations[1], latexstring.(offset_tick_locations[1])),
            yticks=(parent_tick_locations[2], latexstring.(offset_tick_locations[2])),
        ),
    )
end

THEME[][:no_spine] = Theme(;
    Axis=(;
        topspinevisible=false,
        rightspinevisible=false,
        leftspinevisible=false,
        bottomspinevisible=false,
    ),
)
THEME[][:tiny_ticklabels] = Theme(;
    Axis=(;
        xticklabelsize=5,
        yticklabelsize=5,
        xticklabelpad=1,
        yticklabelpad=1,
        # xticklabelalign=(:center, :top),
        # yticklabelalign=(:right, :center)
    )
)
THEME[][:tiny_ticks] = Theme(;
    Axis=(; xticksize=1, yticksize=1, xtickwidth=0.2, ytickwidth=0.2)
)

# TODO: This should have a default parameter set to π/4 <18-10-24> 
THEME[][:rotate_labels] = Theme(; Axis=(xticklabelrotation=π / 4, yticklabelrotation=π / 4))

THEME[][:no_ticks] = Theme(; Axis=(
    # xticksize=0,
    # yticksize=0,
    # xtickwidth=0,
    # ytickwidth=0,
    xticksvisible=false,
    yticksvisible=false,
))

# TODO: These override themes should be defined for Axis3 also <28-12-23> 
THEME[][:no_ticklabels] = Theme(;
    Axis=(
        xticklabelsvisible=false,
        yticklabelsvisible=false,
        xticksvisible=false,
        yticksvisible=false,
    ),
)

THEME[][:data_aspect] = Theme(; Axis=(aspect=DataAspect(),))

# TODO: Default parameter <18-10-24> 
THEME[][:figure_padding] = function figure_padding(pad)
    return Theme(; figure_padding=pad)
end

# TODO: This shouldn'ŧ be a thing at all <18-10-24> 
THEME[][:figure_pad] = Theme(; figure_padding=6)

# FIX: As was stated above... Should be done by the keys and arguments with a function <18-10-24> 
# THEME[][:margin_px_ticks] = merge(TINY_TICKLABELS, NO_TICKS)

THEME[][:orange_title] = Theme(; Axis=(titlecolor=:orange,))
