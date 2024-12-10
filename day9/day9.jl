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

function cleanSystemfileInput(s)
    while s[end] ∉ "0123456789"
        # remove bad characters at the end \n,\r and such
        s = s[1:end-1]
    end
    if length(s)%2==0
        # remove final empty space
        s = s[1:end-1]
    end
    s
end

function getFilesystemCheckSum(s, verbose=false)
    """We have a running index i and a counter-running index j"""
    s = cleanSystemfileInput(s)
    l = length(s)
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

function printSystem(v)
    for (i, d) in enumerate(v)
        thing= i%2==1 ? "$(i÷2)," : ".,"
        print(thing^d)
    end
    print("\n")
end

function printSystem(s::String) printSystem(parse.(Int8, split(s, ""))) end


function getFilesystemCheckSum2(s, verbose=false)
    """We have a running index i and a counter-running index j"""
    s = cleanSystemfileInput(s)
    # here we need a real vector, since we insert and change things
    v = parse.(Int8, split(s, ""))
    l = length(v)
    positions = cumsum(v) # ith element: the End of the part i.e. 1 0 2 3 4 
                          #                                    => 1 1 3 6 10
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
            # find the right available slot
            d += 1
            i = digitIterators[d]
            if verbose println("d=$d, i=$i") end
            if !isnothing(i)
                break
            end
        end
        if isnothing(i) || j≤i
            # can't push this file: leaving it to be counted at the end
            continue
        end
        # we have a d-sized hole at i: fill it with j as much as possible
        if verbose println("j=$j, i=$i, d=$d, lj=$lj, v[$i]= $(v[max(i-2,1):min(l,i+2)]), v[$j] = $(v[max(1,j-2):min(j+2,l)])") end
        if verbose println("positions[$i]= $(positions[max(i-2,1):min(l,i+2)])") end
        newVi = d-lj
        v[i] = newVi
        v[j] = 0
        δ = sum((positions[i]-d):(positions[i]-newVi-1))*(j÷2)
        if verbose println(δ) end
        checksum += δ
        if newVi != 0
            # the new hole might be before one of the iterators: restore it back
            i2 = digitIterators[newVi]
            if verbose println("next on $newVi: $i2") end
            if isnothing(i2) || i<i2
                digitIterators[newVi] = i
            end
        end
        if verbose println("d=$d, i=$i, $(v[i]), $(v[j])") end
        digitIterators[d] = findNext(==(d), v, i, 2)
        if all(isnothing.(digitIterators))
            # no more free spaces! 
            break
        end
    end

    # now calculate the remaining checksum: use positions to recover original index
    for i=1:2:length(v)
        checksum += sum(positions[i]-v[i]:positions[i]-1)*(i÷2)
    end
    checksum
end


function solveNaive(s; verbose=false)
    """We have a running index i and a counter-running index j"""
    v = parse.(Int8, split(replace(s, "\n"=>"","\r"=>""), ""))
    # here we need a real vector, since we insert and change things

    realvec = zeros(Int64, sum(v))
    j = 1
    for (i, x) in enumerate(v)
        realvec[j:j+x-1] .= (i%2) == 1 ? i÷2 : -1
        j += x
    end
    if verbose println(realvec) end
    lastCurr = -1
    seriesLength = 0
    currSeries = -1
    minJ=1
    for i = length(realvec):-1:1
        curr = realvec[i]
        if lastCurr == -1 && curr!=-1
            lastCurr = curr
        end
        if lastCurr < curr
            curr = -1
        end
        if currSeries == -1 && curr == -1
            continue
        elseif currSeries == -1
            currSeries = curr
            seriesLength = 1
        elseif currSeries != curr
            # flush
            lastCurr = currSeries
            if verbose println("flushing $i, $seriesLength, $currSeries") end
            while realvec[minJ] != -1
                minJ += 1
            end
            for j=minJ:min(length(realvec)-seriesLength, i)
                if all(realvec[j:j+seriesLength-1].==-1)
                    realvec[j:j+seriesLength-1].=currSeries
                    realvec[i+1:i+seriesLength].=-1
                    if verbose println(realvec) end
                    break
                end
            end
            currSeries = curr
            seriesLength = 1
        else
            seriesLength += 1
        end
    end
    if verbose println(realvec) end
    sum(max((i-1)*x,0) for (i, x) in enumerate(realvec))
end

println("checksum #2 for test input: ", getFilesystemCheckSum2(testInput, true))
println("")
println("checksum #2 for puzzle input: ", getFilesystemCheckSum2(puzzleInput, false))

println("checksum #2 naive for test input: ", solveNaive(testInput, verbose=false))
println("checksum #2 naive for puzzle input: ", solveNaive(puzzleInput, verbose=false))
# 6408944901801