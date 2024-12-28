
testInput = """r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb
"""


function solveForInputString(s)
    lines = split(s, "\n",  keepempty=false)
    firstline = lines[1]
    
    regexLine = join(("($x)" for x in split(firstline, ", ")), "|")
    regexLine = "^($regexLine)*"*'$'
    regex = Regex(regexLine)
    
    n = 0
    for (i, line) ∈ enumerate(lines[2:end])
        m = match(regex, line)
        if !isnothing(m)
            n += 1
        end
    end
    return n
end

println("solution for test #1: ", solveForInputString(testInput))

puzzleInput = replace(read(joinpath("day19", "puzzle_input19.txt"), String), "\r"=>"")

println("solution for test #1: ", solveForInputString(puzzleInput))


# solve part 2


function solveForInputString2(s)
    lines = split(s, "\n",  keepempty=false)
    firstline = lines[1]
    
    possiblities = ["$x" for x in split(firstline, ", ")]

    cache = Dict{String, Int64}("" => 1)

    function countPossibilities(str)
        if isempty(str)
            return 1
        end
        if str in keys(cache)
            return cache[str]
        end
        n = Int64(0)
        for p in possiblities
            if startswith(str, p)
                n += countPossibilities(str[length(p)+1:end])
            end
        end
        cache[str] = n
        return n
    end
    
    n = 0
    for (i, line) ∈ enumerate(lines[2:end])
       n += countPossibilities(line)
    end
    return n
end



println("solution for test #2: ", solveForInputString2(testInput))

println("solution for test #2: ", solveForInputString2(puzzleInput))
