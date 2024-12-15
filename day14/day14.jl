# part 1

testInput = """p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3
"""

testBoardSize = (7, 11)

function parseRobot(line)
    parse.(Int64, match(r"p=(-?\d*),(-?\d*) v=(-?\d*),(-?\d*)", line))[[2, 1, 4, 3]]
end

function parseRobots(str)
    [
        parseRobot(line)
        for line in split(str, "\n", keepempty=false)
    ]
end

testRobots = parseRobots(testInput)

puzzleInput = readlines(joinpath("day14","puzzle_input14.txt"))

puzzleRobots = parseRobot.(puzzleInput)

puzzleBoardSize = (103, 101)

function printRobot(robot, boardSize)
    for i=0:boardSize[1]-1
        for j=0:boardSize[2]-1
            if all(robot .== [i, j])
                print('#')
            else print('.') end
        end
        print('\n')
    end
end

function robotsBoard(robots, boardSize)
    board = zeros(Int64, boardSize)
    for robot in robots
        board[robot[1]+1, robot[2]+1] += 1
    end
    board
end

function robotFuture(robot, timesteps, boardSize)
    [mod.((robot[1:2] + timesteps.*robot[3:4]), boardSize)' robot[3:4]']
end

function robotFutures(robots, timesteps, boardSize)
    [robotFuture(robot, timesteps, boardSize) for robot in robots]
end

function robotFutureBoard(robots, timesteps, boardSize)
    robotsBoard(robotFutures(robots, timesteps .% boardSize, boardSize), boardSize)
end

function countQuadrant(robots, timesteps, boardSize)
    board = robotFutureBoard(robots, timesteps, boardSize)
    l, w = boardSize .÷  2
    [sum(board[1:l, 1:w]) sum(board[1:l, w+2:end])
     sum(board[l+2:end, 1:w]) sum(board[l+2:end, w+2:end])]
end

quadrants = countQuadrant(testRobots, 100, testBoardSize)

println("Safety factor for test input: ", prod(countQuadrant(testRobots, 100, testBoardSize)))

println("Safety factor for puzzle input: ", prod(countQuadrant(puzzleRobots, 100, puzzleBoardSize)))


# part 2
# What the heck count as a christmas tree pattern???

function likeChristmasTree(board)
    nothing
end