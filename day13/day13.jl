using JuMP

using HiGHS

testInput = readlines(joinpath("day13", "test_input.txt"))

puzzleInput = readlines(joinpath("day13", "puzzle_input13.txt"))

struct ClawMachine
    a::Vector{Int64}
    b::Vector{Int64}
    prize::Vector{Int64}
end

function parseInput(inputString)
    clawMachines = []
    for (i, lines) in enumerate(Iterators.partition(inputString, 4))
        
        a, b, prize = lines[1:3]
        println("at $i")
        println(a)
        println(b)
        println(prize)
        a = parse.(Int64,match(r"X([+-]\d*),\sY([+-]\d*)",a))
        b = parse.(Int64,match(r"X([+-]\d*),\sY([+-]\d*)",b))
        prize = parse.(Int64,match(r"X=([+-]?\d*),\sY=([+-]?\d*)",prize))
        push!(clawMachines, ClawMachine(a, b, prize))
    end
    return clawMachines
end

testInputMachines = parseInput(testInput)

function besrMachineScore(machine::ClawMachine, cost=[3; 1])
    augmentedMatrix = [machine.a machine.b machine.prize]
    q, r = LinearAlgebra.qr(augmentedMatrix)
    # r is like the row-eschelon form in  Gaussian elimination:
    rzeros = isapprox.(0, r[end,end-1:end], atol=10^-8)
    if !rzeros[2] && rzeros[1]
        # unsolvable
        return nothing
    end
    if !rzeros[1]
        # one solution
        solution = r[:, 1:end-1] \ r[:, end]
        rsolution = round.(solution)
        if !(solution ≈ rsolution)
            return nothing
        end
        return rsolution ⋅ cost
    end
    # at least 1+ free variables
    nextLine = !isapprox.(0, r[end-1,end-2:end], atol=10^-8)
    if nextline[1] && nextline[2]
        # line solutions
        # reduce the last two variables to one
        if !nextline[1]
            # this is the free variable
        return rsolution ⋅ cost
        end
    end
    error("Dont know how to do 2 free variables")
end
