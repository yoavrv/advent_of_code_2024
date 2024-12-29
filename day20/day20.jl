using DataStructures

function readToBlockMatrix(path)
    permutedims(reduce(hcat, [[x for x in line] for line in eachline(path, keep=false)]))
end

function stringToBlockMatrix(s)
    permutedims(reduce(hcat,[[y for y in x] for x in split(replace(s, "\r"=>""),'\n', keepempty=false)]))
end

testInput = """###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############
"""

testBoard = stringToBlockMatrix(testInput)
start = findfirst(==('S'), testBoard)
goal = findfirst(==('E'), testBoard)
testBoard = testBoard .== '#'

function fillBoard(board, start; verbose=false)
    directions = [CartesianIndex(0, -1), CartesianIndex(-1, 0), CartesianIndex(0, 1), CartesianIndex(1, 0)]
    nodes = fill(length(board), size(board)...) # way took to get to the point

    queue = PriorityQueue(start => 0)

    function addToQueue!(queue, nodes, node, way)
        oldWay = nodes[node]
        if oldWay ≤ way return end
        nodes[node] = way
        if node in keys(queue)
            queue[node] = way
            return
        end
        if node == goal return end
        enqueue!(queue, node => way)
    end

    if verbose println("We have $start->$goal, queue=$queue") end

    while !isempty(queue)
        node, way = dequeue_pair!(queue)
        
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
    return nodes
end


startDistance = fillBoard(testBoard, start)
endDistance = fillBoard(testBoard, goal)
@assert startDistance[goal] == endDistance[start]

# for every point along the optimal path, startDistance[x] + endDIstance[x]
# equals the total path from start to end
#
#   starting distance    goal distance
#   # # # # # #          # # # # # #
#   # 0 1 2 # #          # 4 3 2 # #
#   # # # 3 4 #          # # # 1 0 #
#   # # # # # #          # # # # # #
#
# A shortcut is essentially removing a barrier
#   starting distance   goal distance
#
#   # 36 # 5 #          # 12 # 24 #
#   # 37 # 6 #          # 11 # 23 #
#   # 38 = 7 #          # 10 = 22 #
#   # 39 # 8 #          #  9 # 21 #
#
# So from = we can get to the start with 1 + min(7, 38), and to the end with 1 + min(10, 22), so you have
# a distance of 19. The original distance was (5+24) = 29, so we saved 10 steps

directions = [CartesianIndex(1, 0), CartesianIndex(-1, 0), CartesianIndex(0, 1), CartesianIndex(0, -1)]
function cheatDistance(startDistance, endDistance, cheatPosition)
    """Assume cheat position is within [2:end-1, 2:end-1]"""
    return 2 + minimum([startDistance[cheatPosition+d] for d in directions]) + minimum([endDistance[cheatPosition+d] for d in directions])
end

function solvePart1(input, minAdvantage=100; verbose=false)
    board = stringToBlockMatrix(input)
    start = findfirst(==('S'), board)
    goal = findfirst(==('E'), board)
    board = board .== '#'
    startDistance = fillBoard(board, start)
    endDistance = fillBoard(board, goal)

    L, W = size(board)
    way = endDistance[start]

    n = 0
    for i in 2:L-1
        for j in 2:W-1
            if !board[i, j]
                continue
            end
            cheat = cheatDistance(startDistance, endDistance, CartesianIndex(i, j))
            if minAdvantage ≤ (way - cheat)
                if verbose
                    println("At ($i, $j): $cheat")
                end
                n += 1
            end
        end
    end
    return n
end


println("Solution test input for part 1: ", solvePart1(testInput, verbose=true))

