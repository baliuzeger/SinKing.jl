module DCSource
export DCSourceAgent
using ...Types
using ...Network
import ...Network: act, update, state_dict, accept
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

mutable struct DCSourceAgent{T <: AbstractFloat, U <: Unsigned} <: Agent
    current::T
    acceptors_dc::Vector{Address{U}}
    stack_new_dc::NewDC{T}
end

function DCSourceAgent{T, U}() where {T <: AbstractFloat, U <: Unsigned}
    DCSourceAgent{T, U}(zero(T), [], [])
    # DCSourceAgent{T, U}(zero(T),
    #                     Vector{Address{U}}(undef, 0),
    #                     Vector{TimedDC{T}}(undef, 0))
end

# struct DCSourceUpdates{T <: AbstractFloat} <: AgentUpdates
#     current::T
# end

# function update(agent::DCSourceAgent{T, U},
#                 updates::DCSourceUpdates) where {T <: AbstractFloat, U <: Unsigned}
#     agent.current = updates.current
#     agent.stack_t_dc = updates.stack_t_dc
# end

state_dict(agent::DCSourceAgent) = Dict(["current" => agent.current])

function act(address::Address{U},
             agent::DCSourceAgent{T, U},
             dt::T,
             trigger,
             push_signal) where {T <: AbstractFloat, U <: Unsigned}
    if length(agent.stack_new_dc) > 0
        new_current = last(agent.stack_new_dc)
        instruction = DCInstruction(agent.current, new_current)
        for adrs in agent.acceptors_dc
            trigger(adrs)
            push_signal(adrs, tadc)
        end
        agent.current = new_current
        agent.stack_new_dc = []
    end
end

function can_add_acceptor(agent::DCSourceAgent{T, U},
                          signal_name::String) where {T <: AbstractFloat, U <: Unsigned}
    signal_name == name_dc_instruction ? true : false
end

function add_acceptor(agent::DCSourceAgent{T, U},
                      signal_name::String,
                      address::Address{U}) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_acceptor(agent, signal_name)
        push!(agent.acceptors_dc, address)
    else
        error("DCSourceAgent cannot add $signal_name acceptors!")        
    end
end

function accept(agent::DCSourceAgent{T, U}, signal::NewDC{T}) where {T <: AbstractFloat, U <: Unsigned}
    push!(agent.stack_new_dc, signal)
end # should also be triggered manually to let it act at the next step.

end # module end
