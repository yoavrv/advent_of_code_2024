using DataStructures

function readToBlockMatrix(path)
    permutedims(reduce(hcat, [[x for x in line] for line in eachline(path, keep=false)]))
end

function stringToBlockMatrix(s)
    permutedims(reduce(hcat,[[y for y in x] for x in split(replace(s, "\r"=>""),'\n', keepempty=false)]))
end

testInput = """###############
#.......#....E#
#.#.###.#.###.#
#.....#.#...#.#
#.###.#####.#.#
#.#.#.......#.#
#.#.#####.###.#
#...........#.#
###.#.#####.#.#
#...#.....#.#.#
#.#.#.###.#.#.#
#.....#...#.#.#
#.###.#.#.#.#.#
#S..#.....#...#
###############
"""

testCourse = stringToBlockMatrix(testInput)

# we want to search through the matrix
struct SearchNode
    """direction: 00000000
                  LURDLURD
    4 bits represent facing (only one should be toggled): 1: south (1, 0), 2: east (0, 1), 4: north (-1, 0), 8: west (0, -1)
    4 bits represent available directions: 16: down, 32: right 64: up 128: left
    """
    position::CartesianIndex
    way::Int64
    direction::UInt8
end
function SearchNode(i, j, way, direction, facing)
    return SearchNode(CartesianIndex(i,j), way, (direction<<4) | facing)
end

function SearchNode(node::SearchNode, facing)
    return SearchNode(node.position, node.way, (node.direction&0b11110000) | (facing&0b1111))
end

function SearchNode(node::SearchNode, add, facing)
    return SearchNode(node.position, node.way + add, (node.direction&0b11110000) | (facing&0b1111))
end

function facingToIndex(direction)
    if     (direction&0b0001) != 0
        return CartesianIndex( 1,  0)
    elseif (direction&0b0010) != 0
        return CartesianIndex( 0,  1)
    elseif (direction&0b0100) != 0
        return CartesianIndex(-1,  0)
    elseif (direction&0b1000) != 0
        return CartesianIndex( 0, -1)
    else
        error("should not happen")
    end
end

function facingToAlternatives(facing)
    """Return left-opposite-right directions"""
    facing2 = facing&0b1111
    if facing2==0b0001
        return 0b0010, 0b0100, 0b1000
    elseif facing2==0b0010
        return 0b0100, 0b1000, 0b0001
    elseif facing2==0b0100
        return 0b1000, 0b0001, 0b0010
    elseif facing2==0b1000
        return 0b0001, 0b0010, 0b0100
    else
        error("should not happen")
    end
end

function heuristic(node::SearchNode, goal::CartesianIndex, stepCost=1, turnCost=1000, keepSearch=true; verbose=false)
    δ = goal - node.position
    if node.direction & 0b1111 == 0b0000
        if verbose println("fail") end
        return typemax(Int32)
    end
    face = facingToIndex(node.direction)
    if verbose println(δ, face) end
    if (node.direction & (node.direction >> 4))!=0
        # can go in the direction
        costLinear = stepCost*abs(δ[1])+stepCost*abs(δ[2])
        costTurn = turnCost*(δ[1]!=0 && δ[2]!=0)
        costDoubleturn = turnCost*(sign(δ[1])!=sign(face[1]) && sign(δ[2])!=sign(face[2]))
        if verbose println("direction: linear=$costLinear, turn=$costTurn, doubleTurn=$costDoubleturn") end
        return costLinear + costTurn + costDoubleturn
    end
    if keepSearch
        left, opposite, right = facingToAlternatives(node.direction)
        costLeft = heuristic(SearchNode(node, left), goal, stepCost, turnCost, false)
        costOpposite = heuristic(SearchNode(node, opposite), goal, stepCost, turnCost, false)
        costRight = heuristic(SearchNode(node, right), goal, stepCost, turnCost, false)
        if verbose println("left: $costLeft right: $costRight opposite: $costOpposite") end
        return turnCost + min(costLeft, costRight, costOpposite)
    end
    cost = typemax(Int32)
    if verbose println("failed: $cost") end
    return cost
end


function search(board, stepCost=1, turnCost=1000; verbose=false)
    goal = findfirst(==('E'), board)
    start = findfirst(==('S'), board)
    availableDirections = zeros(UInt8, size(board))
    availableDirections[2:end-1,:2:end-1] .|= 16*(board[3:end-0, 2:end-1] .!= '#')
    availableDirections[2:end-1,:2:end-1] .|= 32*(board[2:end-1, 3:end-0] .!= '#')
    availableDirections[2:end-1,:2:end-1] .|= 64*(board[1:end-2, 2:end-1] .!= '#')
    availableDirections[2:end-1,:2:end-1] .|= 128*(board[2:end-1, 1:end-2] .!= '#')
    startNode = SearchNode(start, 0, availableDirections[start] | 0b0010)
    function h(searchNode)
        return heuristic(searchNode, goal, stepCost, turnCost)
    end
    queue = PriorityQueue(startNode => h(startNode) )

    function addToQueue!(node)
        if isnothing(node) return end
        if count_ones(node.direction&0b0000) == 1 return end # dead end
        if node in keys(queue)
            queue[node] = min(node.way + h(node), queue[node])  # got back somewhere
        else 
            enqueue!(queue, node => node.way + h(node)) # new place
        end
    end

    if verbose println("We have $start->$goal, queue=$queue") end
    if verbose println.(eachrow(availableDirections)) end

    function findNextNodeCanGoForwards(position, left, right, facing, start)
        availableDirection = availableDirections[position]
        if availableDirection&facing == 0 # cant go forwards
            if verbose println("Can't go forwards $availableDirection & $facing") end
            return false
        elseif start
            if verbose println("start") end
            return true
        end
        if verbose println("finding junction $availableDirection & $left | $right") end
        return count_ones(availableDirection & (left|right)) == 0 # is a junction
    end

    function findNextNode(node)
        position = node.position
        i = facingToIndex(node.direction)
        # the board directions are in <<4 compare to the facing
        facing = node.direction <<4
        left, opposite, right = facingToAlternatives(node.direction) .<<4
        cost = node.way
        start = true
        while findNextNodeCanGoForwards(position, left, right, facing, start)
            position = position + i
            cost += stepCost
            start=false
        end
        if start return nothing end
        new_direction = availableDirections[position] | node.direction&0b1111
        return SearchNode(position, cost, new_direction)
    end

    while !isempty(queue)
        node, _ = dequeue_pair!(queue)
        if verbose println("$node") end
        if node.position == goal
            return node.way
        end
        left, _, right = facingToAlternatives(node.direction)
        node_direction_as_facing = node.direction >> 4
        if (node.direction & node_direction_as_facing) != 0
            new_node = findNextNode(node)
            if verbose println("direct $(node.direction) ahead $new_node") end
            addToQueue!(new_node)
        end
        if (left & node_direction_as_facing) != 0
            new_node = findNextNode(SearchNode(node, turnCost, left))
            if verbose println("left $left ahead $new_node") end
            addToQueue!(new_node)
        end
        if (right & node_direction_as_facing) != 0
            new_node = findNextNode(SearchNode(node, turnCost, right))
            if verbose println("right $right ahead $new_node") end
            addToQueue!(new_node)
        end
    end
    return nothing
end

println("Solution for test input #1: ", search(testCourse, verbose=false))

