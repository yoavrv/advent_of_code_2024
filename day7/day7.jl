# part 1


function parseline(line)
    solution, numbers = split(line, ':')
    numbers = parse.(Int64, split(numbers))
    solution = parse(Int64, solution)
    return solution, numbers
end


function isPossibleCompute(solution, numbers)
    if solution < numbers[1]
        return false
    end
    if length(numbers) == 1
        return solution == numbers[1]
    end
    # *
    if isPossibleCompute(solution, [numbers[1]*numbers[2] numbers[3:end]...]) return true end
    # +
    if isPossibleCompute(solution, [numbers[1]+numbers[2] numbers[3:end]...]) return true end
    return false
end


function lineValue(line)
    solution, numbers = parseline(line)
    if isPossibleCompute(solution, numbers)
        return solution
    end
    return 0
end

println("Solution for part 1 test input: ",
sum(
    lineValue(line)
    for line in eachline(joinpath("day7", "test_input7.txt"))
)
)


println("Solution for part 1 puzzle input: ",
sum(
    lineValue(line)
    for line in eachline(joinpath("day7", "puzzle_input7.txt"))
)
)

# part 2

function ⊙(x, y)
    """Concatenation operator: more finicky than I expected!"""
    y==0 ? 10x : x*nextpow(10, y+1) + y
end

function isPossibleCompute2(solution, numbers)
    if solution < numbers[1]
        return false
    end
    if length(numbers) == 1
        return solution == numbers[1]
    end
    # ||
    if isPossibleCompute2(solution, [numbers[1]⊙numbers[2] numbers[3:end]...]) return true end
    # *
    if isPossibleCompute2(solution, [numbers[1]*numbers[2] numbers[3:end]...]) return true end
    # +
    if isPossibleCompute2(solution, [numbers[1]+numbers[2] numbers[3:end]...]) return true end
    return false
end

function isPossibleComputeBrute(solution, numbers)
    for ops in Iterators.product(([+, *, ⊙] for _ in 1:length(numbers)-1)...)
        s = numbers[1]
        for (n, op) in zip(numbers[2:end], ops)
            s = op(s, n)
        end
        if s == solution
            return true
        end
    end
    return false
end


function isPossibleComputeVerbose(solution, numbers, ops="")
    if solution < numbers[1]
        return false, ops
    end
    if length(numbers) == 1
        return solution == numbers[1], ops
    end
    # ||
    poss, ops2 = isPossibleComputeVerbose(solution, [numbers[1]⊙numbers[2] numbers[3:end]...], ops*"⊙")
    if poss return true, ops2 end
    # *
    poss, ops2 = isPossibleComputeVerbose(solution, [numbers[1]*numbers[2] numbers[3:end]...], ops*"*")
    if poss return true, ops2 end
    # +
    poss, ops2 = isPossibleComputeVerbose(solution, [numbers[1]+numbers[2] numbers[3:end]...], ops*"+")
    if poss return true, ops2 end
    return false, ops
end

function parseReasoning(line)
    solution, numbers = parseline(line)
    possible, ops = isPossibleComputeVerbose(solution, numbers)
    if possible
        eline = string(numbers[1])
        for (n, op) in zip(numbers[2:end], ops)
            eline = "($(eline)) $(op) $(n)"
        end
        return true, eval(Meta.parse(eline)) == solution
    end
    return false, nothing
end



function lineValue2(line)
    solution, numbers = parseline(line)
    if isPossibleCompute2(solution, numbers)
        return solution
    end
    return 0
end


println("Solution for part 2 test input: ",
sum(
    lineValue2(line)
    for line in eachline(joinpath("day7", "test_input7.txt"))
)
)


println("Solution for part 2 puzzle input: ",
sum(
    lineValue2(line)
    for line in eachline(joinpath("day7", "puzzle_input7.txt"))
)
)
