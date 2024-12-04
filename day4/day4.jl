
testInput = """MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
"""

miniTestInput="""..X...
.SAMX.
.A..A.
XMAS.S
.X....
"""

println(testInput)

puzzleInput = read(joinpath("day4","puzzle_input4.txt"), String)

# part one

function solveXmasPuzzle(puzzleString)
    puzzleString = String(puzzleString)
    lengthLine = findfirst('\n',puzzleString)
    dm = ".{$(lengthLine-2)}" #back diag
    dl = ".{$(lengthLine-1)}" #col
    dp = ".{$(lengthLine+0)}" #diag 
    substrs = [ "XMAS" "SAMX" ["X$(x)M$(x)A$(x)S" for x in [dm, dl, dp]]... ["S$(x)A$(x)M$(x)X" for x in [dm, dl, dp]]...]
    # no good way to count "double" or "triple" matches?
    return sum(count(Regex(x,"s"), puzzleString, overlap=true) for x in substrs)
end

function align(s)
    s = String(s)
    firstline = findfirst('\n',s)
    if isnothing(firstline)
        return s
    end
    secondline = findfirst('\n',s[firstline+1:end])
    if isnothing(secondline)
        secondline = length(s) - firstline
    end
    return ("."^(max(secondline-firstline, 0)))*s
end

function printmatches(puzzleString)
    puzzleString = String(puzzleString)
    lengthLine = findfirst('\n',puzzleString)
    for m in matches
        i = m.offset-1
        println("___ $i: ($(i÷lengthLine),$(i%lengthLine)) ___") 
        println(align(m.match))  
    end
end

function mymatches(rs, s)
    collect(eachmatch(Regex(rs,"s"), s, overlap=true))
end

println("For test input: ", solveXmasPuzzle(testInput))

println("For puzzle input: ", solveXmasPuzzle(puzzleInput))


# part 2

function solveX_masPuzzle(puzzleString)
    puzzleString = String(puzzleString)
    lengthLine = findfirst('\n',puzzleString)
    dm = ".{$(lengthLine-2)}" #back diag
    substrs = [ "S.S$(dm)A$(dm)M.M"  "S.M$(dm)A$(dm)S.M"  "M.M$(dm)A$(dm)S.S"  "M.S$(dm)A$(dm)M.S" ]
    # no good way to count "double" or "triple" matches?
    return sum(count(Regex(x,"s"), puzzleString, overlap=true) for x in substrs)
end

println("For part 2 test input: ", solveX_masPuzzle(testInput))

println("For part 2 puzzle input: ", solveX_masPuzzle(puzzleInput))