# some things for visualization of day21
const mainPad = [
    '7' '8' '9'
    '4' '5' '6'
    '1' '2' '3'
    '.' '0' 'A'
]

const robotPad = [
    '.' '^' 'A'
    '<' 'v' '>'
]

const robotPadIndex = [
    nothing               CartesianIndex(-1,0)  CartesianIndex(0, 0)
    CartesianIndex(0, -1) CartesianIndex(+1,0) CartesianIndex(0, 1)
]

const charToPad = Dict(                             '^' => CartesianIndex(1, 2), 'A' => CartesianIndex(1, 3),
                       '<' => CartesianIndex(2, 1), 'v' => CartesianIndex(2, 2), '>' => CartesianIndex(2, 3))

               
const charToMainPad = Dict('7' => CartesianIndex(1, 1), '8' => CartesianIndex(1, 2), '9' => CartesianIndex(1, 3),
                           '4' => CartesianIndex(2, 1), '5' => CartesianIndex(2, 2), '6' => CartesianIndex(2, 3),
                           '1' => CartesianIndex(3, 1), '2' => CartesianIndex(3, 2), '3' => CartesianIndex(3, 3),
                                                        '0' => CartesianIndex(4, 2), 'A' => CartesianIndex(4, 3),
                    )


const allViews = [
    '|' '7' '|' '8' '|' '9' '|' ' ' '|' '.' '|' '^' '|' 'A' '|' ' ' '|' '.' '|' '^' '|' 'A' '|' ' ' '|' '.' '|' '^' '|' 'A' '|'
    '|' '4' '|' '5' '|' '6' '|' ' ' '|' '<' '|' 'v' '|' '>' '|' ' ' '|' '<' '|' 'v' '|' '>' '|' ' ' '|' '<' '|' 'v' '|' '>' '|'
    '|' '1' '|' '2' '|' '3' '|' ' ' '.' '.' '.' '.' '.' '.' '.' ' ' '.' '.' '.' '.' '.' '.' '.' ' ' '.' '.' '.' '.' '.' '.' '.'
    '|' '.' '|' '0' '|' 'A' '|' ' ' '.' '.' '.' '.' '.' '.' '.' ' ' '.' '.' '.' '.' '.' '.' '.' ' ' '.' '.' '.' '.' '.' '.' '.'
]

state = [CartesianIndex(4, 3), CartesianIndex(1, 3), CartesianIndex(1, 3), nothing]

function printState(state)
    views = deepcopy(allViews)
    i, j = Tuple(state[1])
    views[i, 2*j - 1] = '['
    views[i, 2*j + 1] = ']'
    i, j = Tuple(state[2])
    views[i, 8 + 2*j - 1] = '['
    views[i, 8 + 2*j + 1] = ']'
    i, j = Tuple(state[3])
    views[i, 16 + 2*j - 1] = '['
    views[i, 16 + 2*j + 1] = ']'
    if !isnothing(state[4])
        i, j = Tuple(state[4])
        views[i, 24 + 2*j - 1] = '['
        views[i, 24 + 2*j + 1] = ']'
    end
    rows = join.(eachrow(views))
    println.(rows)
    return
end

function tick!(state, self; verbose=false)
    state[4] = self
    δ = robotPadIndex[state[4]]
    if isnothing(δ) error("Bad press on robot 2!") end
    if δ != CartesianIndex(0, 0)
        if checkbounds(Bool, robotPad, state[3] + δ)
            state[3] = state[3] + δ
            if verbose printState(state) end
            return 4, robotPad[state[4]]
        end
        error("Off grid for robot 2!")
    end
    δ = robotPadIndex[state[3]]
    if isnothing(δ) error("Bad press on robot 1!") end
    if δ != CartesianIndex(0, 0)
        if checkbounds(Bool, robotPad, state[2] + δ)
            state[2] = state[2] + δ
            if verbose printState(state) end
            return 3, robotPad[state[3]]
        end
        error("Off grid for robot 1!")
    end
    δ = robotPadIndex[state[2]]
    if isnothing(δ) error("Bad press on pad!") end
    if δ != CartesianIndex(0, 0)
        if checkbounds(Bool, mainPad, state[1] + δ)
            state[1] = state[1] + δ
            if verbose printState(state) end
            return 2, robotPad[state[2]]
        end
        error("Off grid for main!")
    end
    if verbose printState(state) end
    return 1, mainPad[state[1]]
end
