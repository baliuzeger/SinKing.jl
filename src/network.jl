using Sinking.Types

module Network

# struct Network
#     populations::Dict{string, Vector{Agent}}
#     # queue::Vector{(AbstractFloat, Address)} # (time, address)
# end

struct Position{T <: AbstractFloat}
    x1::T
    x2::T
    x3::T
end

struct Seat{T <: AbstractFloat, U <: Agent}
    position::Position{T}
    agent::Agent
end

end # Module end
