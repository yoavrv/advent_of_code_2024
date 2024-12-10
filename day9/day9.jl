testInput = "2333133121414131402"

puzzleInputPath = joinpath("day9", "puzzle_input9.txt")
puzzleInput = read(puzzleInputPath, String)

function addToChecksum(position, N, score)
    return (position*N + ((N-1)*N)÷2) * score
end

function parseX(x)
    parse(UInt8, x)
end

function parseX(x::UInt8)
    x
end

function getFilesystemCheckSum(s, verbose=false)
    """We have a running index i and a counter-running index j"""
    while s[end] ∉ "0123456789"
        s = s[1:end-1]
    end
    l = length(s)
    if l%2==0
        l = l-1
    end
    j = l
    highIndex = (l-1)÷2
    lowIndex = 0
    position = 0
    lj = parseX(s[j])
    onfileI = true
    checksum = 0
    for i = 1:l
        # li = parseX(s[i])
        if j<i break end
        if i==j
            δ = addToChecksum(position, lj, highIndex)
            if verbose li =parseX(s[i]); println("A: $i: $li $j: $lj: at $position taking $highIndex ($lowIndex) checksum +$(δ)") end
            checksum += δ
            # position += lj
            break
        end
        li = parseX(s[i])
        if onfileI
            δ = addToChecksum(position, li, lowIndex)
            if verbose println("B: $i: $li $j: $lj: at $position taking $lowIndex checksum +$(δ)") end
            checksum += δ
            position += li
            lowIndex+=1
            onfileI=false
            continue
        else
            maxJ = 10
            for jlim = 1:maxJ  # this is really a while lj < li loop but we know it can't go for long
                if li ≤ lj break end
                δ = addToChecksum(position, lj, highIndex)
                if verbose println("C: $i: $li $j: $lj: at $position taking $highIndex checksum +$(δ)") end
                checksum += δ
                position += lj
                li -= lj
                highIndex -= 1
                j -= 2
                if j ≤ i break end
                lj = parseX(s[j])
            end
            if  j ≤ i break end
            if li < lj
                δ = addToChecksum(position, li, highIndex)
                if verbose println("D: $i: $li $j: $lj: at $position taking $highIndex checksum +$(δ)") end
                lj -= li
                checksum += δ 
                position += li
                onfileI=true
                continue
            end
            if li == lj
                δ = addToChecksum(position, li, highIndex)
                if verbose println("E: $i: $li $j: $lj: at $position taking $highIndex checksum +$(δ)") end
                checksum += δ
                position += li
                highIndex -= 1
                onfileI=true
                j -= 2
                lj = parseX(s[j])
                if j≤i break end
                continue
            end
        end
    end
    checksum
end

println("checksum #1 for test input: ", getFilesystemCheckSum(testInput, true))

println("checksum #1 for puzzle input: ", getFilesystemCheckSum(puzzleInput, false))

function findNext(pred, A, i=1, s=1)
    return (findfirst(pred, A[i+s:s:end])) |> x -> isnothing(x) ? nothing : i+s*x
end

function printSystem(s)
    for (i, d) in enumerate(split(s,""))
        thing= i%2==1 ? "$(i÷2)," : ".,"
        print(thing*parse(Int8,d))
    end
    print("\n")
end

function getFilesystemCheckSum2(s, verbose=false)
    """We have a running index i and a counter-running index j"""
    while s[end] ∉ "0123456789"
        s = s[1:end-1]
    end
    # here we need a real vector, since we will change things
    v = parse.(Int8, split(s, ""))
    l = length(v)
    if l%2==0
        l -= 1
    end
    positions = cumsum(v) # ith element: the End of the part i.e. 1 0 2 3 4                                                     => 1 1 3 6 10
    checksum = 0
    digitIterators::Vector{Union{Int64, Nothing}} = [findfirst(==(x), v[2:2:end]) |> y -> !isnothing(y) ? 2*y : y for x in 1:9]
    for j=l:-2:1
        # move each left to a fitting hole. shrink the hole, use positions to recover the original location
        if verbose println(v) end
        lj = v[j]
        i = nothing
        d = lj-1
        if lj==0
            continue
        end
        if verbose println("j=$j, lj=$lj, index=$(j÷2): ", digitIterators) end
        while d<9
            d += 1
            i = digitIterators[d]
            if verbose println("d=$d, i=$i") end
            if !isnothing(i)
                break
            end
        end
        if isnothing(i) || j≤i
            continue
        end
        # fill i with j
        if verbose println("j=$j, i=$i, d=$d, lj=$lj, v[$i]= $(v[max(i-2,1):min(l,i+2)]), v[$j] = $(v[max(1,j-2):min(j+2,l)])") end
        if verbose println("positions[$i]= $(positions[max(i-2,1):min(l,i+2)])") end
        newVi = d-lj
        v[i] = newVi
        v[j] = 0
        δ = sum((positions[i]-d):(positions[i]-newVi-1))*(j÷2)
        if verbose println(δ) end
        checksum += δ
        if newVi != 0
            i2 = digitIterators[newVi]
            if verbose println("next on $newVi: $i2") end
            if isnothing(i2) || i<i2
                digitIterators[newVi] = i
            end
        end
        if verbose println("d=$d, i=$i, $(v[i]), $(v[j])") end
        digitIterators[d] = findNext(==(d), v, i, 2)
        if all(isnothing.(digitIterators)) 
            break
        end
        
    end

    # now calculate the remaining checksum: use positions to recover original index
    for i=1:2:length(v)
        checksum += sum(positions[i]-v[i]:positions[i]-1)*(i÷2)
    end
    checksum
end

println("checksum #2 for test input: ", getFilesystemCheckSum2(testInput, true))
println("")
println("checksum #2 for puzzle input: ", getFilesystemCheckSum2(puzzleInput, false))
