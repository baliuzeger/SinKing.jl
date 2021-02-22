module MarkramTransmitter

struct MarkramStates{T <: AbstractFloat}
    exct_r::T
    exct_w::T
    inhbt_r::T
    inhbt_w::T
end

struct Markramparams{T <: AbstractFloat}
    exct_d::T
    exct_f::T
    exct_u::T
    inhbt_d::T
    inhbt_f::T
    inhbt_u::T
end

struct fire(t, dt)
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
end
