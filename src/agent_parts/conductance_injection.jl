module ConductanceInjection
export ConductanceStates, ConductanceParams, gen_syn_current

struct ConductanceStates{T <: AbstractFloat}
    g_ampa::T
    g_nmda::T
    g_gaba_a::T
    g_gaba_b::T
end

struct ConductanceParams{T <: AbstractFloat}
    tau_ampa::T
    tau_nmda::T
    tau_gaba_a::T
    tau_gaba_b::T
end

function gen_syn_current(dt,
                         delta_exct,
                         delta_inhbt,
                         states::ConductanceStates,
                         params::ConductanceParams,
                         state_v::AbstractFloat,
                         updater)

    states = ConductanceStates(agent.states.g_ampa * (1 - dt / agent.params.tau_ampa) + delta_exct,
                               agent.states.g_nmda * (1 - dt / agent.params.tau_nmda) + delta_exct,
                               agent.states.g_gaba_a * (1 - dt / agent.params.tau_gaba_a) + delta_inhbt,
                               agent.states.g_gaba_b * (1 - dt / agent.params.tau_gaba_b) + delta_inhbt)
    updater(states)
    return - (stts.g_ampa * state_v +
              stts.g_nmda * state_v * ((state_v + 80) / 60)^2 / (1 + ((state_v + 80) / 60)^2) +
              stts.g_gaba_a * (state_v + 70) + stts.g_gaba_b(state_v + 90))

end

end # Module end
