using Markdown
# FIX: Think this over. It should instead return a function that does the with_backend functionality and the dict of
# plots <16-10-24> 
# NOTE: Must not be exported to enable to call as `with_backend = with_backend(plot_dict)`
# TODO: `with_backend` should accept theme as a kwarg <18-10-24> 
# TODO: Think about how should I use themes for the with_backend. Probably should handle the interactive theme more
# intensionally <18-10-24> 

function with_backend(plots::Dict)
    function _run_backend(stop_first)
        """
        with_backend$(stop_first ? "!" : "")(f, backend, args...)

        Show the output figure of function `f` called with arguments `args` with the backend `backend`
        """
        function _with_backend(f, backend, args...)
            key = hash((f, backend))
            plots[key] = haskey(plots, key) ? plots[key] + 1 : 0
            backend.activate!(; inline=backend == GLMakie)
            out = f(args...)
            if stop_first && backend == GLMakie
                plots[key] != 0 && GLMakie.display(out)
                return md"Rerun to show plot!"
            else
                return out
            end
        end
        return _with_backend
    end
    return _run_backend(true), _run_backend(false)
end
