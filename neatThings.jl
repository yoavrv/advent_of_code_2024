
function readToBlockMatrix(path)
    permutedims(reduce(hcat, [[x for x in line] for line in eachline(path, keep=false)]))
end

function stringToBlockMatrix(s)
    permutedims(reduce(hcat,[[y for y in x] for x in split(replace(s, "\r"=>""),'\n', keepempty=false)]))
end

function nextBinaryPemutation(m, n, curr=nothing)
    """stolen from the internet"""
    if isnothing(curr)
        return UInt(1<<m - 1)
    end
    t = curr | (curr - 1); #  t gets curr's least significant 0 bits set to 1
    # // Next set to 1 the most significant bit to change, 
    # // set to 0 the least significant ones, and add the necessary 1 bits.

    next = (t + 1) | (((~t & -~t) - 1) >> (trailing_zeros(curr) + 1));
    if 1 << (n+m) ≤ next || next == 0 || next < 0
        return nothing
    end
    return next
end
