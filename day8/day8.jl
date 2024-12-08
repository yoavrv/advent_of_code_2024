# part 1


function printboard(input)
    for row in eachrow(input)
        println(String(row))
    end
end

function stringBlockToMatrix(s)
    permutedims(reduce(hcat,[[y for y in x] for x in split(replace(s, "\r"=>""),'\n', keepempty=false)]))
end

function readToBlockMatrix(path)
    permutedims(reduce(hcat, [[x for x in line] for line in eachline(path, keep=false)]))
end


testInput = """............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............
"""

puzzleInputPath = joinpath("day8", "puzzle_input8.txt")

testGrid =stringBlockToMatrix(testInput)
puzzleGrid = readToBlockMatrix(puzzleInputPath)

function antenniFromGrid(grid)
    antenii = Dict{Char, Vector{CartesianIndex}}()
    for (ij, a) in pairs(grid)
        if a=='.' continue end
        if !haskey(antenii, a) antenii[a] = [] end
        push!(antenii[a], ij)
    end
    antenii
end

function antipodePositions(grid, antenii)
    positions = zeros(Bool, size(grid))
    for (antennaKey, antennaIndices) in pairs(antenii)
        for i in 1:(length(antennaIndices)-1)
            for j in i+1:length(antennaIndices)
                a, b = antennaIndices[i], antennaIndices[j]
                δ = b-a
                if checkbounds(Bool, positions, a-δ) positions[a-δ] = true end
                if checkbounds(Bool, positions, b+δ) positions[b+δ] = true end
            end
        end
    end
    positions
end

function antipodePositions(grid)
    antipodePositions(grid, antenniFromGrid(grid))
end

testgrid = copy(testGrid)
antipodes = antipodePositions(testgrid)
testgrid[antipodes .& (testgrid.=='.')] .= '#'
println("Solution for test input: ", sum(antipodes))
printboard(testgrid)


puzzlegrid = copy(puzzleGrid)
antipodes = antipodePositions(puzzlegrid)
puzzlegrid[antipodes .& (puzzlegrid.=='.')] .= '#'
println("Solution for puzzle input: ", sum(antipodes))
printboard(puzzlegrid)

# part 2

function reduceDelta(a, b)
    δa, δb = Tuple(b-a)
    rat = δa//δb
    CartesianIndex(copysign(numerator(rat), δa), copysign(denominator(rat), δb))
end

function fillSuperpods!(positions, a, b, verbose=false)
    positions[a], positions[b] = true, true
    δ = reduceDelta(a, b)
    if verbose println("delta:", δ) end
    more, less = true, true
    for i in 1:max(size(positions)...)
        if less
            if checkbounds(Bool, positions, a-i*δ)
                positions[a-i*δ] = true 
                if verbose println(a-i*δ) end
            else
                less = false
            end
        end
        if more
            if checkbounds(Bool, positions, b+i*δ) 
                positions[b+i*δ] = true 
                if verbose println(b+i*δ) end
            else
                more = false
            end
        end
        if !less && !more break end
    end
end

function superpodePositions(grid, antenii)
    positions = zeros(Bool, size(grid))
    for (antennaKey, antennaIndices) in pairs(antenii)
        for i in 1:(length(antennaIndices)-1)
            a = antennaIndices[i]
            for j in i+1:length(antennaIndices)
                b = antennaIndices[j]
                fillSuperpods!(positions, a, b)
            end
        end
    end
    positions
end

function superpodePositions(grid)
    superpodePositions(grid, antenniFromGrid(grid))
end

testgrid = copy(testGrid)
superpodes = superpodePositions(testgrid)
testgrid[superpodes .& (testgrid.=='.')] .= '#'
println("Solution for test input: ", sum(superpodes))
printboard(testgrid)


puzzlegrid = copy(puzzleGrid)
superpodes = superpodePositions(puzzlegrid)
puzzlegrid[superpodes .& (puzzlegrid.=='.')] .= '#'
println("Solution for puzzle input: ", sum(superpodes))
printboard(puzzlegrid)

