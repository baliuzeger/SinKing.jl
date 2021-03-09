module LIFSimple
using ...Types
using ...AgentParts.LIFNeuron
using ...Network
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor

export LIFSimpleAgent, act, accept, LIFSimpleParams

struct LIFSimpleParams
    lif::LIFParams
    delta_v::AbstractFloat
end

struct LIFSimpleAgent <: Agent
    # address::Address
    states::LIFStates
    params::LIFSimpleParams
    acceptors_t_delta_v::Vector{Address} # agents that accept from self.
    donors_t_delta_v::Vector{Address} # agents that donate to self.
    stack_t_delta_v::Vector{TimedDeltaV}

    LIFSimpleAgent(states, params) = new(states, params, [], [], [])
end

function act(address::Address, agent::LIFSimpleAgent, t, dt, push_task, update_agent, push_signal)

    new_states = agent.states
    new_stack_t_delta_v = agent.stack_t_delta_v
    fired = false
    next_t = t + dt
    
    function inject_fn()
        new_stack_t_delta_v, signals = take_due_signals(agent.stack_t_delta_v)
        if ! isnothing(agent.states.lif.idle_end) # at end of refraction
            signals = filter(s -> s.t >= agent.states.lif.idle_end, signals)
        end
        return (0, reduce((acc, x) -> acc + x.delta_v, signals, 0.)) # (i_syn, delta_v)
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

    update_agent(address, LIFSimpleAgent(new_states,
                                         agent.params,
                                         agent.acceptors_t_delta_v,
                                         agent.donors_t_delta_v,
                                         new_stack_t_delta_v))

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

function update(agent::LIFSimpleAgent, states::LIFStates)
    agent.states = states
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

function add_donor(agent::LIFSimpleAgent, address::Address, signal_name)
    if signal_name == name_t_delta_v
        push!(agent.donors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name donors!")
    end
    
end

function add_acceptor(agent::LIFSimpleAgent, address::Address, signal_name)
    if signal_name == name_t_delta_v
        push!(agent.acceptors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name acceptors!")
    end
end


end # module end
