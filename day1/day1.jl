using CSV, DataFrames, StatsBase

function dist_to_list(l1, l2)
    return abs(sum(abs.(sort(l1) .- sort(l2))))
end

# first part
test_list = [3 4
    4 3
    2 5
    1 3
    3 9
    3 3
]

println("Test list: ", test_list)

println("Test list distance: ", dist_to_list(test_list[:, 1], test_list[:, 2]))

# read list
println(pwd())

list = open(joinpath(pwd(), "day1", "puzzle_input1.txt")) do f
    CSV.read(f, DataFrame, delim="   ", header=false) |> Matrix
end
println("Check that loading works: ", list[1:4, :])

# run
println("Distance to list: ", dist_to_list(list[:, 1], list[:, 2]))

# second part

function similarity(l1, l2)
    counter = IdDict(zip(l1, Iterators.cycle(0)))
    for l in l2
        if haskey(counter, l)
            counter[l] += 1
        end
    end
    return sum(x * counter[x] for x in l1)
end

println("Test similarity: ", similarity(test_list[:, 1], test_list[:, 2]))
println("Final Answer: ", similarity(list[:, 1], list[:, 2]))