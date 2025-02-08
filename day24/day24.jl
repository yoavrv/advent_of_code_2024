testInput = read(joinpath("day24","test_input24.txt"), String)
puzzleInput = read(joinpath("day24","puzzle_input24.txt"), String)

function parseInput(s)
    starts = []
    rules = []
    for line in split(replace(s, "\r"=> ""), "\n", keepempty=false)
        if ':' in line
            push!(starts, parseStart(line))
        elseif '>' in line
            push!(rules, parseRule(line))
        end
    end
    return starts, rules
end

function parseStart(line)
    x, b = split(line, ": ")
    return x, b == "1"
end

@enum GateOp begin
    AND
    OR
    XOR
end

function runOp(a::Bool, b::Bool, op::GateOp)
    if op == AND
        return a & b
    elseif op == OR
        return a | b
    elseif op == XOR
        return a ⊻ b
    end
    error("Invalid operator $op")
end

struct Rule
    inA::String
    inB::String
    op::GateOp
    out::String
end

function Rule(inA, inB, op::AbstractString, out)
    if op == "AND"
        return Rule(inA, inB, AND, out)
    elseif op == "OR"
        return Rule(inA, inB, OR, out)
    elseif op == "XOR"
        return Rule(inA, inB, XOR, out)
    end
    error("invalid operator $op")
end

function parseRule(line)
    m = match(r"(\w\w\w)\s(XOR|OR|AND)\s(\w\w\w)\s->\s(\w\w\w)", line)
    return Rule(m.captures[1], m.captures[3], m.captures[2], m.captures[4])
end


function solvePart1(starts, rules)
    state = Dict(k => b for (k, b) in starts)
    rulesByOutput = Dict(rule.out => rule for rule in rules)
    function cachedSolver(gate)
        if gate ∈ keys(state)
            return state[gate]
        end
        if gate ∉ keys(rulesByOutput)
            error("gate has no rule or cached output")
        end
        rule = rulesByOutput[gate]
        inA = cachedSolver(rule.inA)
        inB = cachedSolver(rule.inB)
        gateState = runOp(inA, inB, rule.op)
        state[gate] = gateState
        gateState
    end

    zgates = [gate for gate in keys(rulesByOutput) if 'z' in gate]
    sort!(zgates, rev=true)
    res = 0
    for gate in zgates
        res = 2*res + cachedSolver(gate)
    end
    return res
end

testStart, testRules = parseInput(testInput)
res = solvePart1(testStart, testRules)

println("Solution for part 1 for test Input: $res")


puzzleStart, puzzleRules = parseInput(puzzleInput)
res = solvePart1(puzzleStart, puzzleRules)

println("Solution for part 1 for puzzle Input: $res")
