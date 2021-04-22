using ...Network
import ...Network: act, update, state_dict, accept
using ...Signals

struct DelayerAgent{T <: AbstractFloat, U::Unsigned, V <: Signal}
    delay::T # delay time
    w::AbstractFloat
    stack::Vector{(T, V)}
    donor::Address{U}
    acceptor::Address{U}
end

function DelayerAgent(
    delay::T,
    w::AbstractFloat,
    donor::Address{U},
    acceptor::Address{U},
    signal_name::String,
    network::Dict{String, Population{U, T}}
) where {T <: AbstractFloat, U::Unsigned, V <: ForwardSignal}
    donor_check = can_add_acceptor(get_agent(network, donor), signal_name)
    acceptor_check = can_add_donor(get_agent(network, acceptor), signal_name)
    if donor_check && acceptor_check
        DelayerAgent(delay, w, [], donor, acceptor)
    else
        error(string("DelayerAgent cannot be created for $(signal_name) on: ",
                     donor_check ? "" : "donor $(donor)",
                     ! donor_check && ! acceptor_check ? "and" : "",
                     acceptor_check ? "" : "acceptor $(acceptor)",
                     "."))
    end
end
    
function update(agent::DelayerAgent{T, U, V},
                updates::Vector{(T, V)}) where {T <: AbstractFloat, U <: Signal, V <: ForwardSignal}
    agent.stack = updates
end

## state_dict is for recording states, not for network-serialization. temporarily commented.
# function state_dict(agent::DelayerAgent{T}) where {T <: AbstractFloat, U <: ForwardSignal}
#     Dict(["stack" => map(state_dict, agent.stack)])
# end

function act(address::Address{U},
             agent::DelayerAgent{T, V},
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat, U <: Unsigned, V <: ForwardSignal}

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

function accept(agent::DelayerAgent{T, U, V}, signal::U) where {T <: AbstractFloat, U::Unsigned, V <: ForwardSignal}
    push!(agent.stack, (agent.delay, signal))
end
    
function can_add_donor(agent::DelayerAgent{T, U, V},
                       signal_name::String) where {T <: AbstractFloat, U::Unsigned, V <: ForwardSignal}
    signal_name == name_dc_instruction
end

function accept(agent::DelayerAgent{T, U, V},
                signal::BackSpike) where {T <: AbstractFloat, U::Unsigned, V <: ForwardSignal}
    # STDP
end
