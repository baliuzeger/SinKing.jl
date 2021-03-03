using Sinking.Types

module LIFSimple

struct LIFSimpleParams
    lif::LIFParams
    delta_v::AbstractFloat
end

struct LIFSimpleAgent
    # address::Address
    states::LIFStates
    params::LIFSimpleParams
    acceptors_t_delta_v::Vector{Address} # agents that accept from self.
    donors_t_delta_v::Vector{Address} # agents that donate to self.
    stack_t_delta_v::Vector{TimedDeltaV}
end

function act(address::Address, agent::LIFSimpleAgent, t, dt, put_task, update_agent)

    new_states = agent.states
    new_params = agent.params
    new_stack_t_delta_v = agent.stack_t_delta_v
    
    function inject_fn()
        new_stack_t_delta_v, signals = take_due_signals(agent.stack_t_delta_v)
        if ! isnothing(agent.states.lif.idle_end)
            signals = filter(s -> s.t >= agent.states.lif.idle_end, signals)
        end
        return (0, reduce((acc, x) -> acc + x.delta_v, signals, 0.)) # (i_syn, delta_v)
    end

    function lif_update(states::LIFStates)
        new_states = states
    end

    function fire_fn()
        foreach(dnr -> dnr.put(TimedDelta(t, 1.0)), agent.donors_simple)
        for dnr in agent.donors_simple
            dnr.put(TimedDelta(t, agent.params.delta_v))
            put_task(t + dt, dnr.address)
        end
    end
    
    evolve(t,
           dt,
           agent.states,
           agent.params.lif,
           inject_fn,
           lif_update,
           fire_fn,
           t -> put_task(t, agent.Address))

    update_agent(address, LIFSimpleAgent(new_states,
                                         new_params,
                                         agent.acceptors_t_delta_v,
                                         agent.donors_t_delta_v
                                         new_stack_t_delta_v))
end

function 

end # module end
