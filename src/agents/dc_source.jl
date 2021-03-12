module DCSource
using ...Types
using ...Network
import ...Network: act, update, state_dict
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

struct DCSourceAgent{T <: AbstractFloat, U <: Unsigned} <: Agent
    current::T
    acceptors_dc::Vector{Address{U}}
    stack_t_dc::Vector{TimedDC{T}}
end

struct DCSourceUpdate{T <: AbstractFloat} <: AgentUpdates
    current::T
    stack_t_dc::Vector{TimedDC{T}}
end

function update(agent::DCSourceAgent{T, U}, current::T) where {T <: AbstractFloat, U <: Unsigned}
    agent.current = current
end

state_dict(agent::DCSourceAgent) = Dict(["current" => agent.current])

function act(address::Address{U},
             agent::DCSourceAgent{T, U},
             t::T,
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat, U <: Unsigned}

    new_current = agent.current
    new_stack_t_dc = agent.stack_t_dc
    new_stack_t_dc, updates = take_due_signals(t + dt, agent.stack_t_dc)
    
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

    if length(new_stack_t_dc) > 0
        # push task for the next update
        next_t = new_stack_t_dc[1].t
        for upd in new_stack_t_dc
            if upd.t < next_t
                next_t = upd.t
            end
        end
        push_task(address, next_t - dt)
    end

    update_agent(address, DCSourceUpdate(new_current, new_stack_t_dc))
end

function can_add_acceptor(agent::DCSourceAgent{T, U},
                          signal_name::String) where {T <: AbstractFloat, U <: Unsigned}
    signal_name == name_t_dc ? true : false
end

function add_acceptor(agent::DCSourceAgent{T, U},
                      signal_name::String,
                      address::Address{U}) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_acceptor(agent, signal_name)
        push!(agent.acceptors_dc)
    else
        error("DCSourceAgent cannot add $signal_name acceptors!")
    end
end

function can_add_donor(agent::DCSourceAgent{T, U},
                       signal_name::String) where {T <: AbstractFloat, U <: Unsigned}
    false
end

function add_donor(agent::DCSourceAgent{T, U},
                   signal_name::String,
                   address::Address{U}) where {T <: AbstractFloat, U <: Unsigned}
    error("DCSourceAgent cannot add $signal_name donors!")
end

function accept(agent::DCSourceAgent{T, U}, signal::TimedDC{T}) where {T <: AbstractFloat, U <: Unsigned}
    push!(agent.stack_t_dc, signal)
end

end # module end
