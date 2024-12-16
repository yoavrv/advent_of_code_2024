
testInput = """##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
"""

function parseInput(str)
    lines = split(str, "\n", keepempty=false)
    board = []
    boardEnd = 0
    for (i, line) in enumerate(lines)
        if !(0 < length(line) && '<' ∉ line && '>' ∉ line && 'v' ∉ line && '^' ∉ line)
            boardEnd = i
            break
        end
        push!(board, [x[1] for x in split(line,"", keepempty=false) if x ∉ ('\n', '\r')])
    end
    board = permutedims(reduce(hcat, board))

    moves = []
    for line in lines[boardEnd:end]
        append!(moves, [x[1] for x in split(line,"", keepempty=false) if x ∉ ('\n', '\r')])
    end
    return board, moves
end 

testBoard, testMoves = parseInput(testInput)
cursor = findfirst(==('@'), testBoard)

function sokobanMove!(board, cursor, move; verbose=false)
    negativeStep=false
    if move == 'v'
        δ = CartesianIndex(1, 0)
    elseif move == '>'
        δ = CartesianIndex(0, 1)
    elseif move == '<'
        δ = CartesianIndex(0, -1)
        negativeStep = true
    elseif move == '^'
        δ = CartesianIndex(-1, 0)
        negativeStep = true
    else
        error("Bad move $move")
    end
    if verbose println(δ) end
    nextPosition = cursor
    canMove = false
    while board[nextPosition] ∉ ('#', '.')
        nextPosition += δ
        if !checkbounds(Bool, board, nextPosition) || board[nextPosition] == '#'
            break
        elseif board[nextPosition] == '.'
            canMove = true
            break
        end
    end
    if negativeStep
        if verbose println(board[nextPosition:cursor]) end
    else
        if verbose println(board[cursor:nextPosition]) end
    end
    
    if canMove
        if negativeStep
            board[nextPosition:(cursor+δ)] = board[(nextPosition-δ):cursor]
        else
            board[(cursor+δ):nextPosition] = board[cursor:(nextPosition-δ)]
        end
        board[cursor] = '.'
        if verbose printBoard(board) end
        return cursor+δ
    end
    if verbose printBoard(board) end
    cursor
end

function printBoard(board)
    for line in eachrow(board)
        println(join(line))
    end
end


# test the sokoban game
board = copy(testBoard)
cursor = findfirst(==('@'), board)
cursor = sokobanMove!(board, cursor, '<', verbose=true)
cursor = sokobanMove!(board, cursor, '^', verbose=true)
cursor = sokobanMove!(board, cursor, 'v', verbose=true)
cursor = sokobanMove!(board, cursor, '>', verbose=true)

function solveSokoban(board, moves)
    board = copy(board)
    cursor = findfirst(==('@'), board)
    for move in moves
        cursor = sokobanMove!(board, cursor, move)
    end
    return board
end

function boxScore(board)
    s = 0
    for i in eachindex(IndexCartesian(), board)
        if board[i] != 'O'
            continue
        end
        s += (i[1]-1)*100 + (i[2]-1)
    end
    s
end


puzzleInput = replace(read(joinpath("day15", "puzzle_input15.txt"), String), "\r"=>"")
puzzleBoard, puzzleMove = parseInput(puzzleInput)
board = solveSokoban(puzzleBoard, puzzleMove)
println("Puzzle solution for part #1: ", boxScore(board))


# part 2

function widenBoard(board)
    newBoard = fill('.', size(board).*(1, 2))
    newBoard[:, 2:2:end] .= board
    replace!(newBoard, 'O'=>']', '@'=>'.')
    newBoard[:, 1:2:end] .= board
    replace!(newBoard, 'O'=>'[')
end


function sokobanMoveWide!(board, cursor, move; verbose=false)
    if move == '>'
        return sokobanMove!(board, cursor, move, verbose=verbose)
    elseif move == '<'
        return sokobanMove!(board, cursor, move, verbose=verbose)
    elseif move == 'v'
        δ = +1
        negativeStep = false
    elseif move == '^'
        δ = -1
        negativeStep = true
    else
        error("Bad move $move")
    end
    if verbose println(δ) end
     
    canMove = false
    # the only way I can see this working is by two-step:
    # sweep line-by-line to check we can move
    # sweep again to move the right blocks
    row = zeros(Bool, (1, size(board)[2]))
    curr_row = cursor[1]+δ
    if verbose maxDepth = curr_row end
    row[cursor[2]] = true
    left, right = cursor[2], cursor[2]
    slc = negativeStep ? (curr_row:δ:1) : (curr_row:δ:size(board)[1])
    if verbose println(slc) end
    if verbose println("$left $right $curr_row $(δ) $cursor") end
    for i=slc
        breakHere = false
        all_dots = true
        maxDepth = i
        for j = left:right
            if !row[j]
                continue
            end
            if board[i, j] == '#'
                canMove=false
                all_dots = false
                breakHere = true
                break
            elseif board[i, j] == '['
                all_dots = false
                right = max(j+1, right)
                row[j+1] = true
            elseif board[i, j] == ']'
                all_dots = false
                left = min(j-1, left)
                row[j-1] = true
            elseif board[i, j] == '.'
                row[j] = false
                if j==left left=left+1 end
                if j==right right=right-1 end
            end
        end
        if verbose println("$i: ", row) end
        if breakHere
            break
        end
        if all_dots 
            canMove=true
            break
        end
    end


    if negativeStep
        if verbose println(board[maxDepth:δ:cursor[1], left:right]) end
    else
        if verbose println(board[cursor[1]:δ:maxDepth, left:right]) end
    end
    if !canMove
        if verbose printBoard(board) end
        return cursor
    end
    
    # move
    row .= false
    curr_row = cursor[1]+δ
    row[cursor[2]] = true
    left, right = cursor[2], cursor[2]
    slc = negativeStep ? (curr_row:δ:maxDepth) : (curr_row:δ:maxDepth)
    if verbose println(slc) end
    if verbose println("$left $right $curr_row $(δ) $cursor") end
    rowMemory = copy(board[cursor[1], :])
    board[cursor] = '.'
    for i=slc
        all_dots = true
        if verbose println("$i"); println(board[i,:]);  println(row) end
        for j = left:right
            if !row[j]
                continue
            end
            if board[i, j] == '['
                all_dots = false
                right = max(j+1, right)
                if rowMemory[j] ∈ "@[]"
                    rowMemory[j], board[i, j] = board[i, j], rowMemory[j]
                else
                    rowMemory[j], board[i, j] = board[i, j], '.'
                end
                if !row[j+1]
                    rowMemory[j+1], board[i, j+1] = board[i, j+1], '.'
                end
                row[j+1] = true
            elseif board[i, j] == ']'
                all_dots = false
                left = min(j-1, left)
                if rowMemory[j] ∈ "@[]"
                    rowMemory[j], board[i, j] = board[i, j], rowMemory[j]
                else
                    rowMemory[j], board[i, j] = board[i, j], '.'
                end
                if !row[j-1]
                    rowMemory[j-1], board[i, j-1] = board[i, j-1], '.'
                end
                row[j-1] = true
            elseif board[i, j] == '.'
                if rowMemory[j] ∈ "@[]"
                    rowMemory[j], board[i, j] = board[i, j], rowMemory[j]
                end
                row[j] = false
            end
            
        end
        if verbose println("end") ; println(board[i,:]); println(row); println(rowMemory)  end
        if all_dots 
            break
        end
        if !row[left] left = left+1 end
        if !row[right] right = right-1 end
    end
    if verbose printBoard(board) end
    return cursor + CartesianIndex(δ, 0)

end

# test the sokoban game
board = copy(testBoard)
board = widenBoard(board)
cursor = findfirst(==('@'), board)
printBoard(board)
cursor = sokobanMoveWide!(board, cursor, '<', verbose=true)
cursor = sokobanMoveWide!(board, cursor, '^', verbose=true)
cursor = sokobanMoveWide!(board, cursor, 'v', verbose=true)
cursor = sokobanMoveWide!(board, cursor, '>', verbose=true)

function solveSokobanWide(board, moves)
    board = copy(board)
    cursor = findfirst(==('@'), board)
    for move in moves
        cursor = sokobanMoveWide!(board, cursor, move)
    end
    return board
end


function boxScoreWide(board)
    s = 0
    for i in eachindex(IndexCartesian(), board)
        if board[i] ∉ "O["
            continue
        end
        s += (i[1]-1)*100 + (i[2]-1)
    end
    s
end

board = copy(testBoard)
board = widenBoard(board)
cursor = findfirst(==('@'), board)

println("test solution for part #2: ", boxScoreWide(solveSokobanWide(board, testMoves)))

board = copy(puzzleBoard)
board = widenBoard(board)
cursor = findfirst(==('@'), board)

println("Puzzle solution for part #2: ", boxScoreWide(solveSokobanWide(board, puzzleMove)))

