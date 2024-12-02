# part 1


function linesafety(x::Vector)
    diffx = diff(x)
    closeenough = all((1 .≤ abs.(diffx) .≤ 3)) 
    samesign = all(sign.(diffx) .== sign(diffx[1]))
    samesign & closeenough
end

println("solution for test input: ",
sum(
    linesafety(parse.(Int32, split(line)))
    for line in eachline(joinpath("day2", "test_input.txt"))
    # The levels are either all increasing or all decreasing.
    # Any two adjacent levels differ by at least one and at most three.
)
)

println("puzzle solution 1: ",
sum(
    linesafety(parse.(Int32, split(line)))
    for line in eachline(joinpath("day2", "puzzle_input.txt"))
    # The levels are either all increasing or all decreasing.
    # Any two adjacent levels differ by at least one and at most three.
)
)

# part 2


function permissivesafety(v::Vector)
    if linesafety(v)
        return true
    end
    return any(linesafety([x for (i, x) in enumerate(v) if i!= j]) for j in 1:length(v))
end

println("solution 2 for test input: ",
sum(
    permissivesafety(parse.(Int32, split(line)))
    for line in eachline(joinpath("day2", "test_input.txt"))

)
)



println("puzzle solution 2: ",
sum(
    permissivesafety(parse.(Int32, split(line)))
    for line in eachline(joinpath("day2", "puzzle_input.txt"))
)
)
