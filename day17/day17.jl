# part 1

struct TriBitOperator
    instruction::UInt8
end

function TriBitOperator(a,b) return TriBitOperator(a<<3 + b) end

function TriBitOperator(t::TriBitOperator) return t end

mutable struct TriBitMemory
    A::Int64
    B::Int64
    C::Int64
    instructionPointer::Int64
    output::Vector{UInt8}
    instructions::Vector{TriBitOperator}
end

function TriBitMemory(A, B, C, instructions)
    return TriBitMemory(A, B, C, 1, [], TriBitOperator.(instructions))
end

function literalOperand(mem::TriBitMemory, t::TriBitOperator)
    t.instruction & 0b111
end

function comboOperand(mem::TriBitMemory, t::TriBitOperator)
    instruction = t.instruction&0b111
    if instruction== 4
        return mem.A
    elseif instruction == 5
        return mem.B
    elseif instruction == 6
        return mem.C
    else
        return instruction
    end
end

function setComboOperand!(mem::TriBitMemory, t::TriBitOperator, value)
    instruction = t.instruction&&0b111
    if instruction== 4
        mem.A = value
    elseif instruction == 5
        mem.B = value
    elseif instruction == 6
        mem.C = value
    end
end

function adv!(mem::TriBitMemory, t::TriBitOperator)
    mem.A = mem.A >> comboOperand(mem ,t)
end

function bxl!(mem::TriBitMemory, t::TriBitOperator)
    mem.B = mem.B ⊻ literalOperand(mem, t)
end

function bst!(mem::TriBitMemory, t::TriBitOperator)
    mem.B = (comboOperand(mem, t))&0b111
end

function jnz!(mem::TriBitMemory, t::TriBitOperator)
    if mem.A == 0
        return false
    else
        mem.instructionPointer = literalOperand(mem, t)
        return false
    end
end

function bxc!(mem::TriBitMemory, t::TriBitOperator)
    mem.B = mem.B ⊻ mem.C
end

function out!(mem::TriBitMemory, t::TriBitOperator)
    push!(mem.output, comboOperand(mem, t)&0b111)
end

function bdv!(mem::TriBitMemory, t::TriBitOperator)
    mem.B = mem.A >> comboOperand(mem ,t)
end

function cdv!(mem::TriBitMemory, t::TriBitOperator)
    mem.C = mem.A >> comboOperand(mem ,t)
end

function tick!(mem::TriBitMemory)
    t = mem.instructions[mem.instructionPointer]
    op = t.instruction & 0b111000
    if op == 0
        adv!(mem, t)
        mem.instructionPointer += 1
    elseif op == 1 << 3
        bxl!(mem, t)
        mem.instructionPointer += 1
    elseif op == 2 << 3
        bst!(mem, t)
        mem.instructionPointer += 1
    elseif op == 3 << 3
        jumped = jnz!(mem, t)
        if !jumped
            mem.instructionPointer += 1
        end
    elseif op == 4 << 3
        bxc!(mem, t)
        mem.instructionPointer += 1
    elseif op == 5 << 3
        out!(mem, t)
        mem.instructionPointer += 1
    elseif op == 6 << 3
        bdv!(mem, t)
        mem.instructionPointer += 1
    elseif op == 7 << 3
        cdv!(mem, t)
        mem.instructionPointer += 1
    end
    nothing
end

function loop!(mem::TriBitMemory)
    while checkbounds(Bool, mem.instructions, mem.instructionPointer)
        tick!(mem)
    end
    println()
end

# test cases

testMem = TriBitMemory(0, 0, 9, [TriBitOperator(2, 6)])
tick!(testMem)
testMem
@assert testMem.B == 1

testMem = TriBitMemory(10, 0, 0, [TriBitOperator(5, 0), TriBitOperator(5, 1), TriBitOperator(5, 4)])
tick!(testMem)
tick!(testMem)
tick!(testMem)
@assert testMem.output == [0, 1, 2]

testMem = TriBitMemory(2024, 0, 0, [TriBitOperator(0, 1), TriBitOperator(5, 4), TriBitOperator(3, 0)])
loop!(testMem)
@assert testMem.output == [4,2,5,6,7,7,7,7,3,1,0]

testMem = TriBitMemory(0, 29, 0, [TriBitOperator(1, 7)])
tick!(testMem)
@assert testMem.B == 26

testMem = TriBitMemory(0, 2024, 43690, [TriBitOperator(4, 0)])
tick!(testMem)
@assert testMem.B == 44354

testInput = """Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0
"""

testMem = TriBitMemory(729, 0, 0, TriBitOperator.([1, 5<<3 + 4, 3<<3 + 0]))
loop!(testMem)
println(join(testMem.output, ','))

puzzleMem = TriBitMemory(30899381, 0, 0,
    TriBitOperator.([2<<3 + 4,1<<3 + 1,7<<3 + 5,4<<3 + 0,0<<3 + 3,1<<3 + 6,5<<3 + 5,3<<3 + 0])
)

loop!(puzzleMem)
println(join(puzzleMem.output, ','))

# part two

# trying brute force didn't work

function findQuine(program; minA=1, maxA=30_899_381*32)
    expectedOutput = program
    instructions = [TriBitOperator(x, y) for (x,y) in zip(expectedOutput[1:2:end], expectedOutput[2:2:end])]

    for (i, a) in enumerate(minA:maxA)
        if count_ones(i) ≤ 2
            println(i)
        end
        mem = TriBitMemory(a, 0, 0, instructions)
        if isMemQuine!(mem, expectedOutput)
            return a
        end
        if count_ones(i) ≤ 2
            println(mem)
        end
    end
    return nothing
end

function isMemQuine!(mem, expectedOutput)
    outputLength = 0
    expectedLength = length(expectedOutput)
    while checkbounds(Bool, mem.instructions, mem.instructionPointer)
        tick!(mem)
        # println(mem)
        l = length(mem.output)
        if l == outputLength
            continue
        end
        outputLength = l
        if expectedLength < l || mem.output[l] != expectedOutput[l]
            # println("failed: $(expectedLength < l) || $( mem.output[l] != expectedOutput[l])")
            return false
        end

    end
    # println("$(mem.output) == $(expectedOutput)")
    return mem.output == expectedOutput
end




# trying deeper thinking
