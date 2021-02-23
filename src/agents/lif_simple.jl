module LIFSimple

struct LIFSimpleAgent
    address::Address
    states::LIFStates
    params::LIFParams
    donors_simple::Vector{Donor}
    acceptors_t_delta_v::Vector{Acceptor{TimedDelta}}
end

function act(agent::LIFSimpleAgent, t, st, put_task)

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
        for dnr in agent.donors_simple
            dnr.put(TimedDelta(t, 1.0))
            put_task(t + dt, dnr.address)
        end
    end
    
    evolve(t,
           dt,
           agent.states,
           agent.params,
           inject_fn,
           lif_update,
           fire_fn,
           t -> put_task(t, agent.Address))
end

end # module end
