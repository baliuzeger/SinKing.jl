module IZNeuron

struct IZStates{T <: AbstractFloat}
    iz_u::T
    iz_v::T
    idle_end::Union{Nothing, T}
end

struct IZParams{T <: AbstractFloat}
    a::T
    b::T
    c::T
    d::T
    tau_refraction::T
end

function evolve(t, dt, states::IZStates, params::IZParams, states_upd, task_handler, inject_fn)
    if isnothing(states.idle_end) || states.idle_end <= t
        delta_exct, delta_inhbt, delta_v = inject_fn()
        i_syn, delta_v = inject_fn()

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
