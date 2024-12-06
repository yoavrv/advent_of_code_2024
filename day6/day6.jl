# part 1
testInput = """....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...
"""

testInput = permutedims(reduce(hcat,[[y for y in x] for x in split(testInput,'\n', keepempty=false)]))
puzzleInput = permutedims(reduce(hcat, [[x for x in line] for line in eachline(joinpath("day6", "puzzle_input6.txt"))]))

function stringBlockToMatrix(s)
    permutedims(reduce(hcat,[[y for y in x] for x in split(s,'\n', keepempty=false)]))
end

function printboard(input)
    for row in eachrow(input)
        println(String(row))
    end
end

input = copy(testInput)

directions = Dict(:up => CartesianIndex(-1, 0), :down => CartesianIndex(1, 0),
                 :left => CartesianIndex(0, -1), :right => CartesianIndex(0, 1))
directionChar = Dict(:up => '^', :down => 'v', :left => '<', :right => '>')                 
nextDirection = Dict(:up => :right, :right => :down, :down => :left, :left => :up)

function solveBoard(board; maxIterations=10_000, verbose=false)
    board = copy(board)
    cursorIndex = findfirst(board.=='^')
    curDirection = :up
    iterations=1
    while iterations ≤ maxIterations
        if verbose println("iteration $iterations") end
        iterations += 1
        if verbose printboard(board) end
        next = cursorIndex + directions[curDirection]
        if !checkbounds(Bool, board, next)
            break
        end
        if board[next] == '#'
            curDirection = nextDirection[curDirection]
            board[cursorIndex] = directionChar[curDirection]
        else
            board[cursorIndex] = 'X'
            cursorIndex = next
            board[cursorIndex] = directionChar[curDirection]
        end
    end
    if verbose
    println("final")
    printboard(board)
    end
    board
end

println("Number of Xs in test input: ", sum(solveBoard(testInput).=='X') + 1)
println("Number of Xs in puzzle input: ", sum(solveBoard(puzzleInput).=='X') + 1)

# part 2
# We can record the direction with a number
# passes = 0000
#          UDLR
# and terminate on encountering the same direction for a loop i.e (curDirectionCode & passes) != 0

# and we can get the "possible" obstruction from the previous solution

codes = Dict(
    :up => 0b001000, :down => 0b000100, :left => 0b000010, :right => 0b000001,
    :obstacle => 0b010000, :here => 0b10_0000
)
code2symbol = Dict(value => key for (key, value) in codes)

utfcodes = begin
    up, down, left, right = codes[:up], codes[:down], codes[:left], codes[:right]
    directionDict = Dict(
        up => '↑', down => '↓', right => '→',left => '←',
        up|down => '│', up|left => '┘', up|right => '└',
        down|right => '┌', down|left => '┐', left|right => '─',
        up|down|right => '├', down|right|left => '┬', right|left|up => '┴', left|up|down => '┤',
        up|down|right|left => '┼',
    )
    directionDict = Dict(directionDict ∪ Dict(key | codes[:here] => '⊗' for (key, value) in directionDict))
    directionDict[codes[:here]] = '⊗'
    directionDict[codes[:obstacle]] = '#'
    directionDict[0] = '.'
    directionDict
end

function printCodedBoard(board)
    for row in eachrow(board)
        println(replace(row, utfcodes...)...)
    end
end

function boardToCodes(board)
    replace(board, Dict{Char, Int8}('.' => 0, '^'  => codes[:up] | codes[:here], '#'  => codes[:obstacle])...)
end


function solveBoard2(board; cursorIndex=nothing, curDirection=nothing, iterations=0, maxIterations=10_000, verbose=false)
    state = 1 
    if isnothing(cursorIndex)
        cursorIndex = findfirst( (board .& codes[:here]).!=0)
    end
    if isnothing(curDirection)
        curDirection = code2symbol[board[cursorIndex] & ~codes[:here]]
    end
    while iterations ≤ maxIterations
        iterations += 1
        next = cursorIndex + directions[curDirection]
        if !checkbounds(Bool, board, next)
            state = 2  # exit board
            break
        end
        if (board[next] & codes[curDirection])!= 0
            state = 3  # loop!
            break
        end
        if (board[next] & codes[:obstacle])!=0
            if verbose println("iteration $iterations: turning") end
            if verbose printCodedBoard(board) end
            curDirection = nextDirection[curDirection]
            board[cursorIndex] |= codes[curDirection]
        else
            board[cursorIndex] |= codes[curDirection]
            board[cursorIndex] &= ~codes[:here]
            cursorIndex = next
            board[cursorIndex] |= codes[curDirection] | codes[:here]
        end
    end
    if verbose
        println("iteration $iterations: ",
                ["Pass max iteration $maxIterations", "Exited board", "Looped"][state])
        printCodedBoard(board)
    end
    board, state
end



function solveBoardObstacles(board; maxIterations=10_000, verbose=false)
    state = 1
    loopers = 0
    cursorIndex = findfirst( (board .& codes[:here]).!=0)
    curDirection = code2symbol[board[cursorIndex] & ~codes[:here]]
    iterations=0
    while iterations ≤ maxIterations
        iterations += 1
        next = cursorIndex + directions[curDirection]
        if !checkbounds(Bool, board, next)
            state = 2  # exit board
            break
        end
        if (board[next] & codes[curDirection])!= 0
            state = 3  # loop!
            break
        end
        if (board[next] & codes[:obstacle])!=0
            if verbose println("iteration $iterations: turning") end
            if verbose printCodedBoard(board) end
            curDirection = nextDirection[curDirection]
            board[cursorIndex] |= codes[curDirection]
        else
            # could go forward
            if board[next] == 0
                # check what would happen if we blocked this block
                blockedBoard = copy(board)
                blockedBoard[next] = codes[:obstacle]
                tryboard, trystate = solveBoard2(blockedBoard, cursorIndex=cursorIndex, curDirection=curDirection, iterations=iterations)
                if trystate == 3
                    if verbose println("Blocked $next will loop") end
                    if verbose printCodedBoard(tryboard) end
                    loopers += 1
                elseif trystate == 2
                    if verbose println("Blocked $next will exit") end
                    if verbose printCodedBoard(tryboard) end
                end
            end
            board[cursorIndex] |= codes[curDirection]
            board[cursorIndex] &= ~codes[:here]
            cursorIndex = next
            board[cursorIndex] |= codes[curDirection] | codes[:here]
        end
    end
    if verbose
        println("iteration $iterations: ",
                ["Pass max iteration $maxIterations", "Exited board", "Looped"][state])
        printCodedBoard(board)
    end
    board, state, loopers
end

# board2[end-1, 4] = '#'
board = Matrix{Int8}(boardToCodes(copy(testInput)))
board, state, loopers = solveBoardObstacles(board, verbose=true)
println("for test input, we have $loopers looping blocks")

board = Matrix{Int8}(boardToCodes(copy(puzzleInput)))
board, state, loopers = solveBoardObstacles(board, verbose=false)
println("for puzzle input, we have $loopers looping blocks")
