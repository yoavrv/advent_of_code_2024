testInput = Int64[125, 17]


puzzleInput = parse.(Int64, split(read(joinpath("day11", "puzzle_input11.txt"), String)," ",keepempty=false))

function numStones(puzzleInput, steps=25; verbose=false, extraVerbose=false)
    stones = [(0, x) for x in Iterators.reverse(puzzleInput)]
    numStones=0
    if verbose
        if !extraVerbose println(stones) end
        records = Int64[]
    end
    if extraVerbose
        allRecords = [Int64[] for x in 1:steps-1]
    end
    while 0 < length(stones)
        level, stone = pop!(stones)
        if extraVerbose && 0 <level
            push!(allRecords[level], stone)
        end
        if stone == 0
            if level+1 == steps
                if verbose push!(records,1) end
                numStones+=1
                continue 
            end
            push!(stones, (level+1, 1))
            continue
        end
        digits = length("$stone")
        if iseven(digits)
            top, bottom = divrem(stone, 10^(digits÷2))
            if level+1 == steps 
                numStones+=2
                if verbose push!(records, top); push!(records, bottom) end
                continue
            end
            push!(stones, (level+1, bottom))
            push!(stones, (level+1, top))
            continue
        else
            if level+1 == steps
                if verbose push!(records, stone*2024) end
                numStones+=1
                continue 
            end
            push!(stones, (level+1, stone*2024))
            continue
        end
    end
    if verbose println("$(steps): ", records) end
    if extraVerbose
        for (i, record) in Iterators.reverse(enumerate(allRecords))
            println("$i: ",record)
        end
        println("0: ", puzzleInput)
    end
    numStones
end

println("Solution for test input #1: ")
numStones(testInput, 6, verbose=true, extraVerbose=true)
println("solution for puzzle Input #1: ", numStones(puzzleInput))

# not good for #2, need a memoized version

const maxStoneMemory = 1000
const maxStepsMemory = 75
const sumStoneCache = -ones(Int64, (maxStepsMemory ,maxStoneMemory))

function numStone(level, stone)
    if stone == -1 return 0 end
    if level == 0 return 1 end
    if maxStepsMemory < level || maxStoneMemory < stone
        return sum(numStone(level-1, substone) for substone in stoneRules(stone))
    end
    # memoized section
    cached = sumStoneCache[level, stone+1]
    if cached != -1
        return cached
    end
    cached = sum(numStone(level-1, substone) for substone in stoneRules(stone))
    sumStoneCache[level, stone+1] = cached
    return cached
end


function stoneRules(stone)
    if stone==0 return (1, -1) end
    digits = length("$stone")
    if iseven(digits)
        return divrem(stone, 10^(digits÷2))
    end
    return (stone*2024, -1)
end

println("solution for test Input #2: ", sum(numStone(6, x) for x in testInput))
println("solution for test Input big #2: ", sum(numStone(25, x) for x in testInput))
println("solution for #1-complient puzzle Input #2 with new method: ", sum(numStone(25, x) for x in puzzleInput))

println("solution for puzzle Input #2: ", sum(numStone(75, x) for x in puzzleInput))