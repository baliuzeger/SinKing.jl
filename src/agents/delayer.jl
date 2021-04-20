using ...Network
import ...Network: act, update, state_dict, accept

struct DelayerAgent{T <: AbstractFloat, U <: Signal}
    delay::T # delay time
    stack::Vector{(T, U)}
end

function update(agent::DelayerAgent{T}, updates::Vector{(T, Signal)}) where {T <: AbstractFloat, U <: Signal}
    agent.stack = updates
end

function state_dict(agent::DelayerAgent{T}) where {T <: AbstractFloat, U <: Signal}
    Dict
end
state_dict(agent::DelayerAgent) =

    


