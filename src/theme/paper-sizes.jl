# TODO: Add a note of these constants existence into the documentation <05-02-25> 
# NOTE: There are many conventions to what to refer to as the "width" and what to refer to as the "height". This defines
# the dimensions in the usual portrait orientation, hence the longer side is always the height contrary to the ISO 216
# standard where the "height" (and "width") are alternatingly shorter and longer. This means that in the ISO standard,
# A4's dimensions would be height=210mm and width=297mm and in ours it would be width=210mm and height=297mm. <05-02-25> 
for (series, base_hw, count) in (
    ("A", (1189u"mm", 841u"mm"), 13),
    ("B", (1414u"mm", 1000u"mm"), 13),
    ("C", (1297u"mm", 917u"mm"), 10),
)
    for i in 0:count
        ph, pw = Symbol(series, i, "_HEIGHT"), Symbol(series, i, "_WIDTH")
        h_true, w_true = (base_hw ./ (2^((1 + i) ÷ 2), 2^(i ÷ 2)))[[
            i % 2 + 1, (i + 1) % 2 + 1
        ]]
        ph_true, pw_true = map(a -> Symbol(a, "_ISO216"), (ph, pw))

        @eval begin
            """
                const $($(string(ph_true))) = $($(h_true))
            Height of the $($(series))$($(i)) paper under the ISO 216 standard.

            See also [`$($(string(ph_true)))`](@ref), [`$($(string(ph)))`](@ref)
            """
            const $ph_true = $h_true
            """
                const $($(string(pw_true))) = $($(w_true))
            Width of the $($(series))$($(i)) paper under the ISO 216 standard.

            See also [`$($(string(pw_true)))`](@ref), [`$($(string(pw)))`](@ref)
            """
            const $pw_true = $w_true
        end

        h_standard, w_standard = floor.(Unitful.mm, (h_true, w_true))
        @eval begin
            """
                const $($(string(ph))) = $($(h_standard))
            Height of the $($series)$($i) paper as it is usually though of (unlike the ISO 216 standard defines it).

            See also [`$($(string(ph_true)))`](@ref), [`$($(string(pw)))`](@ref)
             """
            const $ph = $h_standard
            """
                const $($(string(pw))) = $($(w_standard))
            Width of the $($series)$($i) paper as it is usually though of (unlike the ISO 216 standard defines it).

            See also [`$($(string(pw_true)))`](@ref), [`$($(string(ph)))`](@ref)
             """
            const $pw = $w_standard
        end
    end
end
