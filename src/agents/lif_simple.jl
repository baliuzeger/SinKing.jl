module LIFSimple
export LIFSimpleAgent, accept, LIFSimpleParams
using Printf
using ...Types
using ...AgentParts.LIFNeuron
using ...AgentParts.DC
using ...Network
import ...Network: act, update, state_dict, accept
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

struct LIFSimpleParams{T <: AbstractFloat}
    lif::LIFParams{T}
    delta_v::T
end

struct LIFSimpleStates{T <: AbstractFloat}
    lif::LIFStates{T}
    sum_delta_v::T    
end

mutable struct LIFSimpleAgent{T <: AbstractFloat, U <: Unsigned} <: Agent
    states::LIFSimpleStates{T}
    params::LIFSimpleParams{T}
    acceptors_delta_v::Vector{Address{U}} # agents that accept from self.
    donors_delta_v::Vector{Address{U}} # agents that donate to self.
    donors_dc::Vector{Address{U}}
end

function LIFSimpleAgent{T, U}(states::LIFStates{T},
                              params::LIFSimpleParams{T}) where {T <: AbstractFloat, U <: Unsigned}
    LIFSimpleAgent{T, U}(states, params, [], [], [])
    # LIFSimpleAgent{T, U}(states,
    #                      params,
    #                      Vector{Address{U}}(undef, 0),
    #                      Vector{Address{U}}(undef, 0),
    #                      Vector{TimedDeltaV{T}}(undef, 0),
    #                      [])
end

function update(agent::LIFSimpleAgent{T, U},
                updates::LIFSimpleStates{T}) where {T <: AbstractFloat, U <: Unsigned}
    agent.states = updates
end

function act(address::Address, # self address.
             agent::LIFSimpleAgent{T, U},
             dt::T,
             trigger, # (address) -> trigger for next step
             push_signal) where{T <: AbstractFloat, U <: Unsigned}

    fired, triggered, new_lif_states = evolve(dt,
                                              agent.states.lif,
                                              agent.params.lif,
                                              agent.states.sum_delta_v)

    if fired
        signal = TimedDeltaV(zero(T), agent.params.delta_v)
        for adrs in agent.acceptors_t_delta_v
            trigger(adrs)
            push_signal(adrs, signal)
        end
    end

    if triggered
        trigger(address)
    end

    agent.states = LIFSimpleStates(new_lif_states, zero(T))
end

function accept(agent::LIFSimpleAgent{T, U}, signal::DeltaV{T}) where{T <: AbstractFloat, U <: Unsigned}
    agent.states.sum_delta_v += signal.delta_v
end

function accept(agent::LIFSimpleAgent{T, U},
                signal::DCInstruction{T}) where{T <: AbstractFloat, U <: Unsigned}
    update_dc(agent.states.lif, agent.params.lif, signal)
end

function can_add_donor(agent::LIFSimpleAgent{T, U},
                       signal_name::String) where{T <: AbstractFloat, U <: Unsigned}
    signal_name == name_t_delta_v || signal_name == name_t_adrs_dc
end

function add_donor(agent::LIFSimpleAgent{T, U},
                   signal_name::String,
                   address::Address{U}) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_donor(agent, signal_name)
        if signal_name == name_t_delta_v
            push!(agent.donors_t_delta_v, address)
        elseif signal_name == name_t_adrs_dc
            push!(agent.ports_dc, DCPort(address, zero(T), Vector{TimedDC{T}}(undef, 0)))
        else
            error("Got unhandled signal_name on add_donor.")
        end
    else
        error("LIFSimpleAgent cannot add $signal_name for donor at $(address.population)-$(address.num)!")
    end
end

function can_add_acceptor(agent::LIFSimpleAgent{T, U},
                          signal_name::String) where{T <: AbstractFloat, U <: Unsigned}
    #println("LIFSimple can_add_acceptor: $(signal_name) vs $(name_t_delta_v), $(signal_name == name_t_delta_v)")
    signal_name == name_t_delta_v
end

function add_acceptor(agent::LIFSimpleAgent{T, U},
                      signal_name::String,
                      address::Address{U}) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_acceptor(agent, signal_name)
        push!(agent.acceptors_t_delta_v, address)
    else
        error("LIFSimpleAgent cannot add $signal_name acceptors!")
    end
end

function state_dict(agent::LIFSimpleAgent{T, U}) where{T <: AbstractFloat, U <: Unsigned}
    Dict(["v" => agent.states.v,
          "t_refractory" => agent.states.t_refractory])
end

end # module end
