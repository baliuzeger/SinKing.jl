using ...Network
import ...Network: act, update, state_dict, accept

struct DelayerAgent{T <: AbstractFloat, U <: Signal}
    delay::T # delay time
    stack::Vector{(T, U)}
end

function update(agent::DelayerAgent{T}, updates::Vector{(T, Signal)}) where {T <: AbstractFloat, U <: Signal}
    agent.stack = updates
end

## state_dict is for recording states, not for network-serialization. temporarily commented.
# function state_dict(agent::DelayerAgent{T}) where {T <: AbstractFloat, U <: Signal}
#     Dict(["stack" => map(state_dict, agent.stack)])
# end



    


