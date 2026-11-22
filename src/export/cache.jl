# Digest computation and content-addressed caching of exported figures. <20-11-26>
#
# The digest covers the figure-producing inputs (code, positional arguments, keyword arguments) and the resolved
# export options (basename, backend, format, figure size in points, theme keys) -- the "code + options" contract.
# Environment information (Julia, Makie, backend and MakieMaestro versions) is deliberately NOT part of the digest;
# it is recorded in the cache entries as diagnostics only (mirroring the documented trade-off of `Sphinx-Gallery`'s
# source-only caching: changing the rendering environment does not invalidate cached figures). Bump `CACHE_VERSION`
# whenever the rendering or cache semantics change in a way that should invalidate existing caches.
using SHA, Dates, CodeTracking

const CACHE_VERSION = "MakieMaestro.figure-cache/v1"

const FIGURE_CACHE_DIR = Ref{Union{Missing,String}}(missing)

"""
    figure_cache_dir!(dir)
Set the default directory of the figure cache store used by [`savefig`](@ref). The directory is created if it does
not exist yet. Unless set, `savefig` uses the hidden `.figurecache` directory inside the figure directory.

```julia
figure_cache_dir!(joinpath(pwd(), ".figurecache"))
```

See also [`get_figure_cache_dir`](@ref).
"""
function figure_cache_dir!(dir::AbstractString)
    return FIGURE_CACHE_DIR[] = mkpath(abspath(dir))
end

"""
    MakieMaestro.get_figure_cache_dir()
Get the default directory of the figure cache store, or `nothing` if it has not been set with
[`figure_cache_dir!`](@ref).
"""
function get_figure_cache_dir()
    return ismissing(FIGURE_CACHE_DIR[]) ? nothing : FIGURE_CACHE_DIR[]
end

"""
    sha256hex(x)
Return the SHA-256 hex digest of `x` (an `AbstractString` or a byte vector) as a `String`.
"""
sha256hex(x::AbstractString) = bytes2hex(sha256(codeunits(x)))
sha256hex(x::AbstractVector{UInt8}) = bytes2hex(sha256(x))

"""
    MakieMaestro.canonical_repr(x)
Deterministic plain-text representation of `x` used for digesting values.

Arrays print their full contents, so two arrays with different elements digest differently. Mutable objects without
a content-reflecting `show` method may digest identically despite differing -- such values should not be passed as
figure arguments to cached figures.
"""
canonical_repr(x) = repr("text/plain", x)

# Write a length-prefixed, name-tagged field into a digest payload so that field boundaries and types are
# unambiguous regardless of the value contents.
function digest_field!(io::IO, name::AbstractString, value::AbstractString)
    return print(io, name, ':', ncodeunits(value), ':', value)
end

function digest_value!(io::IO, name::AbstractString, x)
    if x isa Function
        code = CodeTracking.code_string(x)
        return digest_field!(io, name * "(function)", something(code, string(nameof(x))))
    end
    return digest_field!(io, name, canonical_repr(x))
end

"""
    MakieMaestro.figure_digest(fig::FunctionSpec; kwargs...) -> (digest, info)
Digest the figure-producing inputs of `fig`: the source code of the function (via `CodeTracking`), its positional
arguments and the `kwargs` that would be passed to the figure function. Returns a `(digest, info)` pair where
`digest` is the hex digest and `info` a `Dict` with diagnostics (`code_source`, `code_sha256`) for the cache entry.

If no source text is available for the function, the digest falls back to the function name and argument types
(`code_source = "name"`); such digests are weaker and may collide for different functions with the same signature.

See also [`figure_digest_code`](@ref), [`uniqueid`](@ref).
"""
function figure_digest(fspec::FunctionSpec; kwargs...)
    io = IOBuffer()
    print(io, CACHE_VERSION, '\n')
    code_string = try
        CodeTracking.code_string(fspec.fig, typeof.(fspec.args))
    catch
        # NOTE: `code_string` throws when the method does not exist for the given argument types (e.g. when the
        # arguments cascade is about to produce a `MethodError` anyway). The digest must never break the export, so
        # fall back to the name-based digest. <20-11-26> 
        nothing
    end
    code, code_source = if isnothing(code_string)
        fallback = string(
            nameof(fspec.fig), "::", join(string.(typeof.(fspec.args)), "::")
        )
        fallback, "name"
    else
        code_string, "source"
    end
    digest_field!(io, "code", code)
    for (i, arg) in enumerate(fspec.args)
        digest_value!(io, "arg$i", arg)
    end
    for k in sort(collect(keys(kwargs)))
        # NOTE: Indexing (instead of `getfield`) works both for `NamedTuple` kwargs (Julia < 1.13) and for the
        # `Base.Pairs` that kwargs are bound to on Julia >= 1.13. <20-11-26> 
        digest_value!(io, "kwarg_$k", kwargs[k])
    end
    digest = bytes2hex(sha256(take!(io)))
    info = Dict{String,Any}("code_source" => code_source, "code_sha256" => sha256hex(code))
    return (digest = digest, info = info)
end

"""
    MakieMaestro.figure_digest_code(code::AbstractString) -> String
Digest the code text `code` of a zero-argument figure function with no keyword arguments. Used by the
`@makie` Documenter block expander, which owns the code text of the block and passes the digest to `savefig` (the
sandboxed function it defines has no trackable source).

See also [`figure_digest`](@ref).
"""
function figure_digest_code(code::AbstractString)
    io = IOBuffer()
    print(io, CACHE_VERSION, '\n')
    digest_field!(io, "code", code)
    return bytes2hex(sha256(take!(io)))
end

"""
    MakieMaestro.theme_tags(backend, format, override_theme)
Canonical tags of the full export theme composition: the `:base` key, the backend and format keys, the `:size` key
and the override themes (registry keys by name, ad-hoc `Theme`s by the digest of their canonical representation).
"""
function theme_tags(backend, format::Format, override_theme)
    tags = String["base", string.(get_themes(backend, format))..., "size"]
    for t in override_theme
        if t isa Symbol
            push!(tags, "symbol:" * string(t))
        else
            push!(tags, "repr:" * sha256hex(canonical_repr(t)))
        end
    end
    return tags
end

"""
    MakieMaestro.renderdigest(figdigest, basename, backend, format, figsize, theme_keys) -> String
Digest one concrete rendered output: the [`figure_digest`](@ref) of the figure-producing inputs combined with the
export options that affect the file contents -- the output `basename`, the `backend`, the `format`, the figure size
in points and the theme keys. Cached figures with different basenames or sizes do not collide.
"""
function renderdigest(
    figdigest::AbstractString,
    basename::AbstractString,
    backend,
    format::Format,
    figsize::Tuple{Integer,Integer},
    theme_keys::Vector{String},
)
    io = IOBuffer()
    print(io, CACHE_VERSION, '\n')
    digest_field!(io, "figdigest", String(figdigest))
    digest_field!(io, "basename", string(basename))
    digest_field!(io, "backend", string(backend))
    digest_field!(io, "format", string(format))
    digest_field!(io, "figsize", join(string.(figsize), "x"))
    digest_field!(io, "themes", join(theme_keys, ","))
    return bytes2hex(sha256(take!(io)))
end

"""
    cache_environment_info(backend)
Versions of the rendering-relevant packages recorded in cache entries as diagnostics. These are deliberately not
part of the digest (see the module-level note on the "code + options" contract).
"""
function cache_environment_info(backend)
    return Dict{String,Any}(
        "julia" => string(VERSION),
        "makie" => string(pkgversion(Makie)),
        "backend" => string(pkgversion(backend)),
        "makie_maestro" => string(pkgversion(MakieMaestro)),
    )
end

"""
    cache_entry_info(figdigest, digest_info, basename, backend, format, figsize, theme_keys)
Assemble the diagnostic `info` dictionary stored alongside a cached figure in the store index.
"""
function cache_entry_info(
    figdigest::AbstractString,
    digest_info::AbstractDict,
    basename::AbstractString,
    backend,
    format::Format,
    figsize::Tuple{Integer,Integer},
    theme_keys::Vector{String},
)
    info = Dict{String,Any}(
        "figdigest" => String(figdigest),
        "basename" => string(basename),
        "backend" => string(backend),
        "format" => string(format),
        "figsize" => collect(figsize),
        "theme_keys" => theme_keys,
    )
    merge!(info, digest_info)
    merge!(info, cache_environment_info(backend))
    return info
end

"""
    FigureCacheStore
Content-addressed store of rendered figures: a `<dir>/cache-entries.toml` index plus the stored files under
`<dir>/objects/<digest[1:2]>/<digest><extension>`. The index is written by a [`TOMLLogger`](@ref) and each entry
records the digest inputs as diagnostics (see [`cache_entry_info`](@ref)) together with `created` and `lastsaved`
timestamps. Cached files are only reused when the index entry and the stored file both exist.
"""
struct FigureCacheStore
    dir::String
    logger::TOMLLogger
end
function FigureCacheStore(dir::AbstractString)
    dir = mkpath(abspath(dir))
    return FigureCacheStore(dir, TOMLLogger(dir=dir, basename="cache-entries"))
end

"""
    MakieMaestro.figure_cache_store(cache, figdir) -> Union{Nothing,FigureCacheStore}
Resolve the `cache` argument of [`savefig`](@ref) into a [`FigureCacheStore`](@ref). `false` disables the cache,
`true` uses [`get_figure_cache_dir`](@ref) or the hidden `.figurecache` directory inside `figdir`, and an
`AbstractString` is used as the store directory directly.
"""
function figure_cache_store(cache::Union{Bool,AbstractString}, figdir::AbstractString)
    cache === false && return nothing
    dir = if cache isa AbstractString
        String(cache)
    elseif !ismissing(FIGURE_CACHE_DIR[])
        FIGURE_CACHE_DIR[]
    else
        joinpath(figdir, ".figurecache")
    end
    return FigureCacheStore(dir)
end

"""
    cache_lookup!(store::FigureCacheStore, digest, target_path) -> Bool
Return `true` and copy the cached file to `target_path` if `store` holds a complete entry for `digest` (index entry
and stored file). Updates the `lastsaved` timestamp of the entry on every retrieval.
"""
function cache_lookup!(
    store::FigureCacheStore, digest::AbstractString, target_path::AbstractString
)
    digest = String(digest)
    entry = get_entry(store.logger, digest)
    (entry isa AbstractDict && haskey(entry, "file")) || return false
    stored = joinpath(store.dir, "objects", digest[1:2], entry["file"])
    isfile(stored) || return false
    mkpath(dirname(target_path))
    cp(stored, target_path; force=true)
    add_entry(
        store.logger, digest, Dict{String,Any}("lastsaved" => string(now(Dates.UTC))); merge=true
    )
    return true
end

"""
    cache_store!(store::FigureCacheStore, digest, target_path, info) -> Bool
Copy the freshly rendered file `target_path` into `store` under `digest` and write its index entry with `info` as
diagnostics. Returns `false` without writing anything if `target_path` does not exist. The file is copied first and
the index entry written last, so that an interrupted run never leaves an index entry without its content.
"""
function cache_store!(
    store::FigureCacheStore,
    digest::AbstractString,
    target_path::AbstractString,
    info::AbstractDict,
)
    isfile(target_path) || return false
    digest = String(digest)
    file = digest * splitext(target_path)[2]
    stored = joinpath(store.dir, "objects", digest[1:2], file)
    mkpath(dirname(stored))
    cp(target_path, stored; force=true)
    entry = Dict{String,Any}(
        "file" => file,
        "created" => string(now(Dates.UTC)),
        "lastsaved" => string(now(Dates.UTC)),
    )
    merge!(entry, Dict{String,Any}(string(k) => v for (k, v) in info))
    add_entry(store.logger, digest, entry; update=true, merge=false)
    return true
end
