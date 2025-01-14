
# there is probably a very clever mathematical way to solve this

# lets hope llvm compiler is smart enouogh to do ut

function run(seed, iterations=1; verbose=false)
    num = seed
    pruneMask = (1 << 24) - 1
    for i in 1:iterations
        num = (num ⊻ (num << 6)) & pruneMask
        num = (num ⊻ (num >> 5)) & pruneMask
        num = (num ⊻ (num << 11)) & pruneMask
        if verbose println(num) end
    end
    num
end

run(123, 10, verbose=true)

testInput = [1,10,100,2024]

println("solution for past 1 test input: ", sum(run.(testInput, 2000)))


puzzleInput = parse.(Int32, readlines(joinpath("day22","puzzle_input22.txt")))
println("solution for past 1 puzzle input: ", sum(run.(puzzleInput, 2000)))

# part 2

# lets try visualize

bits = split("abcdefghijklmnopqrstuvwx","")
for i in 7:24
    bits[i] = bits[i]*"^"*bits[i-6]
end
for i in 1:(24-5)
    bits[i] = bits[i]*"^"*bits[i+5]
end
for i in 12:24
    bits[i] = bits[i]*"^"*bits[i-11]
end

# a^f
# b^g^a
# c^h^b
# d^i^c
# e^j^d
# f^k^e
# g^a^l^f
# h^b^m^g^a
# i^c^n^h^b
# j^d^o^i^c
# k^e^p^j^d
# l^f^q^k^e^a^f
# m^g^a^r^l^f^b^g^a
# n^h^b^s^m^g^a^c^h^b
# o^i^c^t^n^h^b^d^i^c
# p^j^d^u^o^i^c^e^j^d
# q^k^e^v^p^j^d^f^k^e
# r^l^f^w^q^k^e^g^a^l^f
# s^m^g^a^x^r^l^f^h^b^m^g^a
# t^n^h^b^i^c^n^h^b
# u^o^i^c^j^d^o^i^c
# v^p^j^d^k^e^p^j^d
# w^q^k^e^l^f^q^k^e^a^f
# x^r^l^f^m^g^a^r^l^f^b^g^a

# now we can simplify: any "double" xor is not doing anything (x^y^x = y)

# a^f
# b^g^a
# c^h^b
# d^i^c
# e^j^d
# f^k^e
# g^a^l^f
# h^b^m^g^a
# i^c^n^h^b
# j^d^o^i^c
# k^e^p^j^d
# l^q^k^e^a
# m^r^l^f^b
# n^s^m^g^a^c
# o^t^n^h^b^d
# p^u^o^i^c^e
# q^v^p^j^d^f
# r^w^q^k^e^g^a
# s^x^r^l^f^h^b
# t^i^c
# u^j^d
# v^k^e
# w^l^a
# x^m^b

# doesn't seem to be that good, what about a few iterations?

xors = [1<<i for i in 0:23]
function step_bits(xors)
    for i in 7:24
        xors[i] = xors[i]⊻xors[i-6]
    end
    for i in 1:(24-5)
        xors[i] = xors[i]⊻xors[i+5]
    end
    for i in 12:24
        xors[i] = xors[i]⊻xors[i-11]
    end
    xors
end

# I like this vizualization, but it seems to just be psuedo random
#  and I should just solve the questions assuming its random
