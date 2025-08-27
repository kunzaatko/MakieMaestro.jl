# The Problem with `Pluto` + `Makie`

For research and experimenting, I use [`Pluto.jl`](https://github.com/fonsp/Pluto.jl) notebooks. 
When I need to study a figure/plot with more complex features, I open it with `GLMakie` in a separate window. 
Previously I did this with code
```julia
begin
    using GLMakie
    # other packages
end
# other cells
begin
    # figure code
end
```
The problems with this are:
1. When I reopen the notebook for another session, every figure that I made by this code is run (Resulting only with the
   window of the last figure).
2. Anytime I would like to open a figure and take a look, I would need to rerun that particular cell.
3. I need to name every figure differently, so that `Pluto.jl` does not complain. (My imagination did not last for long,
   after which it was `f1`, `f2`, ...).
4. Finding the figures that I want to look at or show to my supervisor did took time since they are not immediately
   recognizable unlike the figure itself.
5. When I didn't need to observe the figure in a separate window, since it was only a simple check such as the
   convergence of an optimization or something similar, I would need to do something like this
```julia
CairoMakie.activate!()
# figure code
GLMakie.activate!()
```
After a while of living the hell and inconvenience of this, I decided that a change is necessary.
I iterated on some workflows from using only `CairoMakie`s static plots and switching only when necessary or using
   `WGLMakie`s interactive plots. After a while I landed on a solution that made my plotting life a walk in a rose garden.
You are browsing through the documentation of my solution.

# The Solution -- `Pluto.jl` Workflow
When I want to create a figure I write a function that returns a `Makie` figure and run
```julia
with_backend!(GLMakie) do
# figure code
end
```
and I see inspect the figure to get the information from it.

!!! tip
    It is often useful to use the `do` block syntax to define the figure function but it is also possible to use the
    direct syntax
    ```julia
    with_backend!(fig_func, GLMakie, fig_func_args...)
    ```

Next I decide whether I want to keep, modify or discard the figure.
If I decide to keep the figure for reference, I would 
If I decide to add the finishing touches to the figure such as adding axis labels etc., I will typically want to save it
    as well in the future. 
Because of this, I will create a named function for the figure.
Since I do not need to create so many figure function names, it does not diverge to a fast numbered naming scheme as
    `fig1`, `fig2` etc. but instead, I think of a descriptive name such as `fig_very_nice_beautiful`.
This also enables me to define the figure with some parameter (e.g. indices of singular functions to plot, temperature
    parameter of the heat equation, etc.) and do some basic experimenting without too much effort with `Makie` sliders
    or similar stuff.
Then I add both a static `CairoMakie` (or `WGLMakie`) and an interactive `GLMakie` figure in separate blocks
```julia
with_backend(fig_very_nice_beautiful, CairoMakie, very_nice_args...)
```
```julia
with_backend(fig_very_nice_beautiful, GLMakie, very_nice_args...) # notice the missing `!`
```
The first run of the `GLMakie` backend figure outputs only `md"Rerun to show plot!"` and only any further run calls the
    function and creates the figure.
With this setup, I can have the best of both worlds!
I see the static figures for making navigation in my sloppy experimentation notebook easier and I have the interactive
    figures so that I do not miss any details and can inspect the plots in further detail later with my supervisor.
As a cherry on top, the initial run does not take too much time, since the figure is not being rendered but only
    abstractly created.
This makes the initial run in a resumed session a lot faster.

!!! note "How does it work?"
    There is a global dictionary that stores the figures and the figure is shown only if the dictionary already contains
    this figure.

!!! tip "Edit notebook code in your editor"
    If you would like to have the notebook code watch the content of the notebook file so that you can directly edit
    that file and see the outcome, this is possible in __Pluto.jl__ by specifying the `Pluto.ServerSession` prior to
    launching it like so:
    ```julia
    Pluto.run(; auto_reload_from_file=true)
    ```
    If you prefer, you may add this to your
    [`startup.jl`](@extref Julia Startup-file) file so that you do not
    need to remember next time:
    ```julia
    """
        run_pluto()

    Run Pluto session with notebook file watching enabled.
    """
    function run_pluto()
        @eval begin
            using Pluto
            Pluto.run(; auto_reload_from_file=true)
        end
    end
    ```
