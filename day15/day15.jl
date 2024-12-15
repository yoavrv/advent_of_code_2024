
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
