include("Day21Visualization.jl")


# visualize example

steps = "<vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A"

# steps = "<vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A"

state = [CartesianIndex(4, 3), CartesianIndex(1, 3), CartesianIndex(1, 3), nothing]
output=[]
verbose = true
for c in steps
    level, res = tick!(state, charToPad[c], verbose=verbose)
    if level==1
        push!(output, res)
        println(output)
    end
    if verbose sleep(0.1) end
end

function animate(steps; printLayer=1)
    state = [CartesianIndex(4, 3), CartesianIndex(1, 3), CartesianIndex(1, 3), nothing]
    output=[]
    verbose = true
    for c in steps
        level, res = tick!(state, charToPad[c], verbose=verbose)
        if level==printLayer
            push!(output, res)
            println(output)
        end
        if verbose sleep(0.3) end
    end
    return output
end

# deep thinking:
# This is probably a dynamic programming question
# I did not learn dynamic programming

# Looking down, we see that, starting at P, to get action Q in layer n:
# (P)Q
# In layer n+1, we need to get to Q and press A. We start at A because we just pressed P
# (A)xxxxA
# Since we are moving in a 2D space, x must be one of two direction
# e.g.
# to press v in a layer, starting at A, we can use <vA:
#  0: |'.'| |'^'| ['A'] 1: |'.'| ['^'] |'A'| 2: |'.'| |'^'| |'A'| 3: |'.'| |'^'| |'A'|
#     |'<'| |'v'| |'>'|    |'<'| |'v'| |'>'|    |'<'| ['v'] |'>'|    |'<'| ('V') |'>'|
# Here x is one 'v' and one '<'. We can commute the xs, up to falling from the board, i.e. <v and v> are both valid

# To go between layers up, we need to end with A, so we should always have
# (A)XYZA
# which is expanded to
# (A)xxxAyyyAzzzAaaaA
# and we can independantly solve each subproblem
# (A)xxxA (A)yyyA (A)zzzA (A)aaaA

# Lets do ðe old caching 
# (n,   'A', 'B') => ['<' 'v' 'A']
# (n-1, 'A', '<') => ['v' '>' '>' 'A']
# (n-2, 'A', 'v') => ['v' '<' 'A']
# ...
# and then and the final layer
# (1, 'A', 'v') => ['v']


# We really need to optimize each transition at each layer,
# i.e.
#
# 'A'->'B'
# find possible sequencs of ">" "<", "^", "v" (as long as we get keypads without holes, this should be very simple)
# find the cost of each sequence, and pick the best
# the weight of each transition is the sum of each sub-transition
# and the weight of the final layer is 1

# We therefore need to propagate the cost up, so the cache should really be
# (layer, fromchar, tochar) => [chars in layer 1]



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


cachePossibilities = Dict{Tuple{Char, Char, Matrix{Char}}, Vector{Vector{Char}}}()
function layerGetFromAToBOptions(from, to, pad::Matrix{Char})
    if (from, to, pad) in keys(cachePossibilities)
        return cachePossibilities[(from, to, pad)]
    end

    toIndex = CartesianIndex(1, 1)
    fromIndex = CartesianIndex(1, 1)
    for (index, char) in pairs(pad)
        if from == char
            fromIndex = index
        end
        if to == char
            toIndex = index
        end
    end
    m, n = Tuple(toIndex - fromIndex)
    if m==0 && n==0
        return [['A']]
    end

    leftRight = n < 0
    topDown = m < 0
    leftRightSymbol = leftRight ? '<' : '>'
    topDownSymbol = topDown ? '^' : 'v'
    deltaLeftRight = leftRight ? CartesianIndex(0, -1) : CartesianIndex(0, 1)
    deltaTopDown = topDown ? CartesianIndex(-1, 0) : CartesianIndex(1, 0)
    mabs = abs(m)
    nabs = abs(n)

    # I assume keeping the same direction has to be cheaper
    # So if we need to move left and up we ideally should have >*^* or ^*>*
    # But we have the possibility of a '.'
    # So we need to to "get around" it.

    options = []
    perm = nextBinaryPemutation(mabs, nabs)
    while !isnothing(perm)
        pos = fromIndex
        curr = []
        p = perm
        for i=1:(mabs+nabs)
            if (p & 1) == 0
                pos += deltaLeftRight
                push!(curr, leftRightSymbol)
            else
                pos += deltaTopDown
                push!(curr, topDownSymbol)
            end
            if !checkbounds(Bool, pad, pos) || pad[pos] == '.'
                curr = nothing
                break
            end
            p = p>>1
        end
        if !isnothing(curr)
            push!(curr, 'A')
            push!(options, curr)
        end
        perm = nextBinaryPemutation(mabs, nabs, perm)
    end

    cachePossibilities[(from, to, pad)] = options
    return options
end

function solve(layer, sequence; mainLayer=4, maxLayerToCache=3)
    
    cacheSequence = Dict{Tuple{Int, Char, Char}, Union{Vector{Char}, Nothing}}()
    
    function cacheSequenceFunc(layer::Int, from::Char, to::Char)
        if layer==1 return Char[to]  end
        if layer ≤ maxLayerToCache
            if (layer, from , to) in keys(cacheSequence)
                return cacheSequence[(layer, from, to)]
            end
        end
        return nothing
    end

    function innerSolve(layer, sequence; breakCost=nothing)
        subsequence = []

        for (i, to) in enumerate(sequence)
            from = i == 1 ? 'A' : sequence[i-1]
            res = cacheSequenceFunc(layer, from, to)
            
            if isnothing(res)
                # calculate res
                if layer == mainLayer
                    possiblities = layerGetFromAToBOptions(from, to, mainPad)
                else
                    possiblities = layerGetFromAToBOptions(from, to, robotPad)
                end
                
                bestPossibility = possiblities[1]
                breakCostNow = isnothing(breakCost) ? nothing : breakCost - length(subsequence)
                bestres = innerSolve(layer-1, bestPossibility, breakCost=breakCostNow)
                for poss in possiblities[2:end]
                    
                    breakCostNow = isnothing(bestres) ? (isnothing(breakCost) ? nothing : breakCost - length(subsequence)) : length(bestres)
                    res = innerSolve(layer-1, poss, breakCost=breakCostNow)
                    if !isnothing(res) && !isnothing(bestres) && length(res) < length(bestres)
                        bestres = res
                    end
                end
                res = bestres
                if isnothing(res)
                    return nothing
                elseif layer ≤ maxLayerToCache
                    cacheSequence[(layer, from, to)] = res
                end

            end
            append!(subsequence, res)
            if !isnothing(breakCost) && breakCost < length(subsequence)
                return nothing
            end

        end

        return subsequence
    end

    return innerSolve(layer, sequence)
end

function score(sequenceAsString; mainLayer=4)
    num = parse(Int, sequenceAsString[1:end-1])
    res = solve(mainLayer, collect(sequenceAsString), mainLayer=mainLayer, maxLayerToCache=mainLayer)
    cost = length(res)
    return num*cost
end

function fullScore(sequencesAsString; mainLayer=4)
    sum(
        score(x, mainLayer=mainLayer)
        for x in split(sequencesAsString, "\n", keepempty=false)
    )
end

testInput = """
029A
980A
179A
456A
379A
"""

println("Solution for part 1 test input: ", fullScore(testInput))
puzzleInput = replace(read(joinpath("day21","puzzle_input21.txt"), String), "\r"=>"")
println("Solution for part 1 puzzle input: ", fullScore(puzzleInput))

# part 2

# println("Solution for part 2 test input: ", fullScore(testInput, mainLayer=27))

# println("Solution for part 2 puzzle input: ", fullScore(puzzleInput, mainLayer=27))


function solve2(layer, sequence)
    
    cacheSequence = Dict{Tuple{Int, Char, Char}, Union{Int, Nothing}}()
    
    function cacheSequenceFunc(layer::Int, from::Char, to::Char)
        if layer==1 return 1 end
        if (layer, from , to) in keys(cacheSequence)
            return cacheSequence[(layer, from, to)]
        end
        return nothing
    end

    mainLayer = layer

    function innerSolve(layer, sequence; breakCost=nothing)
        overallcost = 0

        for (i, to) in enumerate(sequence)
            from = i == 1 ? 'A' : sequence[i-1]
            cost = cacheSequenceFunc(layer, from, to)
            
            if isnothing(cost)
                # calculate cost
                pad = (layer == mainLayer) ?  mainPad : robotPad
                
                possiblities = layerGetFromAToBOptions(from, to, pad)
                breakCostNow = isnothing(breakCost) ? nothing : breakCost - overallcost
                bestcost = nothing

                for poss in possiblities
                    breakCostNow = isnothing(bestcost) ? breakCostNow : bestcost
                    cost = innerSolve(layer-1, poss, breakCost=breakCostNow)
                    if isnothing(bestcost)
                        bestcost = cost
                    elseif !isnothing(cost) && cost < bestcost
                        bestcost = cost
                    end
                end

                cost = bestcost
                if isnothing(cost) return nothing end
                cacheSequence[(layer, from, to)] = cost
            end

            overallcost += cost
            if !isnothing(breakCost) && breakCost < overallcost
                return nothing
            end
        end

        return overallcost
    end

    return innerSolve(layer, sequence)
end

function score2(sequenceAsString; mainLayer=4)
    num = parse(Int, sequenceAsString[1:end-1])
    cost = solve2(mainLayer, collect(sequenceAsString))
    return num*cost
end

function fullScore2(sequencesAsString; mainLayer=4)
    sum(
        score2(x, mainLayer=mainLayer)
        for x in split(sequencesAsString, "\n", keepempty=false)
    )
end

println("Solution for part 1 test input: ", fullScore2(testInput))
puzzleInput = replace(read(joinpath("day21","puzzle_input21.txt"), String), "\r"=>"")
println("Solution for part 1 puzzle input: ", fullScore2(puzzleInput))

# part 2

println("Solution for part 2 test input: ", fullScore2(testInput, mainLayer=27))

println("Solution for part 2 puzzle input: ", fullScore2(puzzleInput, mainLayer=27))