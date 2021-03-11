module LIFSimple
using ...Types
using ...AgentParts.LIFNeuron
using ...Network
import ...Network: act, update, state_dict
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor

export LIFSimpleAgent, accept, LIFSimpleParams

struct LIFSimpleParams
    lif::LIFParams
    delta_v::AbstractFloat
end

mutable struct LIFSimpleAgent <: Agent
    # address::Address
    states::LIFStates
    params::LIFSimpleParams
    acceptors_t_delta_v::Vector{Address} # agents that accept from self.
    donors_t_delta_v::Vector{Address} # agents that donate to self.
    stack_t_delta_v::Vector{TimedDeltaV}
end

LIFSimpleAgent(states::LIFStates, params::LIFSimpleParams) = LIFSimpleAgent(states, params, [], [], [])

function update(agent::LIFSimpleAgent, states::LIFStates)
    agent.states = states
end

function act(address::Address,
             agent::LIFSimpleAgent,
             t::T,
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat}

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

    update_agent(address, new_states)

    push_task(address, next_t)
    if fired
        signal = TimedDeltaV(next_t, agent.params.delta_v)
        for adrs in agent.acceptors_t_delta_v
            push_task(adrs, next_t)
            push_signal(adrs, signal)
        end
    end
end

function accept(agent::LIFSimpleAgent, signal::TimedDeltaV)
    push!(agent.stack_t_delta_v, signal)
end

function can_add_donor(agent::LIFSimpleAgent, signal_name::String)
    if signal_name == name_t_delta_v
        return true
    else
        return false
    end
end

function can_add_acceptor(agent::LIFSimpleAgent, signal_name::String)
    if signal_name == name_t_delta_v
        return true
    else
        return false
    end
end

function add_donor(agent::LIFSimpleAgent, signal_name::String, address::Address)
    if signal_name == name_t_delta_v
        push!(agent.donors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name donors!")
    end
    
end

function add_acceptor(agent::LIFSimpleAgent, signal_name::String, address::Address)
    if signal_name == name_t_delta_v
        push!(agent.acceptors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name acceptors!")
    end
end

function state_dict(agent::LIFSimpleAgent)
    return Dict(["v" => agent.states.v,
                 "refractory" => isnothing(agent.states.refractory_end) ? 0 : 1])
end


end # module end
