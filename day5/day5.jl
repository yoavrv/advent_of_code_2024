testInput = """47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47
"""

puzzleInput = read(joinpath("day5","puzzle_input5.txt"), String)

function breakInput(s)
    rules, lists = split(replace(s, "\r" => ""),"\n\n") 
    rules = reduce(hcat, [parse(Int32, y) for y in split(x,"|")] for x in split(rules, "\n", keepempty=false))
    lists = [[ parse(Int32,y) for y in split(x,",")] for x in split(lists,"\n", keepempty=false)]
    return rules, lists
end

function crunchRules(rules)
    """I have no idea how to do this in a reasonable way
    
    so instead, I"ll re-process the rules whatever O(n^cajillion) and get a sorting structure
    "Floating" the values up
    """
    rules = rules[:, sortperm(rules[2, :])]
    valuesToSort = Dict{Int32, Int32}()
    # We start with all number at sorting value 1, then "float" successive levels
    # by proving they are after numbers of the previous level
    for pre in rules[1, :] valuesToSort[pre] = 1 end
    for post in rules[2,:] valuesToSort[post] = 2 end

    numbers = sort([x for x in keys(valuesToSort)])
    for i in 1:length(numbers) # we know the maximum level is length sortvalues i.e. 1:N
        n2r = 1 # n to rules index
        foundAny=false
        for n in numbers
            if valuesToSort[n] != i continue end
            foundAny=true
            # The rules are sorted, so we iterate until we get our number, then check the level of the "befores"
            for j = n2r:size(rules)[2]
                m = rules[2, j]
                if n < m break # break if we're past the rules for n
                elseif m < n continue end # skip the rules for m<n
                n2r = j
                # run over the rules for n
                beforesLevel = valuesToSort[rules[1, j]]
                if i ≤ beforesLevel
                    valuesToSort[n] = beforesLevel + 1
                    continue
                end
                
            end 
        end
        if i!=1 && !foundAny
            break
        end
    end
    return valuesToSort
end

rules, lists = breakInput(testInput)
rulesDict = crunchRules(rules)
orderedRules = sort(collect(rulesDict), by=(x -> x.second))
println("Rules priority on test input: ", orderedRules)

function listFollowsRules(l, rules)
    i = 0
    for n in l
        j = get(rules, n, i)
        if j < i return false end
        i = j
    end
    return true
end

function sumMidLists(lists, rulesDict)
    sum(
        l[length(l)÷2+1]
        for l in lists
        if listFollowsRules(l, rulesDict)
    )
end

println("For test input, the sum of mids is: ", sumMidLists(lists, rulesDict))

rules, lists = breakInput(puzzleInput)
rulesDict = crunchRules(rules)
println("For puzzle input, the sum of mids is: ", sumMidLists(lists, rulesDict))

# turns out the rules are not self consistent (there are cycles)

function crunchRules2(rules)
    rulesDict = Dict{Int32, Vector{Int32}}()
    for i in 1:size(rules)[2]
        a, b = rules[:, i]
        if a ∉ keys(rulesDict); rulesDict[a] = [] end
        append!(rulesDict[a], b)
    end
    rulesDict
end

function isXbeforeY(x, y, rulesDict)
    return x ∉ get(rulesDict, y, [])
end

function listFollowsRules2(l, rulesDict)
    for (i, y) in enumerate(l)
        for x in l[1:i]
            if !isXbeforeY(x, y, rulesDict) return false end
        end
    end
    return true
end

rules, lists = breakInput(testInput)
rulesDict = crunchRules2(rules)
midsum = sum(
    l[length(l)÷2+1] for l in lists
        if listFollowsRules2(l, rulesDict)
)
println("For test input, the sum of mids is: ", midsum)


rules, lists = breakInput(puzzleInput)
rulesDict = crunchRules2(rules)
midsum = sum(
    l[length(l)÷2+1] for l in lists
        if listFollowsRules2(l, rulesDict)
)
println("For puzzle input, the sum of mids is: ", midsum)


# part 2
function reorderList(l, rulesDict, verbosity=false)
    # there is some sort of bug at the final iteration missing
    # so just rerun twice
    l = copy(l)
    maxiteration = 1000
    iteration = 1
    i = 1
    while i ≤ length(l) && iteration ≤ maxiteration
        y = l[i]
        i_ = i
        i+=1
        if verbosity 
            println("At $i_: $y") 
        end
        for (j, x) in enumerate(l[1:i_])
            if x ∈ get(rulesDict, y, [])
                if verbosity println("Swapping $i_: $y with $j: $x") end
                l[j], l[i_] = l[i_], l[j]
                i = j
                break
            end
        end
        iteration += 1
    end
    if iteration == maxiteration println("failed!") end
    return l
end


rules, lists = breakInput(testInput)
rulesDict = crunchRules2(rules)
midsum = sum(
    reorderList(l, rulesDict)[length(l)÷2+1] for l in lists
        if !listFollowsRules2(l, rulesDict)
)
println("For test input, the sum of mids for reordered is: ", midsum)

rules, lists = breakInput(puzzleInput)
rulesDict = crunchRules2(rules)
midsum = sum(
    reorderList(reorderList(l, rulesDict),rulesDict)[length(l)÷2+1] for l in lists
        if !listFollowsRules2(l, rulesDict)
)
println("For puzzle input, the sum of mids for reordered is: ", midsum)

findfirst(x -> !listFollowsRules2(x, rulesDict),
    [reorderList(l[1:min(22,length(l))], rulesDict) for l in lists
        if !listFollowsRules2(l, rulesDict)]
)

reorderList([reorderList(l[1:min(22,length(l))], rulesDict) for l in lists
if !listFollowsRules2(l, rulesDict)][92], rulesDict, true)