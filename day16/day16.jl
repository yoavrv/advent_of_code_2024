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

function heuristic(node::SearchNode, goal::CartesianIndex, stepCost=1, turnCost=1000)
    δ = goal - node.position
    if node.direction & 0b1111 == 0b0000
        return typemax(Int32)
    end
    face = facingToIndex(node.direction)
    costLinear = stepCost*abs(δ[1])+stepCost*abs(δ[2])
    costTurn = turnCost*(δ[1]!=0 && δ[2]!=0)
    costDoubleturn = turnCost*(sign(δ[1])!=sign(face[1]) && sign(δ[2])!=sign(face[2]))
    return costLinear + costTurn + costDoubleturn
end

function printBoard(board)
    for row in eachrow(board)
        println(join(row,""))
    end
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
            return false
        elseif start
            return true # start: go forward even in a junction
        end
        return count_ones(availableDirection & (left|right)) == 0 # is a junction
    end

    function findNextNode(node)
        position = node.position
        i = facingToIndex(node.direction)
        # the board directions are in <<4 compare to the facing
        facing = node.direction <<4
        left, _, right = facingToAlternatives(node.direction) .<<4
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
        if node.position == goal
            return node.way
        end
        left, _, right = facingToAlternatives(node.direction)
        node_direction_as_facing = node.direction >> 4
        if (node.direction & node_direction_as_facing) != 0
            new_node = findNextNode(node)
            addToQueue!(new_node)
        end
        if (left & node_direction_as_facing) != 0
            new_node = findNextNode(SearchNode(node, turnCost, left))
            addToQueue!(new_node)
        end
        if (right & node_direction_as_facing) != 0
            new_node = findNextNode(SearchNode(node, turnCost, right))
            addToQueue!(new_node)
        end
    end
    return nothing
end

println("Solution for test input #1: ", search(testCourse, verbose=false))

secondTestInput = """#################
#...#...#...#..E#
#.#.#.#.#.#.#.#.#
#.#.#.#...#...#.#
#.#.#.#.###.#.#.#
#...#.#.#.....#.#
#.#.#.#.#.#####.#
#.#...#.#.#.....#
#.#.#####.#.###.#
#.#.#.......#...#
#.#.###.#####.###
#.#.#...#.....#.#
#.#.#.#####.###.#
#.#.#.........#.#
#.#.#.#########.#
#S#.............#
#################
"""

println("Solution for test input 2 #1: ", search(stringToBlockMatrix(secondTestInput), verbose=false))

puzzleInput = readToBlockMatrix(joinpath("day16","puzzle_input16.txt"))
println("Solution for puzzle input #1: ", search(puzzleInput, verbose=false))

# part 2

# I was planning on doing something better, but I'm out of patience


function SearchNodeMem(node::SearchNode)
    return SearchNode(node.position, 0, node.direction)
end

mutable struct SearchThing
    past::Vector{SearchNode}
    way::Int64
    index::Int64
end

function SearchThing(i)
    return SearchThing([], 0, i)
end

function findPositionInTree(tree, position)
    [n for n in keys(tree)
        if n.position == position]
end


function searchPaths(board, stepCost=1, turnCost=1000; verbose=false)
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
    queue = PriorityQueue(startNode => h(startNode))

    treeIndex = 0
    function nextSearchThing!()
        st = SearchThing(treeIndex)
        treeIndex += 1
        return st
    end
    nodesTree = DefaultDict{SearchNode, SearchThing}(nextSearchThing!)

    function addToQueue!(node, previousNode)
        if isnothing(node) return end
        if count_ones(node.direction&0b0000) == 1 return end # dead end

        lookup = SearchNodeMem(node)
        if lookup in keys(nodesTree)
            if node.way < nodesTree[lookup].way
                if node in keys(queue)
                    queue[node] = new_priority  # got back somewhere with lower score
                else
                    new_priority = node.way + h(node)
                    enqueue!(queue, node => new_priority)
                end
                empty!(nodesTree[lookup].past)
                push!(nodesTree[lookup].past, previousNode)
                nodesTree[lookup].way = node.way
            elseif nodesTree[lookup].way < node.way
                return
            else
                push!(nodesTree[lookup].past, previousNode)
            end
        else 
            new_priority = node.way + h(node)
            enqueue!(queue,node => new_priority) # new place
            push!(nodesTree[lookup].past, previousNode)
            nodesTree[lookup].way = node.way
        end
    end

    if verbose println("We have $start->$goal, queue=$queue") end
    if verbose println.(eachrow(availableDirections)) end

    function findNextNodeCanGoForwards(position, left, right, facing, start)
        availableDirection = availableDirections[position]
        if availableDirection&facing == 0 # cant go forwards
            return false
        elseif start
            return true # start: go forward even in a junction
        end
        return count_ones(availableDirection & (left|right)) == 0 # is a junction
    end

    function findNextNode(node)
        position = node.position
        i = facingToIndex(node.direction)
        # the board directions are in <<4 compare to the facing
        facing = node.direction <<4
        left, _, right = facingToAlternatives(node.direction) .<<4
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

    min_path = nothing
    nodesTree[SearchNodeMem(startNode)]
    finalPaths = []
    while !isempty(queue)
        node, heuristic = dequeue_pair!(queue)
        if !isnothing(min_path )
            if min_path < heuristic
                continue
            end
        end
        if node.position == goal
            if isnothing(min_path)
                min_path = node.way
                push!(finalPaths, node)
            elseif min_path == node.way
                push!(finalPaths, node)
            elseif node.way < min_path
                println("Error! shouldn't happen!")
            end
            continue
        end
        left, _, right = facingToAlternatives(node.direction)
        node_direction_as_facing = node.direction >> 4
        if (node.direction & node_direction_as_facing) != 0
            new_node = findNextNode(node)
            addToQueue!(new_node, node)
        end
        if (left & node_direction_as_facing) != 0
            new_node = findNextNode(SearchNode(node, turnCost, left))
            addToQueue!(new_node, node)
        end
        if (right & node_direction_as_facing) != 0
            new_node = findNextNode(SearchNode(node, turnCost, right))
            addToQueue!(new_node, node)
        end
    end
    return nodesTree, finalPaths
end


tree, finalNodes = searchPaths(testCourse, verbose=false)

function getFinalBoard(board, tree, finalNodes)
    junctionNodes = Set{SearchNode}()
    passedNodes = Set{SearchNode}()
    for node in finalNodes
        nodes = [node]
        while !isempty(nodes)
            n = pop!(nodes)
            if n ∉ junctionNodes
                push!(junctionNodes, n)
                for p in tree[SearchNodeMem(n)].past
                    a, b = sort([n.position, p.position])
                    push!(passedNodes, SearchNode.(a:b, 0, 0)...)
                end
                push!(nodes, tree[SearchNodeMem(n)].past...)
            end
        end
    end
    t2 = copy(board)
    for n in passedNodes t2[n.position] = 'O' end
    return t2
end

newBoard = getFinalBoard(testCourse, tree, finalNodes)
printBoard(newBoard)

function d2i(d)
    return (d&1 != 0) ? 1 : (d&2 != 0) ? 2 : (d&4 != 0) ? 3 : 4
end

t2 = Matrix{Any}(testCourse)
t2[t2.!='#'] .= "        "
t2[t2.=='#'] .= "########"
for (n, st) in pairs(tree) 
    d = 2*d2i(n.direction)-2
    s = t2[n.position]
    ns = (s[1:d] * lpad("$(st.index)", 2) * s[d+3:end])
    t2[n.position] = ns
end
printBoard(t2)

println("Solution for test input #1: ", sum(newBoard.=='O'))


testCourse2 = stringToBlockMatrix(secondTestInput)
tree, finalNodes = searchPaths(testCourse2, verbose=false)

newBoard = getFinalBoard(testCourse2, tree, finalNodes)
printBoard(newBoard)

t2 = Matrix{Any}(testCourse2)
t2[t2.!='#'] .= "        "
t2[t2.=='#'] .= "########"
for (n, st) in pairs(tree) 
    d = 2*d2i(n.direction)-2
    s = t2[n.position]
    ns = (s[1:d] * lpad("$(st.index)", 2) * s[d+3:end])
    t2[n.position] = ns
end
printBoard(t2)

println("Solution for test input #2: ", sum(newBoard.=='O'))

tree, finalNodes = searchPaths(puzzleInput, verbose=false)

newBoard = getFinalBoard(puzzleInput, tree, finalNodes)

println("Solution for puzzle input #2: ", sum(newBoard.=='O'))

