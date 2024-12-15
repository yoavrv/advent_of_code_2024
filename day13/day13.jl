using JuMP

using HiGHS

using GLPK

using LinearAlgebra

testInput = readlines(joinpath("day13", "test_input.txt"))

puzzleInput = readlines(joinpath("day13", "puzzle_input13.txt"))

struct ClawMachine
    """Claw machine: 
    
    buttons(ClawMachine) to get the buttons and prize(ClawMachine) to get the prize, cost(c) to get the cost"""
    matrix::Matrix{Int64}
end

function buttons(c::ClawMachine) c.matrix[1:end-1, 1:end-1] end
function prize(c::ClawMachine) c.matrix[1:end-1, end] end
function cost(c::ClawMachine) c.matrix[end, 1:end-1] end
function cost(c::ClawMachine, x) c.matrix[end, 1:end-1] ⋅ x end


function parseInput(inputString)
    clawMachines = []
    for (i, lines) in enumerate(Iterators.partition(inputString, 4))
        
        a, b, prize = lines[1:3]
        a = parse.(Int64,match(r"X([+-]\d*),\sY([+-]\d*)",a))
        b = parse.(Int64,match(r"X([+-]\d*),\sY([+-]\d*)",b))
        prize = parse.(Int64,match(r"X=([+-]?\d*),\sY=([+-]?\d*)",prize))
        push!(clawMachines, ClawMachine([a b prize 
                                         3 1 0]))
    end
    return clawMachines
end

testInputMachines = parseInput(testInput)
puzzleMachines = parseInput(puzzleInput)

function bestMachineScore(machine::ClawMachine; verbose=false)
    model = Model(GLPK.Optimizer)
    if !verbose set_silent(model) end
    bs = buttons(machine)
    p = prize(machine)
    c = cost(machine)
    nb, nx = size(bs)
    @variable(model, x[1:nb]≥0, Int)
    @constraint(model, con_vector, bs*x == p)
    @objective(model, Min, c ⋅ x)
    optimize!(model)
    if !is_solved_and_feasible(model)
        return Int64(0)
    end
    Int64(objective_value(model))
end

function modelMachineScore(machine::ClawMachine; verbose=false)
    model = Model(HiGHS.Optimizer)
    if !verbose set_silent(model) end
    bs = buttons(machine)
    p = prize(machine)
    c = cost(machine)
    nb, nx = size(bs)
    @variable(model, x[1:nb]≥0, Int)
    @constraint(model, con_vector,bs*x == p)
    @objective(model, Min, c ⋅ x)
    optimize!(model)
    if !is_solved_and_feasible(model)
        return model, Int64(0)
    end
    model, x
end


println("For test input #1, sum is: ", sum(bestMachineScore.(testInputMachines)))

println("For puzzle input #1, sum is: ", sum(bestMachineScore.(puzzleMachines)))

# part 2

function calibrateMachines(machines)
    clawMachines = []
    for machine in machines
        push!(clawMachines, ClawMachine([buttons(machine)  (prize(machine).+10_000_000_000_000)
                                         [cost(machine) ; 0]']))
    end
    return clawMachines
end

testInputMachines2 = calibrateMachines(testInputMachines)
puzzleMachines2 = calibrateMachines(puzzleMachines)

println("For test input #2, sum is: ", sum(bestMachineScore.(testInputMachines2)))

println("For puzzle input #2, sum is: ", sum(bestMachineScore.(puzzleMachines2)))

function bestMachineScoreNaive(machine::ClawMachine; verbose=false)
    p = prize(machine)
    bs = buttons(machine)
    ax, bx = bs[1,1], bs[1, 2]
    ay, by = bs[2,1], bs[2, 2]
    px, py = p
    c = cost(machine)
    mA, mB, mP =ax//ay, bx//by, px//py
    if (mA < mP && mB < mP) || (mP < mA && mP < mB) return 0 end # unsolvable
    if mA != mB
        # solvable system (potentially)
        # determinent
        adbc = bs[1, 1]*bs[2,2] - bs[1, 2]*bs[2, 1]
        if adbc == 0 return 0 end
        # 2x2 matrix solution
        x = (bs[2, 2]*p[1] - bs[1, 2]*p[2])÷adbc
        y = (-bs[2, 1]*p[1] + bs[1, 1]*p[2])÷adbc
        # test the integerification works
        if bs*[x;y] == p
            return 3x + y
        else
            return 0
        end
    end
    # line solve
    if ax == 0 && bx == 0
        # switch y and x
        px, py = py, px
        ax, bx = ay, by
    end
    if 3*bx < ax
        x1, x2 = ax, bx # A is cheaper per distance
        c1, c2 = c
    else
        x1, x2 = bx, ax # B is cheaper: switch roles
        c1, c2 = c[end:-1:1]
    end
    m, n = px÷x1 + 1, 0
    nMax = px÷x2 + 1
    curr = m*x1 + n*x2
    while (curr!=px) && (0 ≤ m) && (n≤nMax)
        if curr < px
            n += 1
        else
            m -= 1
        end
        curr = m*x1 + n*x2
    end
    if curr==px return m*c1 + n*c2 end
    return 0    
end

println("For test input #1, naive method sum is: ", sum(bestMachineScoreNaive.(testInputMachines)))
println("For puzzle input #1, naive sum is: ", sum(bestMachineScoreNaive.(puzzleMachines)))

println("For puzzle input #2, naive sum is: ", sum(bestMachineScoreNaive.(puzzleMachines2)))
