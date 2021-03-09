module IZCondMarkram
using ...AgentParts.IZNeuron
using ...AgentParts.ConductanceInjection
using ...AgentParts.MarkramTransmitter
using ...Types
using ...Network
using ...Signals

struct IZCondMrkrmStates{T <: AbstractFloat} # <: AgentStates{T}
    iz::IZStates{T}
    cond::ConductanceStates{T}
    mrkrm::MarkramStates{T}
end

struct IZCondMrkrmParams{T <: AbstractFloat}
    iz::IZParams
    cond::ConductanceParams
    mrkrm::Markramparams
    delta_v::AbstractFloat
end

struct IZCondMrkrmAgent{T <: AbstractFloat} <: Agent
    states::IZCondMrkrmStates{T}
    params::IZCondMrkrmParams{T}
    # donors_t_delta_v::Vector{DonorTimedDeltaV}
    # donors_t_delta_g::Vector{DonorTimedDeltaCond}
    acceptors_t_delta_v::Vector{Address}
    acceptors_mrkrm::Vector{Address}
    donors_t_delta_v::Vector{Address}
    stack_t_delta_v::Vector{TimedDeltaV}
    donors_t_exct_delta_g::Vector{Address}
    stack_t_exct_delta_g::Vector{TimedExctDeltaCond}
    donors_t_inhbt_delta_g::Vector{Address}
    stack_t_inhbt_delta_g::Vector{TimedInhbtDeltaCond}
end

# accept(acceptor) return [] of msgs
function act(agent::IZCondMrkrmAgent, t, dt, put_task)

    function cond_update(cond_states::ConductanceStates)
        agent.states.cond = cond_states
    end
    
    function inject_fn()
        agent.acceptors_t_delta_v.take(t)
        agent.acceptors_t_exct_delta_g.take(t)
        agent.acceptors_t_inhbt_delta_g.take(t)
        delta_v_signals = vcat(map(accptr -> take_due_signals(t, accptr),
                                   agent.acceptors_t_delta_v))
        delta_exct_signals = vcat(map(accptr -> take_due_signals(t, accptr),
                                      agent.acceptors_t_exct_delta_g))
        delta_inhbt_signals = vcat(map(accptr -> take_due_signals(t, accptr),
                                      agent.acceptors_t_inhbt_delta_g)) 

        if ! isnothing(agent.states.iz.idle_end)
            delta_v_signals = filter(s -> s.t >= agent.states.iz.idle_end, delta_v_signals)
            delta_exct_signals = filter(s -> s.t >= agent.states.iz.idle_end, delta_exct_signals)
            delta_inhbt_signals = filter(s -> s.t >= agent.states.iz.idle_end, delta_inhbt_signals)
        end
        
        delta_v = reduce((acc, x) -> acc + x.delta_v, delta_v_signals, 0.)
        delta_exct = reduce((acc, x) -> acc + x.delta_cond, delta_exct_signals, 0.)
        delta_inhbt = reduce((acc, x) -> acc + x.delta_cond, delta_inhbt_signals, 0.)
        
        i_syn = gen_syn_current(
            dt, delta_exct, delta_inhbt, agent.states.cond, agent.params.cond, agent.state.iz.v, cond_update
        )
        return (i_syn, delta_v)
    end

    function iz_update(iz_states::IZStates)
        agent.states.iz = iz_states
    end

    function mrkrm_update(mrkrm_states::MarkramStates)
        agent.states.mrkrm = mrkrm_states
    end

    function put_mrkrm_signal(signal::TimedMarkram)
        foreach(dnr -> dnr.put(signal), agent.acceptors_mrkrm)
    end
    
    function fire_fn(t, dt)
        fire(t, dt, agent.states.mrkrm, agent.params.mrkrm, mrkrm_update, put_mrkrm_signal)
        foreach(dnr -> put_task(t + dt, dnr.address), agent.donors_mrkrm)
        for dnr in agent.donors_simple
            dnr.put(TimedDelta(t, agent.params.delta_v))
            put_task(t + dt, dnr.address)
        end
    end
    
    evolve(t,
           dt,
           agent.states.iz,
           agent.params.iz,
           inject_fn,
           iz_update,
           fire_fn,
           t -> put_task(t, agent.Address))
    
end

end # Module end
