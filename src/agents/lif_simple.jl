module LIFSimple
export LIFSimpleAgent, accept, LIFSimpleParams
using ...Types
using ...AgentParts.LIFNeuron
using ...AgentParts.DC
using ...Network
import ...Network: act, update, state_dict
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

struct LIFSimpleParams
    lif::LIFParams
    delta_v::AbstractFloat
end

mutable struct LIFSimpleAgent{T <: AbstractFloat, U <: Unsigned} <: Agent
    # address::Address
    states::LIFStates
    params::LIFSimpleParams
    acceptors_t_delta_v::Vector{Address} # agents that accept from self.
    donors_t_delta_v::Vector{Address} # agents that donate to self.
    stack_t_delta_v::Vector{TimedDeltaV}
    ports_dc::Vector{DCPort{T, U}}
end

struct LIFSimpleUpdate{T <: AbstractFloat, U <: Unsigned} <: AgentUpdates
    states::LIFStates
    stack_t_delta_v::Vector{TimedDeltaV}
    ports_dc::Vector{DCPort{T, U}}
end

LIFSimpleAgent(
    states::LIFStates, params::LIFSimpleParams
) where {T <: AbstractFloat, U <: Unsigned} = LIFSimpleAgent{T, U}(states, params, [], [], [])

function update(agent::LIFSimpleAgent{T, U},
                update::LIFSimpleUpdate{T, U}) where {T <: AbstractFloat, U <: Unsigned}
    agent.states = update.states
    agent.stack_t_delta_v = update.stack_t_delta_v
end

function act(address::Address,
             agent::LIFSimpleAgent{T, U},
             t::T,
             dt::T,
             push_task,
             update_agent,
             push_signal) where{T <: AbstractFloat, U <: Unsigned}

    new_states = agent.states
    new_stack_t_delta_v = agent.stack_t_delta_v
    fired = false
    next_t = t + dt
    
    function inject_fn()
        new_stack_t_delta_v, signals = take_due_signals(t, agent.stack_t_delta_v)
        if ! isnothing(agent.states.refractory_end) # at end of refractory
            signals = filter(s -> s.t >= agent.states.refractory_end, signals)
        end
        return (0, reduce((acc, x) -> acc + x.delta_v,
                          signals;
                          init=0.0)) # (i_syn, delta_v)
    end

    function lif_update(states::LIFStates)
        new_states = states
    end

    function fire_fn()
        fired = true
    end

    function lif_push_task(t)
        next_t = t
    end
    
    evolve(t,
           dt,
           agent.states,
           agent.params.lif,
           inject_fn,
           lif_update,
           fire_fn,
           lif_push_task)

    update_agent(address, LIFSimpleUpdate(new_states, new_stack_t_delta_v))

    push_task(address, next_t)
    if fired
        signal = TimedDeltaV(next_t, agent.params.delta_v)
        for adrs in agent.acceptors_t_delta_v
            push_task(adrs, next_t)
            push_signal(adrs, signal)
        end
    end
end

function accept(agent::LIFSimpleAgent{T, U}, signal::TimedDeltaV) where{T <: AbstractFloat, U <: Unsigned}
    push!(agent.stack_t_delta_v, signal)
end

function can_add_donor(agent::LIFSimpleAgent{T, U},
                       signal_name::String) where{T <: AbstractFloat, U <: Unsigned}
    if signal_name == name_t_delta_v
        return true
    else
        return false
    end
end

function add_donor(agent::LIFSimpleAgent{T, U},
                   signal_name::String,
                   address::Address) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_donor(agent, signal_name)
        push!(agent.donors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name donors!")
    end
end

function can_add_acceptor(agent::LIFSimpleAgent{T, U},
                          signal_name::String) where{T <: AbstractFloat, U <: Unsigned}
    if signal_name == name_t_delta_v
        return true
    else
        return false
    end
end

function add_acceptor(agent::LIFSimpleAgent{T, U},
                      signal_name::String,
                      address::Address) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_acceptor(agent, signal_name)
        push!(agent.acceptors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name acceptors!")
    end
end

function state_dict(agent::LIFSimpleAgent{T, U}) where{T <: AbstractFloat, U <: Unsigned}
    return Dict(["v" => agent.states.v,
                 "refractory" => isnothing(agent.states.refractory_end) ? 0 : 1])
end

function accept(agent:: LIFSimpleAgent{T, U},
                signal::TimedAdrsDC{T, U}) where{T <: AbstractFloat, U <: Unsigned}
    found_port = false
    for port in agent.ports_dc
        if port.address == signal.address
        end
    end
end

can_add_donor
add_donor

end # module end
