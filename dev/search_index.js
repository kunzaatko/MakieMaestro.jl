var documenterSearchIndex = {"docs":
[{"location":"workflow/#Where-I-started:-problem-(-solution)","page":"Workflow","title":"Where I started: problem (⇒ solution)","text":"","category":"section"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"For research and experimenting, I use Pluto.jl notebooks.  When I need to study a figure/plot with more complex features, I open it with GLMakie in a separate window.  Previously I did this with code","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"begin\n    using GLMakie\n    # other packages\nend\n# other cells\nbegin\n    # figure code\nend","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"The problems with this are:","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"When I reopen the notebook for another session, every figure that I made by this code is run (Resulting only with the window of the last figure).\nAnytime I would like to open a figure and take a look, I would need to rerun that particular cell.\nI need to name every figure differently, so that Pluto.jl does not complain. (My imagination did not last for long, after which it was f1, f2, ...).\nFinding the figures that I want to look at or show to my supervisor did took time since they are not immediately recognizable unlike the figure itself.\nWhen I didn't need to observe the figure in a separate window, since it was only a simple check such as the convergence of an optimization or something similar, I would need to do something like this","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"CairoMakie.activate!()\n# figure code\nGLMakie.activate!()","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"After a while of living the hell and inconvenience of this, I decided that a change is necessary. I iterated on some workflows from using only CairoMakies static plots and switching only when necessary or using    WGLMakies interactive plots. After a while I landed on a solution that made my plotting life a walk in a rose garden. You are browsing through the documentation of my solution.","category":"page"},{"location":"workflow/#My-Current-Workflow","page":"Workflow","title":"My Current Workflow","text":"","category":"section"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"When I want to create a figure I write a function that returns a Makie figure and run","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"with_backend!(GLMakie) do\n# figure code\nend","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"and I see inspect the figure to get the information from it.","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"tip: Tip\n","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"It is often useful to use the do block syntax to define the figure function but it is also possible to use the   direct syntax","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"  with_backend!(fig_func, GLMakie, fig_func_args...)\n  ```\nNext I decide whether I want to keep, modify or discard the figure.\nIf I decide to keep the figure for reference, I would \nIf I decide to add the finishing touches to the figure such as adding axis labels etc., I will typically want to save it\n    as well in the future. \nBecause of this, I will create a named function for the figure.\nSince I do not need to create so many figure function names, it does not diverge to a fast numbered naming scheme as\n    `fig1`, `fig2` etc. but instead, I think of a descriptive name such as `fig_very_nice_beautiful`.\nThis also enables me to define the figure with some parameter (e.g. indices of singular functions to plot, temperature\n    parameter of the heat equation, etc.) and do some basic experimenting without too much effort with `Makie` sliders\n    or similar stuff.\nThen I add both a static `CairoMakie` (or `WGLMakie`) and an interactive `GLMakie` figure in separate blocks","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"julia withbackend(figverynicebeautiful, CairoMakie, veryniceargs...)","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"julia withbackend(figverynicebeautiful, GLMakie, veryniceargs...) # notice the missing ! ``The first run of theGLMakiebackend figure outputs onlymd\"Rerun to show plot!\"` and only any further run calls the     function and creates the figure. With this setup, I can have the best of both worlds! I see the static figures for making navigation in my sloppy experimentation notebook easier and I have the interactive     figures so that I do not miss any details and can inspect the plots in further detail later with my supervisor. As a cherry on top, the initial run does not take too much time, since the figure is not being rendered but only     abstractly created. This makes the initial run in a resumed session a lot faster.","category":"page"},{"location":"workflow/","page":"Workflow","title":"Workflow","text":"note: How does it work?\nThere is a global dictionary that stores the figures and the figure is shown only if the dictionary already contains this figure.","category":"page"},{"location":"reference/#Public-Documentation","page":"Reference","title":"Public Documentation","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"Documentation for MakieMaestro.jl's public interface.","category":"page"},{"location":"reference/#Contents","page":"Reference","title":"Contents","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"Pages = [\"reference.md\"]\nDepth = 2:2","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"Pages = [\"reference.md\"]","category":"page"},{"location":"reference/#Public-Interface","page":"Reference","title":"Public Interface","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"MakieMaestro.Themes.get_theme\nMakieMaestro.Themes.interactive_size!\nMakieMaestro.Themes.hwratio!\nMakieMaestro.Themes.get_hwratio\nMakieMaestro.Themes.get_width\nMakieMaestro.Themes.to_units\nMakieMaestro.Themes.figsize\nMakieMaestro.Themes.screen_parameters\nMakieMaestro.Themes.update_theme\nMakieMaestro.Themes.update_theme!\nMakieMaestro.Themes.width!\nMakieMaestro.Themes.merge_generate","category":"page"},{"location":"reference/#MakieMaestro.Themes.get_theme","page":"Reference","title":"MakieMaestro.Themes.get_theme","text":"get_theme(themes::Vector{Union{ThemeGenerator,Symbol}}; dict = THEME[])\nget_theme(A, B, C, ...; dict = THEME[])\n\nCreate theme for specified keys and/or generators (including Themes).\n\nArguments\n\nkeys::Vector{Symbol}: A vector of symbols representing the desired theme property keys.\n\nExample\n\ngap = true\ntheme_props = get_theme([Theme(; figure_padding=2), :font, () -> Theme(; colgap = gap, rowgap = gap),  :linewidth, :color])\n\nThis will return a theme that combines the three specified themes together. Note that rightmost has precedence unlike merges on usual julia dictionaries, but same as with Makie.Attributes.\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.interactive_size!","page":"Reference","title":"MakieMaestro.Themes.interactive_size!","text":"interactive_size!(ratio::Tuple{Number,Number}; index=nothing) -> Tuple\n\nCalculate the interactive size based on the given ratio and screen parameters.\n\nArguments\n\nratio::Tuple{Number,Number}: A tuple of two numbers between 0 and 1 representing the ratio of the screen size.\nindex::Union{Nothing,Int}: Optional. If provided, uses the screen parameters at the specified index.\n\nReturns\n\nA tuple representing the calculated interactive size.\n\nThrows\n\nArgumentError: If the ratio is not between 0 and 1.\nAny error that might occur when filtering for the default screen.\n\nDescription\n\nThis function calculates the interactive size by multiplying the screen size with the provided ratio.  If an index is provided, it uses the screen parameters at that index. Otherwise, it attempts to use  the default screen parameters.\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.hwratio!","page":"Reference","title":"MakieMaestro.Themes.hwratio!","text":"hwratio!(val)\n\nSet the default height-width ratio for figures.\n\njulia> MakieMaestro.hwratio!(0.8)\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.get_hwratio","page":"Reference","title":"MakieMaestro.Themes.get_hwratio","text":"get_hwratio()\n\nGet the default height-width ratio for figures\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.get_width","page":"Reference","title":"MakieMaestro.Themes.get_width","text":"get_width()\n\nGet the default figure width\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.to_units","page":"Reference","title":"MakieMaestro.Themes.to_units","text":"to_units(val::Length)\n\nConvert val to Makie figure units\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.figsize","page":"Reference","title":"MakieMaestro.Themes.figsize","text":"figsize(width::Length=get_width(), hw_ratio=get_hwratio())\n\nCalculate the figure size in points based on the given width and height-to-width ratio.\n\nArguments\n\nwidth::Length: The desired width of the figure. Defaults to the result of get_width().\nhw_ratio: The height-to-width ratio. Defaults to the result of get_hwratio().\n\nExample\n\nwidth, height = figsize(800u\"px\", 0.75)\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.screen_parameters","page":"Reference","title":"MakieMaestro.Themes.screen_parameters","text":"screen_parameters() -> Vector{ScreenInfo}\n\nRetrieve information about available screens using the xdpyinfo command.\n\nThis function parses the output of xdpyinfo to extract details about each screen, including its index, dimensions in pixels and millimeters, and whether it's the default screen.\n\nReturns:\n\nA vector of ScreenInfo objects, each containing details about a screen.\n\nNote:\n\nThis function relies on the xdpyinfo command and is therefore only compatible with   systems where this command is available (typically Unix-like systems with X11).\nThe function may return an empty vector if no screens are detected or if parsing fails.\nRequires the Unitful.jl package for handling millimeter units.\n\nExample:\n\nscreens = screen_parameters()\nfor screen in screens\n    println(\"Screen $(screen.index): $(screen.size_px) pixels, $(screen.size_mm) physical size\")\nend\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.update_theme","page":"Reference","title":"MakieMaestro.Themes.update_theme","text":"update_theme(key::Symbol, with::ThemeGenerator)\n\nUpdate a specific theme component identified by key in the global THEME dictionary.\n\nArguments\n\nkey::Symbol: The key identifying the theme component to update.\nwith::ThemeGenerator: The new theme or function to update the existing theme with.\n\nSee also Use update_theme! for direct modifications.\n\nExtended help\n\nSpecific behaviour for argument types:\n\nIf the key doesn't exist in THEME, it adds the new theme or function.\nIf the key exists:\nFor an existing Theme:\nIf with is a Function, it merges the result of with with the current theme.\nIf with is a Theme, it merges the current theme with with.\nFor an existing Function:\nIf with is a Theme, it creates a new function that merges with with the result of the current function.\nIf with is a Function, it throws an ArgumentError.\n\nThrows\n\nArgumentError: If attempting to update a generating function with another generating function.\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.update_theme!","page":"Reference","title":"MakieMaestro.Themes.update_theme!","text":"update_theme!(key::Symbol, new::ThemeGenerator)\n\nUpdate a specific theme component in the global theme.\n\nArguments\n\nkey::Symbol: The key representing the theme component to be updated.\nnew::ThemeGenerator: The new theme generator to replace the existing one.\n\nThis function modifies the global theme by replacing the theme generator for the specified component with a new one. It directly updates the THEME global variable.\n\nSee also Use update_theme for a function a non-overwriting method.\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.width!","page":"Reference","title":"MakieMaestro.Themes.width!","text":"width!(val)\n\nSet the default width for figures.\n\njulia> MakieMaestro.width!(177u\"mm\" * 0.8)\n\n\n\n\n\n","category":"function"},{"location":"reference/#MakieMaestro.Themes.merge_generate","page":"Reference","title":"MakieMaestro.Themes.merge_generate","text":"merge_generate(themes::ThemeGenerator)\n\nMerge and generate themes from a ThemeGenerator.\n\nThis function takes a ThemeGenerator (which can be a collection of themes or theme-generating functions) and merges them into a single theme. If an element of themes is a function, it is called to generate a theme; otherwise, the element is used as-is.\n\nArguments\n\nthemes::ThemeGenerator: A collection of themes or theme-generating functions.\n\nReturns\n\nA merged theme combining all the input themes. Note that the inputs that earlier in the collection have precedence.\n\nExample\n\ntheme = merge_generate(BASE_THEME,Theme(; figure_padding=2), GL_THEME, SIZE_THEME(20u\"cm\", 0.5))\n\n\n\n\n\n","category":"function"},{"location":"reference/#RecipeOverrides","page":"Reference","title":"RecipeOverrides","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = MakieMaestro","category":"page"},{"location":"#MakieMaestro","page":"Home","title":"MakieMaestro","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"MakieMaestro attempts to add features for Makie to ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Simplify theming consistency. This includes using different themes across different back-ends.\nMake it easy to save-figures in different formats using different themes and with various back-ends to a given output directory. This also includes saving figures in all selected formats with one command.\nEnable saving figures for a given physical size to be included in a document.\nSimplifies overriding the theme for a specific case (e.g. margin figures, offset axes etc.) using override themes","category":"page"},{"location":"","page":"Home","title":"Home","text":"and functions that generate them","category":"page"},{"location":"","page":"Home","title":"Home","text":"danger: Warning\nMost of the features of this package is opinionated including the theming. It is made with the priority of optimizing my workflow.","category":"page"},{"location":"","page":"Home","title":"Home","text":"See also: MakieExtra.jl","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [MakieMaestro]","category":"page"},{"location":"#MakieMaestro.L-Tuple{Any}","page":"Home","title":"MakieMaestro.L","text":"L(s::String)\n\nShortcut for latexstring(raw\"\text{\" * s * \"}\").\n\nThis is useful when you want to have LaTeX axis labels, but do not want to use the theme_latexfonts() theme.\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.Recipes.image!-Tuple{Any, Vararg{Any}}","page":"Home","title":"MakieMaestro.Recipes.image!","text":"Recipes.image!(args...; decorations=false, interpolate=false, axis=(; aspect=DataAspect()), colormap=:viridis, kwargs...)\n\nModified image! recipe that enables the user to set axis attributes even with the mutating function and has different defaults.\n\ndecorations – hide the axis decorations if set to false\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.Recipes.image-Tuple","page":"Home","title":"MakieMaestro.Recipes.image","text":"Recipes.image(f)\n\nHelper for setting the prefered options (interpolate, ax.aspect, decorations) for the image recipe.\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.fftvis-Tuple{Any}","page":"Home","title":"MakieMaestro.fftvis","text":"fftvis(fft_img)\n\nApply a logarithmic scaling to visualize the absolute value of the Fourier image.\n\nExtended help\n\nThis function takes the absolute value of the input img (typically the result of an FFT), adds 1 to avoid log(0), and then applies a base-2 logarithm. This scaling helps to visualize the wide dynamic range typically present in Fourier transforms of images.\n\nExample\n\nusing FFTW\nimg = rand(100, 100)\nfft_img = fft(img)\nheatmap(fftvis(fftshift(fft_img)))\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.figure_dir!-Tuple{AbstractString}","page":"Home","title":"MakieMaestro.figure_dir!","text":"figure_dir!(dir)\n\nSet the figure directory\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.get_figure_dir-Tuple{}","page":"Home","title":"MakieMaestro.get_figure_dir","text":"get_figure_dir()\n\nGet the figure directory\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.savefig","page":"Home","title":"MakieMaestro.savefig","text":"savefig(fig_function, name, dir; <keyword arguments>)\n\nSave a figure output by fig_function in with themes applied and various formats in dir with the file name name\n\nParameters:\n\nfig_function: function that generates the figure or figures to save\nname: name of the file to save the figure as or vector of names if multiple figures are returned\ndir: relative or absolute path to the project directory (default: FIGURE_DIR)\n\nSave a figure in the selected formats. If :pdf_tex format is requested, Inkscape is used to convert the SVG file to PDF with text in LaTeX.\n\nKeyword arguments:\n\nhwratio=HWRATIO_DEFAULT\nwidth=WIDTH_DEFAULT\nbackend=CairoMakie\noverride_theme=Theme()\nsize_theme=SIZE_THEME\nbase_theme=BASE_THEME\nvector_theme=VECTOR_THEME\nraster_theme=RASTER_THEME\ngl_theme=GL_THEME\ncairo_theme=CAIRO_THEME\nskip=[:eps, :pdf_tex, :svg, :raster] - other options are :svg, :pdf, :pdf_tex, :eps, :png, :raster, :vector\nfig_function_args=()\nupdate=false\n\n\n\n\n\n","category":"function"},{"location":"#MakieMaestro.skip-Tuple{Vararg{Union{MakieMaestro.Format, Symbol}}}","page":"Home","title":"MakieMaestro.skip","text":"skip(skips::Vararg{Union{Symbol,Format}})\n\nGenerate a set of allowed formats by excluding specified formats or format groups.\n\nArguments\n\nskips: Variable number of arguments specifying formats or format groups to exclude.          Can be individual Format types or symbols :raster or :vector.\n\nReturns\n\nA Set of allowed Format types after excluding the specified formats.\n\nExamples\n\nskip(:raster)  # Excludes Png format\nskip(:vector)  # Excludes Png, Eps, PdfTex, and Svg formats\nskip(Png, Svg) # Excludes Png and Svg formats specifically\n\nThis function is useful for customizing the output formats when saving figures, allowing you to easily exclude certain format types or groups of formats.\n\n\n\n\n\n","category":"method"},{"location":"#MakieMaestro.vectorgraphic-Tuple{Any}","page":"Home","title":"MakieMaestro.vectorgraphic","text":"vectorgraphic(x)\n\nDetermine if the given format is a vector graphic format.\n\nArguments\n\nx: The format to check.\n\nReturns\n\ntrue if the format is a vector graphic format (Svg, Png, Eps, or PdfTex), false otherwise.\n\nExamples\n\nvectorgraphic(Svg)   # returns true\nvectorgraphic(Jpg)   # returns false\n\n\n\n\n\n","category":"method"}]
}
