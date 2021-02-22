module IZCondMarkram

struct IZCondMrkrmStates{T <: AbstractFloat} <: AgentStates{T}
    iz::IZStates{T}
    cond::ConductanceStates{T}
    mrkrm::MarkramStates{T}
end

struct IZCondMrkrmParams{T <: AbstractFloat} <: AgentStates{T}
    iz::IZParams
    cond::ConductanceParams
    mrkrm::Markramparams
end

struct IZCondMrkrmAgent{T <: AbstractFloat} <: Agent{IZStates{T}}
    states::IZCondMrkrmStates{T}
    params::IZCondMrkrmParams{T}
    donors_t_delta_v::Vector{DonorTimedDeltaV}
    donors_t_delta_g::Vector{DonorTimedDeltaCond}
    acceptors_t_delta_v::Vector{AcceptorTimedDeltaV}
    acceptors_t_exct_delta_g::Vector{AcceptorTimedExctDeltaCond}
    acceptors_t_inhbt_delta_g::Vector{AcceptorTimedInhbtDeltaCond}
end

# accept(acceptor) return [] of msgs
function act(agent::IZCondMrkrmAgent, t, dt, task_handler)

    function cond_updater(cond_states)
        agent.states.cond = cond_states
    end
    
    function inject_fn()
        delta_v = sum(vcat(accept(agent.acceptors_t_delta_v, t)))
        delta_exct = sum(vcat(accept(agent.acceptors_t_exct_delta_g, t)))
        delta_inhbt = sum(vcat(accept(agent.acceptors_t_inhbt_delta_g, t)))
        i_syn = gen_syn_current(
            dt, delta_exct, delta_inhbt, agent.states.cond, agent.params.cond, agent.state.iz.v, cond_updater
        )
        return (i_syn, delta_v)
    end

    function iz_updater(iz_states)
        agent.states.iz = iz_states
    end

    function fire_fn(t, dt)
        
    end
    
    evolve(t, dt, agent.states.iz, agent.params.iz, inject_fn, iz_updater, fire_fn, task_fn)
    
end

end
