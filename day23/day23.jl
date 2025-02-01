# Well, part of my reason to do this is to learn julia
using GLMakie
using Graphs, GraphMakie
using GraphMakie.NetworkLayout
# from package import solution

g = smallgraph(:dodecahedral)
graphplot(g; layout=Stress(; dim=3))

el = Edge.([(1, 3), (3, 4), (3, 2), (2, 1)])
g = SimpleGraph(el)
graphplot(g, layout=Stress(; dim=3))

function str2num(twoLetterStr)
    """Convert the two letter xy to an int"""
    valueA = Int('a')
    return sum( (Int(c)-valueA)*(26^(i-1)) for (i, c) in enumerate(twoLetterStr))
end

function startsWithT(nodeInt)
    return nodeInt .% 26 .== 19
end

testInput = """
kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
ta-co
de-co
tc-td
tb-wq
wh-td
ta-ka
td-qp
aq-cg
wq-ub
ub-vc
de-ta
wq-aq
wq-vc
wh-yn
ka-de
kh-ta
co-tc
wh-qp
tb-vc
td-yn
"""

function parseInput(s)
    [
    split(line, "-")
    for line in split(replace(s, "\r"=> ""), "\n", keepempty=false)
    ]
end

testInputParsed = parseInput(testInput)

nodes = sort(unique(y for x in testInputParsed for y in x), by=x -> (x[1]=='t' ? 'A' : x[1], x[2]))

num2nodes = Dict(enumerate(nodes))
nodes2num = Dict(c => i for (i, c) in enumerate(nodes))

isT = [x[1] == 't' for x in nodes]
numT = sum(isT)

testLanParty = SimpleGraph(Edge.( (nodes2num[a], nodes2num[b]) for (a, b) in testInputParsed))
graphplot(testLanParty;
    ilabels=["$num: $node" for (node, num) in enumerate(nodes)],
    ilabels_color=[x ? :black : :white for x in isT],
    node_color=[x ? :red : :black for x in isT],
    layout=Stress(; dim=3)
)

lanCycles = cycle_basis(testLanParty)
nodeCycles = replace.(lanCycles, num2nodes...)

cyclesWithT = filter(x -> any(i in x for i in 1:numT), lanCycles)

tCycles = replace.(cyclesWithT, num2nodes...)

# ["td", "wh", "yn"]
#  ["td", "qp", "wh"]
 ["tc", "kh", "qp", "wh"]
#  ["co", "ka", "ta"]
#  ["de", "ka", "ta"]
 ["cg", "tb", "ka", "ta", "kh", "qp", "wh", "yn"]
 ["vc", "tb", "ka", "ta", "kh", "qp", "wh", "yn", "aq"]
 ["wq", "tb", "ka", "ta", "kh", "qp", "wh", "yn", "aq"]
 ["cg", "de", "ta", "kh", "qp", "wh", "yn"]
#  ["co", "de", "ta"]
 ["tc", "co", "ta", "kh"]
#  ["td", "tc", "wh"]

# co,de,ta
# co,ka,ta
# de,ka,ta
# # qp,td,wh
# # tb,vc,wq
# tc,td,wh
# td,wh,yn

function edge2cycleNum(edge, cycles)
    for (i, cycle) in enumerate(cycles)
        if edge in Edge.(zip(cycle, circshift(cycle, -1)))
            return i
        end
    end
    0
end

graphplot(testLanParty;
    ilabels=["$num: $node" for (node, num) in enumerate(nodes)],
    ilabels_color=[x ? :black : :white for x in isT],
    node_color=[x ? :red : :black for x in isT],
    edge_color=[edge2cycleNum(ab, lanCycles) for ab in edges(testLanParty)],
    layout=Stress(; dim=3)
)


# I have no clue how to solve this "well". I'm sure there is, but I'm very bad at graph algorithms

# First insight the I think is correct: we can cut down the work by solving for vertex "i" and then removing it from the graph 

# Easiest option: for vertex i, look for the neighbors. Every edge between neighbors in this first layer is a 3-cycle
# (won't work for larger cycles by looking at the k//2-th layer even if counting the number of connections or something,
#  because we lose the history and we don't have a cycle of two vertices path shared a vertex)


testInputParsed = parseInput(testInput)

nodes = sort(unique(y for x in testInputParsed for y in x), by=x -> (x[1]=='t' ? 'A' : x[1], x[2]))

num2nodes = Dict(enumerate(nodes))
nodes2num = Dict(c => i for (i, c) in enumerate(nodes))

isT = [x[1] == 't' for x in nodes]
numT = sum(isT)

testLanParty = SimpleGraph(Edge.( (nodes2num[a], nodes2num[b]) for (a, b) in testInputParsed))
graphplot(testLanParty;
    ilabels=["$num: $node" for (node, num) in enumerate(nodes)],
    ilabels_color=[x ? :black : :white for x in isT],
    node_color=[x ? :red : :black for x in isT],
    layout=Stress(; dim=3)
)

number3kCyclesWithT=0
g = copy(testLanParty)
for v in 1:numT
    num3kCyclesWithV=0
    neighV = neighbors(g, v)
    for (i, v1) in enumerate(neighV)
        for v2 in neighV[i+1:end]
            if has_edge(g, v1, v2)
                num3kCyclesWithV += 1
                println("($(num2nodes[v]), $(num2nodes[v1]), $(num2nodes[v2])) is a cycle")
            else
                println("($(num2nodes[v]), $(num2nodes[v1]), $(num2nodes[v2])) is not a cycle")
            end
        end
    end
    number3kCyclesWithT += num3kCyclesWithV
    rem_vertex!(g, v)
end
println(number3kCyclesWithT)


function get3kcyclesWithT(input)
    inputParsed = parseInput(input)

    nodes = sort(unique(y for x in inputParsed for y in x), by=x -> (x[1]=='t' ? 'A' : x[1], x[2]))
    
    nodes2num = Dict(c => i for (i, c) in enumerate(nodes))
    
    isT = [x[1] == 't' for x in nodes]
    numT = sum(isT)
    
    g_graph = SimpleGraph(Edge.( (nodes2num[a], nodes2num[b]) for (a, b) in inputParsed))
    
    # if visualize
    #     cycles3kT=[]
    # end

    number3kCyclesWithT=0
    g = copy( g_graph)
    for v in 1:numT
        num3kCyclesWithV=0
        neighV = neighbors(g, v)
        for (i, v1) in enumerate(neighV)
            for v2 in neighV[i+1:end]
                if has_edge(g, v1, v2)
                    num3kCyclesWithV += 1
                    # if visualize
                    #     append!(cycles3kT)
                    # end
                end
            end
        end
        number3kCyclesWithT += num3kCyclesWithV
        rem_vertex!(g, v)
    end

    return number3kCyclesWithT
end

println("Solution for test input for part 1: ", get3kcyclesWithT(testInput))

puzzleInput = read(joinpath("day23","puzzle_input23.txt"), String)

println("Solution for puzzle input for part 1: ", get3kcyclesWithT(puzzleInput))


# part 2
# Hey, this wasn't "find all the 20 cycle with tx nodes"!

# from graphs import solution


cliques = maximal_cliques(testLanParty)
for clique in cliques
    println(replace(clique, pairs(num2nodes)...))
end

function getMaxMaximalClique(input)
    inputParsed = parseInput(input)

    nodes = sort(unique(y for x in inputParsed for y in x), by=x -> (x[1]=='t' ? 'A' : x[1], x[2]))
    
    num2nodes = Dict(enumerate(nodes))
    nodes2num = Dict(c => i for (i, c) in enumerate(nodes))
    
    g = SimpleGraph(Edge.( (nodes2num[a], nodes2num[b]) for (a, b) in inputParsed))

    cliques = maximal_cliques(g)
    clique = cliques[argmax(length.(cliques))]
    clique_names = replace(clique, pairs(num2nodes)...)
    sort!(clique_names)
    return join(clique_names, ",")
end

println("Solution for test input for part 2: ", getMaxMaximalClique(testInput))

puzzleInput = read(joinpath("day23","puzzle_input23.txt"), String)

println("Solution for puzzle Input for part 2: ", getMaxMaximalClique(puzzleInput))
