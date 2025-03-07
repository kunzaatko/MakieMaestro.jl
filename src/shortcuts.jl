"""
    L(s::String)

Shortcut for `latexstring(raw"\text{" * s * "}")`.

This is useful when you want to have LaTeX axis labels, but do not want to use the `theme_latexfonts()` theme.
"""
L(s) = begin
    @assert typeof(s) == String
    return latexstring(raw"\text{" * s * "}")
end

"""
    fftvis(fft_img)

Apply a logarithmic scaling to visualize the absolute value of the Fourier image.

# Extended help

This function takes the absolute value of the input `img` (typically the result of an FFT),
adds 1 to avoid log(0), and then applies a base-2 logarithm. This scaling helps to visualize
the wide dynamic range typically present in Fourier transforms of images.

# Examples
```julia
using FFTW
img = rand(100, 100)
fft_img = fft(img)
heatmap(fftvis(fftshift(fft_img)))
```
"""
fftvis(img) = log2.(abs.(img) .+ 1)

# TODO: Test & Document <07-03-25> 
function ±(w::Tuple{Int,Int}, point::NTuple{N,Int}) where {N}
    return map(p -> UnitRange(p - w[1], p + w[2]), point)
end
±(w::Int, args...) = ±((w, w), args...)

export L, fftvis
