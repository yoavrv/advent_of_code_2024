testInput = Int8[
    8 9 0 1 0 1 2 3
    7 8 1 2 1 8 7 4
    8 7 4 3 0 9 6 5
    9 6 5 4 9 8 7 4
    4 5 6 7 8 9 0 3
    3 2 0 1 9 0 1 2
    0 1 3 2 9 8 0 1
    1 0 4 5 6 7 3 2
]

function readToBlockMatrix(path)
    permutedims(reduce(hcat, [[parse(Int8,x) for x in line] for line in eachline(path, keep=false)]))
end
puzzleInput =  readToBlockMatrix(joinpath("day10", "puzzle_input10.txt"))

function caseDirection(case)
    if case == 0
        return CartesianIndex(1, 0)
    elseif case == 1
        return CartesianIndex(0, 1)
    elseif case == 2
        return CartesianIndex(-1, 0)
    else
        return CartesianIndex(0, -1)
    end
end

function printRun(shape, ij, nextPosition, level)
    board = zeros(shape)
    board[ij] = level
    board[nextPosition] = level+1
    for row in eachrow(board)
        println(row)
    end
end

function intLog2(i)
    j, l = 1, 0
    while j ≤ i
        j = j << 1
        l += 1
    end
    l
end

function depth_search(board, ij; verbose=false, maxIterations=2^9)
    """Depth first search from ij"""
    i = 0
    level = board[ij]
    level0 = level
    nines = []
    iterations = 0
    while level0 ≤ level && iterations ≤ maxIterations
        iterations += 1
        # we run 0-3 for each direction
        case = i&3
        nextPlace = ij + caseDirection(case)
        if verbose println("Running $i: $ij to $nextPlace, at level $level") end
        if verbose && checkbounds(Bool, board, nextPlace)
            printRun(size(board), ij, nextPlace, level)
        end
        if !checkbounds(Bool, board, nextPlace) || ((board[nextPlace]-board[ij]) != 1)
            # next place
            while case == 3
                # go down a level if went through all options in this one
                i = i >> 2 
                level -= 1
                case = i&3
                ij -= caseDirection(case)
            end
            i += 1
            continue
        else
            # go to the next place (up a level)
            if verbose print("Going up; ; ") end
            if level == 8
                # we got to a nine! we found what we want, we count and go back down
                if Tuple(nextPlace) ∉ nines
                    push!(nines, Tuple(nextPlace))
                    if verbose print("Found a nine!; $nines ; ") end
                end
                while case == 3
                    # go down a level if went through all options in this one
                    i = i >> 2 
                    level -= 1
                    case = i&3
                    ij -= caseDirection(case)
                end
                i += 1
                continue
            end
            # go up a level, starting at 0
            level += 1
            ij = nextPlace
            i = i << 2
        end
    end
    length(nines)
end



println("For testInput, #1 is: ",
    sum(
        depth_search(testInput, x, verbose=false)
        for x in findall(==(0), testInput)
    )
)

println("For puzzleInput, #1 is: ",
    sum(
        depth_search(puzzleInput, x, verbose=false)
        for x in findall(==(0), puzzleInput)
    )
)

function depth_search2(board, ij; verbose=false, maxIterations=2^9)
    """Depth first search from ij"""
    i = 0
    level = board[ij]
    level0 = level
    nines = 0
    iterations = 0
    while level0 ≤ level && iterations ≤ maxIterations
        iterations += 1
        # we run 0-3 for each direction
        case = i&3
        nextPlace = ij + caseDirection(case)
        if verbose println("Running $i: $ij to $nextPlace, at level $level") end
        if verbose && checkbounds(Bool, board, nextPlace)
            printRun(size(board), ij, nextPlace, level)
        end
        if !checkbounds(Bool, board, nextPlace) || ((board[nextPlace]-board[ij]) != 1)
            # next place
            while case == 3
                # go down a level if went through all options in this one
                i = i >> 2 
                level -= 1
                case = i&3
                ij -= caseDirection(case)
            end
            i += 1
            continue
        else
            # go to the next place (up a level)
            if verbose print("Going up; ; ") end
            if level == 8
                # we got to a nine! we found what we want, we count and go back down
                nines+=1
                if verbose print("Found a nine!; $nines ; ") end

                while case == 3
                    # go down a level if went through all options in this one
                    i = i >> 2 
                    level -= 1
                    case = i&3
                    ij -= caseDirection(case)
                end
                i += 1
                continue
            end
            # go up a level, starting at 0
            level += 1
            ij = nextPlace
            i = i << 2
        end
    end
    nines
end

println("For testInput, #2 is: ",
    sum(
        depth_search2(testInput, x, verbose=false)
        for x in findall(==(0), testInput)
    )
)

println("For puzzleInput, #2 is: ",
    sum(
        depth_search2(puzzleInput, x, verbose=false)
        for x in findall(==(0), puzzleInput)
    )
)
