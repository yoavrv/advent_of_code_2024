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

# checked out "reddit day 17 help": Suggested to look at the program and think in terms of octals
# so I should probably look at the actual program I got
# 2,4,1,1,7,5,4,0,0,3,1,6,5,5,3,0


function compiledProgram(A)
    output = []
    while A!=0
        B=A%8
        B=B ⊻ 1
        C=A>>B
        B=B⊻C
        A=A>>3
        B=B ⊻ 6
        push!(output, B&0b111)
    end
    return output
end

function optimizedProgram(A)
    output = []
    while A!=0
        B=(A&0b111) ⊻ 1
        B=B ⊻ (A>>B)
        push!(output, B ⊻ 0b110)
        A=A>>3
    end
    return output
end

# We can see that we have a while loop, which outputs a symbol and truncates A by 3 bits every time.

# This means for output [2,4,1,1,7,5,4,0,0,3,1,6,5,5,3,0] We need A to be a number of 16*3 bits, ~15 decimal digits
# the virtual machine is fast enough to run through 100 of millions of As, but this is nowhere near!

# We have to use the properties of this specific program: since we truncate A each step, we can try going backwards,
# reconstructing A based on the output

# e.g. if we have
# f(A = [abc def ghi]) -> o[1]
# f(A = [abc def]) -> o[2]
# f(A = [abc]) -> o[3]
# we want
# A[0]=0
# f^-1(A[0], o3) -> A[1] = abc
# f^-1(A[1], o2) -> A[2] = abc def
# f^-1(A[2], o1) -> A[3] = abc def ghi

# I tried reversing the kernel, but got stuck in B=A>>C, which use the original A value for shifts.
# instead, we can just "movie password crack" the number: for each output, go over all the possible 3 bit additions to A (a).
# and once we find a valid three bit, add it to A and go to the next output

# i.e
# A = A[i]
# o = Output[end-i]
# for a in 0:7
#   if f(Aa) == o
#       A = Aa
#       break

# this turns the problem from exponential 8^16 possible digits of A to multiplicative (8x16) bit combinations of A, which is much saner

# since we want the smallest value of A, and we build A big-to-small, then checking each 3bit step from 0 to 7 will
# yield the smallest solution

# the one final problem is that there could be multiple solutions for each oi, which could be invalidated in the next step
# so we need to "search" through the space and backtrack if we hit an invalid solution

function findQuineProgram()
    output = [2,4,1,1,7,5,4,0,0,3,1,6,5,5,3,0]
    function isOptimizedKernelValid(A, o)
        B=A%8
        B=B ⊻ 1
        C=A>>B
        B=B⊻C
        A=A>>3
        B=B ⊻ 6
        o == B&0b111
    end
    A = 0
    L = length(output)
    depth = 1
    while 1 ≤ depth ≤ L
        # we have A = a[1]a[2]...a[depth]
        # we check for reverse(output)[depth] and a[depth]
        o = output[end - depth + 1]
        if isOptimizedKernelValid(A, o)
            # if A works, we start the next 
            if depth == L
                println("Done A = 0o$(string(A, base=8)) for $o")
                break # found all digits
            end
            # go to the next 3 digits
            depth += 1
            A = A<<3
            println("Ascending A = 0o$(string(A, base=8)) for $o")
        else
            # if A didn't work, we go to the next a[depth]
            while A&0b111 == 7
                # if we checked all 0-7, we go back to the previous 3bit
                depth += -1
                A = A>>3
                println("reverting A = 0o$(string(A, base=8)) for $o")
            end
            A += 1
        end
    end
    A
end


# test solution
A = findQuineProgram()
quineMem = TriBitMemory(A, 0, 0,
    TriBitOperator.([2<<3 + 4,1<<3 + 1,7<<3 + 5,4<<3 + 0,0<<3 + 3,1<<3 + 6,5<<3 + 5,3<<3 + 0])
)

loop!(quineMem)
@assert quineMem.output == [2,4,1,1,7,5,4,0,0,3,1,6,5,5,3,0]
println(A)

