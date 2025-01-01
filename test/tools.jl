using Makie: Attributes, Observable

function issame(attrs1::Attributes, attrs2::Attributes)
    for (k, v) in attrs1
        haskey(attrs2, k) || return false
        typeof(attrs2[k]) == typeof(v) || return false
        if v isa Attributes
            issame(attrs2[k], v) || return false
        elseif v isa Observable
            v[] == attrs2[k][] || return false
        else
            attrs2[k] == v || return false
        end
    end
    for (k, v) in attrs2
        haskey(attrs1, k) || return false
        typeof(attrs1[k]) == typeof(v) || return false
        if v isa Attributes
            issame(attrs1[k], v) || return false
        elseif v isa Observable
            v[] == attrs1[k][] || return false
        else
            attrs1[k] == v || return false
        end
    end
    return true
end

