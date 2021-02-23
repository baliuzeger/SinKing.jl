module LIFSimple

struct LIFSimpleAgent
    states::LIFStates
    params::LIFParams
    donors_simple::Vector{Donor}
    acceptors_t_delta_v::Vector{Acceptor{TimedDelta}}
end

function act(agent::LIFSimpleAgent, t, st, task_handler)

    function inject_fn()
        agent.acceptors_t_delta_v.take(t)
        return reduce((acc, x) -> acc + x.delta_v,
                      vcat(map(accptr -> take_due_signals(t, accptr),
                               agent.acceptors_t_delta_v)),
                      0.)
    end

    function lif_update(states::LIFStates)
        agent.states = states
    end

    function fire_fn()
        foreach(dnr -> dnr.put(TimedDelta(t, 1.0)), agent.donors_simple)
    end

    function task_fn(next_t)
        put_task(next_t, (t, dt) -> act(agent, t, dt, task_handler))
    end
    
    evolve(t, dt, agent.states, agent.params, inject_fn, lif_update, fire_fn, task_fn)
end




end # module end
