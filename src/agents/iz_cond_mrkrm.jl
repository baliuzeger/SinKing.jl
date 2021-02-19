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
    donors::Vector{Donor}
    acceptors::Vector{Acceptor}
end

# accept(acceptor) return [] of msgs
function act(agent::IZCondMrkrmAgent, t, dt, task_handler)
    if isnothing(agent.states.idle_end) || agent.states.idle_end <= t
        delta_exct, delta_inhbt, delta_potential = reduce(
            acc, x -> (acc[1] + x[1], acc[2] + x[2], acc[3] + x[3]),
            vcat(accept(agent.acceptors)),
            (0., 0., 0.,)
        )
        
        agent.states = IZStates(agent.states.iz_u,
                                agent.states.iz_v,
                                agent.states.g_ampa * (1 - dt / agent.params.tau_ampa) + delta_exct,
                                agent.states.g_nmda * (1 - dt / agent.params.tau_nmda) + delta_exct,
                                agent.states.g_gaba_a * (1 - dt / agent.params.tau_gaba_a) + delta_inhbt,
                                agent.states.g_gaba_b * (1 - dt / agent.params.tau_gaba_b) + delta_inhbt,
                                agent.states.exct_mrkrm_r,
                                agent.states.exct_mrkrm_w,
                                agent.states.inhbt_mrkram_r,
                                agent.states.inhbt_mrkram_w,
                                nothing)

        stts = agent.states
        prms = agent.params
        i_syn = stts.g_ampa * stts.iz_v +
            stts.g_nmda * stts.iz_v * ((stts.iz_v + 80) / 60)^2 / (1 + ((stts.iz_v + 80) / 60)^2) +
            stts.g_gaba_a * (stts.iz_v + 70) + stts.g_gaba_b(stts.iz_v + 90)
        new_v = stts.iz_v + dt * (0.04 stts.iz_v^2 + 5 stts.iz_v + 140 - stts.iz_u - i_syn)
        new_u = stts.iz_u + dt * prms.iz_a (prms.iz_b * stts.iz_v - stts.iz_u)
        if new_v >= 30
            new_v = prms.iz_c
            new_u += prms.iz_d
            rw_exct = stts.exct_mrkrm_r * stts.exct_mrkrm_w
            rw_inhbt = stts.inhbt_mrkrm_r * stts.inhbt_mrkrm_w
            agent.states = IZStates(new_u,
                            new_v,
                            agent.states.g_ampa,
                            agent.states.g_nmdap,
                            agent.states.g_gaba_a,
                            agent.states.g_gaba_b,
                            agent.states.exct_mrkrm_r, # update
                            agent.states.exct_mrkrm_w,
                            agent.states.inhbt_mrkram_r,
                            agent.states.inhbt_mrkram_w,
                            t + tau_refraction)
            for dnr in agent.donors
                x =1
            end
            put_task(tak_handler,) # set as after idle time
        else
            put_task(tak_handler, t + dt)
        end
    end                 
end

end
