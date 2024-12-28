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
        oldWay = nodes[node]
        if oldWay ≤ way return end
        nodes[node] = way
        enqueue!(queue, node => way + h(node))
    end

    if verbose println("We have $start->$goal, queue=$queue") end

    while !isempty(queue)
        node, heuristic = dequeue_pair!(queue)
        way = nodes[node]

        if node == goal
            if verbose println("Found goal!")
                 display(nodes)
            end
            return heuristic
        end
        
        for i in 1:4
            next = node+directions[i]
            if checkbounds(Bool, board, next) && !board[next]
                addToQueue!(queue, nodes, next, way+1)
            end
        end
        if verbose 
            println("Status after $node")
            println("$queue")
            display(nodes)
        end
    end
end





