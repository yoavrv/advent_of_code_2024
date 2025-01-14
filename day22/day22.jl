
# there is probably a very clever mathematical way to solve this

# lets hope llvm compiler is smart enouogh to do ut

function run(seed, iterations=1; verbose=false)
    num = seed
    pruneMask = (1 << 24) - 1
    for i in 1:iterations
        num = (num ⊻ (num << 6)) & pruneMask
        num = (num ⊻ (num >> 5)) & pruneMask
        num = (num ⊻ (num << 11)) & pruneMask
        if verbose println(num) end
    end
    num
end

run(123, 10, verbose=true)

testInput = [1,10,100,2024]

println("solution for past 1 test input: ", sum(run.(testInput, 2000)))


puzzleInput = parse.(Int32, readlines(joinpath("day22","puzzle_input22.txt")))
println("solution for past 1 puzzle input: ", sum(run.(puzzleInput, 2000)))

# part 2

# For a single monkey, we have to keep track of all the previous
# four combination: We can always get a new "best" price which we have to check
# against the leading combination having already being seen

# We have n moneys, 2,000 iterations, and we need to keep track of 21x21x21x21
# possible sequences, which is an almost too much things to track

# outline:
# we can have an array
# worth[monkeys, off1, off2, off3, off4] = -1
# then each iteration calculate the offsets, and update
# if we have a new value
# worth[monkeys, off1, off2, off3, off4] = worth[...] == -1 ? new : worth[...]
# At the end, we set all the -1 to 0 and sum
# argmax(sum(max.(worth, 0), axis=monkeys))

using OffsetArrays

const pruneMask = (1 << 24) - 1
function nextMonkeyNumbers!(num)
    num .= (num .⊻ (num .<< 6)) .& pruneMask
    num .= (num .⊻ (num .>> 5)) .& pruneMask
    num .= (num .⊻ (num .<< 11)) .& pruneMask
end

function findBestSequence(monkeyNumbers; iterations=2_000, verbose=false)
    numMonkeys = length(monkeyNumbers)
    worth = fill(Int16(-1), (numMonkeys, 21, 21, 21, 21))
    worth = OffsetArray(worth, 1:numMonkeys, -10:10, -10:10, -10:10, -10:10)

    priceOffsets = zeros(Int16, (numMonkeys, 4))
    # do the first 4 iterations by hand
    prices = monkeyNumbers .% 10

    if verbose
        for i in 1:min(4, numMonkeys) 
            println(lpad(monkeyNumbers[i], 10), ": ",
                   lpad("", 3), " | ", lpad("", 3)) 
        end
    end
    nextMonkeyNumbers!(monkeyNumbers)
    newPrices = monkeyNumbers .% 10
    priceOffsets[:, 1] .= newPrices .- prices
    prices = newPrices

    if verbose
        for i in 1:min(4, numMonkeys) 
            println(lpad(monkeyNumbers[i], 10), ": ",
                   lpad(prices[i], 3), " | ", lpad(priceOffsets[i, 1], 3)) 
        end
    end

    nextMonkeyNumbers!(monkeyNumbers)
    newPrices = monkeyNumbers .% 10
    priceOffsets[:, 2] .= newPrices .- prices
    prices = newPrices
    
    if verbose
        for i in 1:min(4, numMonkeys) 
            println(lpad(monkeyNumbers[i], 10), ": ",
                   lpad(prices[i], 3), " | ", lpad(priceOffsets[i,2], 3)) 
        end
    end

    nextMonkeyNumbers!(monkeyNumbers)
    newPrices = monkeyNumbers .% 10
    priceOffsets[:, 3] .= newPrices .- prices
    prices = newPrices

    if verbose
        for i in 1:min(4, numMonkeys) 
            println(lpad(monkeyNumbers[i], 10), ": ",
                   lpad(prices[i], 3), " | ", lpad(priceOffsets[i,3], 3)) 
        end
    end

    nextMonkeyNumbers!(monkeyNumbers)
    newPrices = monkeyNumbers .% 10
    priceOffsets[:, 4] .= newPrices .- prices
    for i in 1:numMonkeys
        worth[i, priceOffsets[i, :]...] = newPrices[i]
    end
    prices = newPrices

    if verbose
        for i in 1:min(4, numMonkeys) 
            println(lpad(monkeyNumbers[i], 10), ": ",
                   lpad(prices[i], 3), " | ", lpad(priceOffsets[i,4], 3)) 
        end
    end

    # loop the remaining
    for t in 4:iterations
        priceOffsets[:, 1:3] .=  priceOffsets[:, 2:4]
        nextMonkeyNumbers!(monkeyNumbers)
        newPrices = monkeyNumbers .% 10
        priceOffsets[:, 4] .= newPrices - prices
        for i in 1:numMonkeys
            worth[i, priceOffsets[i, :]...] = (
                worth[i, priceOffsets[i, :]...] == -1 ? newPrices[i] : worth[i, priceOffsets[i, :]...]
            )
        end
        prices = newPrices

        if verbose
            for i in 1:min(4, numMonkeys) 
                println(lpad(monkeyNumbers[i], 10), ": ",
                       lpad(prices[i], 3), " | ", lpad(priceOffsets[i,4], 3)) 
            end
        end
    end
    # fill
    bananas = sum(max.(worth, 0), dims=1)
    bestOffsets = argmax(bananas)
    return bestOffsets, bananas[bestOffsets]
end

findBestSequence([123], iterations=4, verbose=true)

testInput2 = [1, 2, 3, 2024]
offset, bananas = findBestSequence(testInput2)

println("Part 2 solution for testInput2: offset=", offset, " bananas=", bananas)

offset, bananas = findBestSequence(puzzleInput)
println("Part 2 solution for puzzle input: offset=", offset, " bananas=", bananas)

