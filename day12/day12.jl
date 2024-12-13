# 1
testInput ="""RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE
"""

miniTestInput="""AAAA
BBCD
BBCC
EEEC
"""

function readToBlockMatrix(path)
    permutedims(reduce(hcat, [[x for x in line] for line in eachline(path, keep=false)]))
end

function stringBlockToMatrix(s)
    permutedims(reduce(hcat,[[y for y in x] for x in split(replace(s, "\r"=>""),'\n', keepempty=false)]))
end

testInput = stringBlockToMatrix(testInput)
miniTestInput = stringBlockToMatrix(miniTestInput)

puzzleInput = readToBlockMatrix(joinpath("day12", "puzzle_input12.txt"))

directions = [CartesianIndex(-1, 0),CartesianIndex(1, 0), CartesianIndex(0, 1), CartesianIndex(0, -1)]
function searchPlot!(garden, loc)
    """depth-first search, mutate garden to lowecase on the plot and count number of edges and squares"""
    edges = 0
    squares = 0
    symbol = garden[loc]
    lowSymbol = lowercase(symbol)
    if symbol == lowSymbol return (0, 0) end
    garden[loc] = lowSymbol
    visited = [loc,]
    while !isempty(visited)
        # println(garden)
        loc = pop!(visited)
        # println("at $loc")
        squares += 1
        for direction in directions
            newloc = loc + direction
            if !checkbounds(Bool, garden, newloc)
                # println("$newloc: out of bounds")
                edges += 1
            elseif garden[newloc] == symbol
                # println("$newloc: new!")
                push!(visited, newloc)
                garden[newloc] = lowSymbol
            elseif garden[newloc] != lowSymbol
                # println("$newloc: $(garden[newloc])")
                edges += 1
            else
                # println("$newloc: seen!")
            end
        end
        
    end
    edges, squares
end

function gardenCost(garden)
    s = 0
    for ij in eachindex(IndexCartesian(), garden)
        if isuppercase(garden[ij])
            edges, squares = searchPlot!(garden, ij)
            s += edges*squares
        end
    end
    garden .= uppercase.(garden)
    return s
end

println("Cost for mini test input garden: ", gardenCost(miniTestInput))
println("Cost for test input garden: ", gardenCost(testInput))
println("Cost for puzzle test input garden: ", gardenCost(puzzleInput))


# part 2

abGarden = """AAAAAA
AAABBA
AAABBA
ABBAAA
ABBAAA
AAAAAA
"""
abGarden = stringBlockToMatrix(abGarden)

exGarden = """EEEEE
EXXXX
EEEEE
EXXXX
EEEEE
"""
exGarden = stringBlockToMatrix(exGarden)

oxGarden = """OOOOO
OXOXO
OOOOO
OXOXO
OOOOO
"""
oxGarden = stringBlockToMatrix(oxGarden)


function pushDirectionEdge!(vert, horz, direction, loc)
    if direction[1] == 1
        push!(horz, loc + direction)
    elseif direction[1] == -1
        push!(horz, loc)
    elseif direction[2] == 1
        push!(vert, loc + direction)
    elseif direction[2] == -1
        push!(vert, loc)
    end
end

function edgeDiscriminateHorz(garden, edges)
    sort!(edges, by=(x-> (x[1]-1)*size(garden)[1] + x[2] - 1))
    n = length(edges)
    # Remove continuous edges
    # println("horz  ", edges)
    for  (x, y) in zip(edges[1:end-1], edges[2:end])
        if x[1] != y[1]  # same line
            # println("lines $x")
            continue
        elseif x[2]+1 != y[2] # side by side
            # println("side $x")
            continue
        elseif !checkbounds(Bool, garden, y) || y[1]==1 || (garden[x] == garden[y]) || (garden[x-CartesianIndex(1,0)] == garden[y-CartesianIndex(1,0)]) # not this cross edge-case
            n -= 1 # we had a continuous edge
            # println("$x-$y")
            continue
        end
        # println("non $x")
    end
    n
end


function edgeDiscriminateVert(garden, edges)
    sort!(edges, by=(x-> (x[2]-1)*size(garden)[2] + x[1] - 1))
    n = length(edges)
    # Remove continuous edges
    # println(edges)
    for  (x, y) in zip(edges[1:end-1], edges[2:end])
        if x[2] != y[2]  # same line
            # println("$x")
            continue
        elseif x[1]+1 != y[1] # side by side
            # println("$x")
            continue
        elseif !checkbounds(Bool, garden, y) || y[2]==1 || (garden[x] == garden[y]) || (garden[x-CartesianIndex(0, 1)] == garden[y-CartesianIndex(0, 1)]) # not this cross edge-case
            # println("$x-$y")
            n -= 1
            continue
        end
        # println("non $x")
    end
    n
end


directions = [CartesianIndex(-1, 0),CartesianIndex(1, 0), CartesianIndex(0, 1), CartesianIndex(0, -1)]
function searchPlotBulk!(garden, loc)
    """depth-first search, mutate garden to lowecase on the plot and count number of edges and squares"""
    squares = 0
    symbol = garden[loc]
    lowSymbol = lowercase(symbol)
    if symbol == lowSymbol return (0, 0) end
    garden[loc] = lowSymbol
    visited = CartesianIndex[loc,]
    visitedEdgesHorz = CartesianIndex[]
    visitedEdgesVert = CartesianIndex[]
    while !isempty(visited)
        loc = pop!(visited)
        squares += 1
        for direction in directions
            newloc = loc + direction
            if !checkbounds(Bool, garden, newloc)
                pushDirectionEdge!(visitedEdgesVert, visitedEdgesHorz, direction, loc)
            elseif garden[newloc] == symbol
                push!(visited, newloc)
                garden[newloc] = lowSymbol
            elseif garden[newloc] != lowSymbol
                pushDirectionEdge!(visitedEdgesVert, visitedEdgesHorz, direction, loc)
            end
        end
    end
    hedges = edgeDiscriminateHorz(garden, visitedEdgesHorz)
    vedges = edgeDiscriminateVert(garden, visitedEdgesVert)
    return (hedges + vedges, squares)
end

function gardenCostBulk(garden)
    s = 0
    for ij in eachindex(IndexCartesian(), garden)
        if isuppercase(garden[ij])
            edges, squares = searchPlotBulk!(garden, ij)
            # println("$ij: $edges, $squares")
            # print(garden)
            # println()
            s += edges*squares
        end
    end
    garden .= uppercase.(garden)
    return s
end

println("Cost for mini test input garden: ", gardenCostBulk(miniTestInput))
println("Cost for ox input garden: ", gardenCostBulk(oxGarden))
println("Cost for ex input garden: ", gardenCostBulk(exGarden))
println("Cost for ab input garden: ", gardenCostBulk(abGarden))
println("Cost for test input garden: ", gardenCostBulk(testInput))
println("Cost for puzzle test input garden: ", gardenCostBulk(puzzleInput))
