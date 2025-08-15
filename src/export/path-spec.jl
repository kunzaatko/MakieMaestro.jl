
"""
    PathSpec(basename, [formats], [dirname])
    PathSpec(fullpath, [formats])
Specification of where and which format to use for exporting a figure.

- `basename` is internally a function that takes an index integer and returns the name of the figure. The function is
    created either by a suffix or by parsing the supplied string (see examples below).
- `formats` is a set or collection of formats wanted for the export.
- `dirname` is the directory where the figure will be saved (checked for existence upon creation).

# Examples
```jldoctest; setup=:(using MakieMaestro: PathSpec)
julia> PathSpec("some_file.pdf", ".")
./some_file.pdf

julia> PathSpec("some_file.{svg,eps}", "..")
../some_file.{eps,svg}

julia> PathSpec("some_file.png", "non_existent_dir")
ERROR: ArgumentError: `non_existent_dir` is not a valid directory
[...]

julia> PathSpec("some_file",["pdf", :svg], "..")
../some_file.{pdf,svg}
"""
struct PathSpec
    basename::Function # takes an index integer and returns the name of the figure
    formats::Set{Format}
    dirname::String # checked for validity on the file-system.

    function PathSpec(basename::Function, formats::Set{Format}, dirname::AbstractString) # 0
        isdir(dirname) || throw(ArgumentError("`$dirname` is not a valid directory"))
        formats = if isempty(formats)
            default = get_export_format()
            @info "Export formats not supplied. Using default formats $default."
            default
        else
            formats
        end
        return new(basename, formats, dirname)
    end
end

function Base.show(io::IO, s::PathSpec)
    extensions = sort([extension(f)[2:end] for f in s.formats])
    ext_string =
        (length(extensions) > 1 ? "{" : "") *
        join(extensions, ",") *
        (length(extensions) > 1 ? "}" : "")
    return print(io, "$(joinpath(s.dirname,s.basename(0))).$ext_string")
end

function PathSpec(fullpath::AbstractString, formats) # 1A ?-> 0 
    dirname, basename = Base.Filesystem.dirname(fullpath),
    Base.Filesystem.basename(fullpath)
    dirname = isempty(dirname) ? get_figure_dir() : dirname
    !isempty(basename) ||
        throw(ArgumentError("Basename of the path cannot be empty. Got `$fullpath`"))
    isempty(splitext(basename)[2]) ||
        @warn "Basename has an extension $(splitext(basename)[2]). This is probably not intensional. Did you mean to supply `formats`?"
    return PathSpec(basename, formats, dirname)
end
function PathSpec(basename::AbstractString, dirname::AbstractString)
    # PERF: Not optimal... Joining strings unnecessarily for later parsing. Should be inexpensive. Avoids necessity to
    # check extension in this method also. <30-01-25> 
    return PathSpec(joinpath(dirname, basename))
end

function PathSpec(basename::AbstractString, formats, dirname::AbstractString)
    return PathSpec(name_function(basename), Set(convert.(Format, formats)), dirname)
end

"""
    PathSpec(fullspec::AbstractString)
Parses the supplied string as a path of the form `<directories...>/basename.{format1,format2,...}` or `<dirrectories...>/basename.format`.

```jldoctest; setup=:(using MakieMaestro: PathSpec)
julia> p = PathSpec("../some_file.{pdf,svg}")
../some_file.{pdf,svg}

julia> p.formats == Set([MakieMaestro.Pdf, MakieMaestro.Svg])
true

julia> p.basename(1)
"some_file_1"

julia> p.basename(0)
"some_file"
```
"""
function PathSpec(fullspec::AbstractString) # 1B -> 1A -> 0
    fullpath, ext_string = splitext(fullspec)
    if contains(ext_string, ",")
        ext_string = rstrip(ext_string)
        (ext_string[1:2] == ".{" && ext_string[end] == '}') || throw(
            ArgumentError(
                "Invalid name format (missing curly braces). Expected `name.{format1,format2,...}`. Got `$ext_string`.",
            ),
        )
        extensions = split(ext_string[3:(end - 1)], ",")
        formats = Set([parse(Format, strip(ext)) for ext in extensions])
    elseif isempty(ext_string)
        formats = Set()
    else
        formats = Set([parse(Format, ext_string[2:end])])
    end
    return PathSpec(fullpath, formats)
end

# TODO: Add documentation for this method so that the users can modify the PathSpec as they please. <14-08-25> 
function name_function(basename::AbstractString; suffix=i -> "_$i")
    function name(i)
        i == 1 &&
            @info "Using `\"$(suffix("i"))\"` name of figure `\"i\"` name. To change this, see documentation of `MakieMaestro.PathSpec`."
        return basename * (i == 0 ? "" : suffix(i))
    end
    return name
end

function Base.:(==)(p1::PathSpec, p2::PathSpec)
    return p1.dirname == p2.dirname && p1.basename == p2.basename
end
