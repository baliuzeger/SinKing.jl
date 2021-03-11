module DCSource
using ...Types
using ...Network
import ...Network: act, update, state_dict
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor

struct DCSourceAgent{T <: AbstractFloat} <: Agent
    current::T
    acceptors_dc::Vector{Address}
    stack_dc_update::Vector{DCUpdate}
end

function update(agent::DCSourceAgent{T}, current::T) where {T <: AbstractFloat}
    agent.current = current
end

function state_dict()
end

function act(address::Address,
             agent::DCSourceAgent,
             t::T,
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat}

    for upd in agent.stack_dc_update
        new_stack_dc_update, updates = take_due_signals(t + dt, agent.stack_dc_update)
        
    end

    
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

end # module end
