struct Network
    populations::Dict{string, Vector{Agent}}
    queue::Vector{(AbstractFloat, Address)} # (time, address)
end
