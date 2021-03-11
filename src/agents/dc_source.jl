module DCSource
using ...Types
using ...Network
import ...Network: act, update, state_dict
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

struct DCSourceAgent{T <: AbstractFloat} <: Agent
    current::T
    acceptors_dc::Vector{Address}
    stack_dc_update::Vector{DCUpdate}
end

struct DCSourceUpdate{T <: AbstractFloat} <: AgentUpdates
    current::T
    stack_dc_update::Vector{DCUpdate}
end

function update(agent::DCSourceAgent{T}, current::T) where {T <: AbstractFloat}
    agent.current = current
end

state_dict(agent::DCSourceAgent) = Dict(["current" => agent.current])

function act(address::Address,
             agent::DCSourceAgent,
             t::T,
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat}

    new_current = agent.current
    new_stack_dc_update = agent.stack_dc_update
    new_stack_dc_update, updates = take_due_signals(t + dt, agent.stack_dc_update)
    
    if length(updates) > 0
        signal_upd = update[1]
        for upd in updates
            if upd.t > signal_upd.t
                signal_upd = upd
            end
        end
        new_current = signal_upd.current
        for adrs in agent.acceptors_dc
            push_task(adrs, signal_upd.t)
            push_signal(adrs, signal)
        end
    end

    if length(new_stack_dc_update) > 0
        # push task for the next update
        next_t = new_stack_dc_update[1].t
        for upd in new_stack_dc_update
            if upd.t < next_t
                next_t = upd.t
            end
        end
        push_task(address, next_t - dt)
    end

    update_agent(address, DCSourceUpdate(new_current, new_stack_dc_update))
end

can_add_acceptor(agent::DCSourceAgent, signal_name::String) = signal_name == name_dc_update ? true : false
function add_acceptor(agent::DCSourceAgent, signal_name::String, address::Address)
    if can_add_acceptor(agent, signal_name)
        push!(agent.acceptors_dc)
    else
        error("DCSourceAgent cannot add $signal_name acceptors!")
    end
end

can_add_donor(agent::DCSourceAgent, signal_name::String) = false
add_donor(agent::DCSourceAgent, signal_name::String, address::Address) = error(
    "DCSourceAgent cannot add $signal_name donors!"
)

function accept(agent::DCSourceAgent, signal::DCUpdate)
    push!(agent.stack_dc_update, signal)
end

end # module end
