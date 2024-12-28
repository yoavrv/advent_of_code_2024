using DelimitedFiles 
using DataStructures

testMemory = [
    5 4
    4 2
    4 5
    3 0
    2 1
    6 3
    2 4
    1 5
    0 6
    3 3
    2 6
    5 1
    1 2
    5 5
    2 5
    6 5
    1 4
    0 4
    6 4
    1 1
    6 1
    1 0
    0 5
    1 6
    2 0
]

mem = zeros(Bool, 7, 7)

for (j, i) in eachrow(testMemory)[1:12]
    mem[i+1, j+1] = true
end

mem

function printBoard(mem)
    for row in eachrow(mem)
        println(join(x ? '#' : '.' for x in row))
    end
end


puzzleInput = readdlm(joinpath("day18","puzzle_input18.txt"),',', Int64)

function fillBoard(input, size, upto=nothing)
    mem = zeros(Bool, size...)
    if isnothing(upto)
        viewInput = view(input, :, :)
    else
        viewInput = view(input, 1:upto, :)
    end
    for (j, i) in eachrow(viewInput)
        mem[i+1, j+1] = true
    end
    return mem
end

# time to A*
# but this one is much simpler, since we dont have any turning nonesense

function fillDeadEnds(board; verbose=false)
    board = copy(board)

    numBlockers = zeros(Int8, size(board))

    numBlockers[:, end] .+= 1
    numBlockers[:, 1] .+= 1
    numBlockers[1, :] .+= 1
    numBlockers[end, :] .+= 1
    numBlockers[:, 1:end-1] += board[:, 2:end] # right block
    numBlockers[1:end-1, :] += board[2:end, :] # down block
    numBlockers[:, 2:end] += board[:, 1:end-1] # left block
    numBlockers[2:end, :] += board[1:end-1, :] # up block

    deadEnds = numBlockers.==3
    oldDeadEnds = zeros(Bool, size(board))
    if verbose printBoard(deadEnds) end
    while deadEnds != oldDeadEnds
        if verbose printBoard(deadEnds) end
        oldDeadEnds = deadEnds
        board[deadEnds] .= true
        # don't block the start and end!
        board[1, 1] = false
        board[end, end] = false
        if verbose printBoard(board) end
        numBlockers = zeros(Int8, size(board))
        
        numBlockers[:, end] .+= 1
        numBlockers[:, 1] .+= 1
        numBlockers[1, :] .+= 1
        numBlockers[end, :] .+= 1
        numBlockers[:, 1:end-1] += board[:, 2:end] # right block
        numBlockers[1:end-1, :] += board[2:end, :] # down block
        numBlockers[:, 2:end] += board[:, 1:end-1] # left block
        numBlockers[2:end, :] += board[1:end-1, :] # up block

        deadEnds = 3 .≤ numBlockers
    end
    if verbose println("Finished filling dead ends") end
    if verbose printBoard(board) end
    return board
end

function searchPath(board; verbose=false)
    goal = CartesianIndex(size(board))
    start = CartesianIndex(1,1)
    board = fillDeadEnds(board, verbose=verbose)

    directions = [CartesianIndex(0, -1), CartesianIndex(-1, 0), CartesianIndex(0, 1), CartesianIndex(1, 0)]
    junctions = zeros(Int8, size(board))

    nboard = .! board
    junctions[2:end-1, 2:end-1] += ((nboard[2:end-1, 3:end] .| nboard[2:end-1, 1:end-2]) 
                                 .& (nboard[1:end-2, 2:end-1] .|  nboard[3:end, 2:end-1]))
    junctions[1, 2:end-1] += (nboard[1, 3:end] .| nboard[1, 1:end-2]) .& nboard[2, 2:end-1]
    junctions[end, 2:end-1] += (nboard[end, 3:end] .| nboard[end, 1:end-2]) .& nboard[end-1, 2:end-1]
    junctions[2:end-1, 1] += nboard[2:end-1, 2] .& (nboard[1:end-2, 1] .|  nboard[3:end, 1])
    junctions[2:end-1, end] += nboard[2:end-1, end-1] .& (nboard[1:end-2, end] .|  nboard[3:end, end])
    junctions[1, 1] += true
    junctions[1, end] += true
    junctions[end, 1] += true
    junctions[end, end] += true
    junctions = min.(1, junctions)
    junctions[board] .= 2

    if verbose println.(eachrow(junctions)) end

    nexts = zeros(Int16, size(board)..., 4)  # next open place right up left down
    accumulate!((x, y) -> y==2 ? -1 : y==1 ? 0 : x+1, (@view nexts[:, :, 1]), junctions, dims=2, init=-1)
    accumulate!((x, y) -> y==2 ? -1 : y==1 ? 0 : x+1, (@view nexts[:, :, 2]), junctions, dims=1, init=-1)
    accumulate!((x, y) -> y==2 ? -1 : y==1 ? 0 : x+1, (@view nexts[:, end:-1:1, 3]), junctions[:, end:-1:1], dims=2, init=-1)
    accumulate!((x, y) -> y==2 ? -1 : y==1 ? 0 : x+1, (@view nexts[end:-1:1, :, 4]), junctions[end:-1:1, :], dims=1, init=-1)


    L, W = size(board)
    function h(i, j)
        return L-i + W-j
    end
    function h(c::CartesianIndex)
        return h(c[1], c[2])
    end

    nodes = fill(Int16(32767), size(board)...) # way took to get to the point
    startNode = CartesianIndex(1, 1)
    nodes[startNode] = 0

    queue = PriorityQueue( startNode => 0 + h(startNode))

    function addToQueue!(queue, nodes, node, way)
        if isnothing(node) return false end
        oldWay = nodes[node]
        if oldWay ≤ way
            return false
        end
        nodes[node] = way
        enqueue!(queue, node => way + h(node))
        return true
    end

    if verbose println("We have $start->$goal, queue=$queue") end
    if verbose 
        for i in 1:4 
            println("Nexts $i")
            println.(eachrow([Int64(x) for x in nexts[:, :, i]])) 
        end
    end

    while !isempty(queue)
        node, heuristic = dequeue_pair!(queue)
        way = nodes[node]

        if node == goal
            if verbose println("Found goal!")
                 println.(eachrow(nodes)) end
            return heuristic
        end
        
        for i in 1:4
            δ = nexts[node, i]
            if δ == 0
                continue
            end
            n = node
            for d in 1:δ-1
                n += directions[i]
                nodes[n] = min(nodes[n], way + d)
            end
            addToQueue!(queue, nodes, node+directions[i], way+δ)
        end
        println("Status after $node")
        println("$queue")
        if verbose println.(eachrow([Int64(x) for x in nodes])) end
    end
end





