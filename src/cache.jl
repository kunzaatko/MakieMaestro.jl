using InteractiveUtils
function hash_code(func::Function, types)
    buf = IOBuffer()
    code_llvm(buf, func, types; optimize = false)
    s = String(take!(buf))
    s = split(s, "\n")
    filter!(x -> !startswith(x, r";|define"), s)
    s = join(s, "\n")
    return hash(s)
end
