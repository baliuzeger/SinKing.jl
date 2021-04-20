using ...Network
import ...Network: act, update, state_dict, accept
using ...Signals

struct DelayerAgent{T <: AbstractFloat, U::Unsigned, V <: Signal}
    delay::T # delay time
    w::AbstractFloat
    stack::Vector{(T, U)}
    donor::Address{U}
    acceptor::Address{U}
end

function update(agent::DelayerAgent{T}, updates::Vector{(T, Signal)}) where {T <: AbstractFloat, U <: Signal}
    agent.stack = updates
end

## state_dict is for recording states, not for network-serialization. temporarily commented.
# function state_dict(agent::DelayerAgent{T}) where {T <: AbstractFloat, U <: Signal}
#     Dict(["stack" => map(state_dict, agent.stack)])
# end

function act(address::Address{U},
             agent::DelayerAgent{T, V},
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat, U <: Unsigned, V <: Signal}

    new_stack, due_stack = reduce(agent.stack; Init=(Vector{(T, V)}(undef, 0), Vector{V}(undef, 0)))
    do (acc, pair)
        new_t = pair[1] - dt
        if new_t >= 0
            ([acc[1]..., (new_t, pair[2])], acc[2])
        else
            (acc[1], [acc[2]..., amplify(pair[2], agent.w)])
        end
    end

    foreach(s -> push_signal(agent.acceptor, s), due_stack)
    update_agent(address, new_stack)
    if length(new_stack) > 0
        push_task(address)
    end
    
end

accept
    


