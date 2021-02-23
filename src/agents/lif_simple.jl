module LIFSimple

struct LIFSimpleParams
    lif::LIFParams
    delta_v::AbstractFloat
end

struct LIFSimpleAgent
    address::Address
    states::LIFStates
    params::LIFSimpleParams
    donors_simple::Vector{Donor}
    acceptors_t_delta_v::Vector{Acceptor{TimedDelta}}
end

function act(agent::LIFSimpleAgent, t, st, put_task)

    function inject_fn()
        agent.acceptors_t_delta_v.take(t)
        signals = vcat(map(accptr -> take_due_signals(t, accptr),
                           agent.acceptors_t_delta_v))
        if ! isnothing(agent.states.lif.idle_end)
            signals = filter(s -> s.t >= agent.states.lif.idle_end, signals)
        end
        return reduce((acc, x) -> acc + x.delta_v, signals, 0.)
    end

    function lif_update(states::LIFStates)
        agent.states = states
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
end

end # module end
