mul_regex = r"mul\((\d+),(\d+)\)"

matched = [x for x in eachmatch(mul_regex, "mul(6789,9)mul[9f?89mul()]mumul(8,)lmul(8,688888)_mul(9,5))")]

test_input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"

function stringToMulsSum(s)
    sum(
    parse(Int, m[1])*parse(Int, m[2])
    for m in  eachmatch(mul_regex, s)
    )
end

println("part 1 for test input: ", stringToMulsSum(test_input))

strToMul = read(joinpath("day3","puzzle_input3.txt"), String)
println("part 1 for puzzle input: ", stringToMulsSum(strToMul))

testInput2 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

mulDoRegex = r"(?:mul\((\d+),(\d+)\))|(?:do\(\))|(?:don't\(\))"
function stringToMulsSumDo(s)
    sum_ = 0
    doState = true
    for m in eachmatch(mulDoRegex, s)
        if (m.match ∉ ["do()", "don't()"]) && doState
            sum_ += parse(Int, m[1])*parse(Int, m[2])
        elseif m.match == "do()"
            doState = true
        elseif m.match == "don't()"
            doState = false
        end
    end
    sum_
end

println("solutioin to part 2: ", stringToMulsSumDo(strToMul))