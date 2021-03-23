module LIFSimple
export LIFSimpleAgent, accept, LIFSimpleParams
using ...Types
using ...AgentParts.LIFNeuron
using ...AgentParts.DC
using ...Network
import ...Network: act, update, state_dict
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

struct LIFSimpleParams{T <: AbstractFloat}
    lif::LIFParams{T}
    delta_v::T
end

mutable struct LIFSimpleAgent{T <: AbstractFloat, U <: Unsigned} <: Agent
    states::LIFStates{T}
    params::LIFSimpleParams{T}
    acceptors_t_delta_v::Vector{Address{U}} # agents that accept from self.
    donors_t_delta_v::Vector{Address{U}} # agents that donate to self.
    stack_t_delta_v::Vector{TimedDeltaV{T}}
    ports_dc::Vector{DCPort{T}}
end

function LIFSimpleAgent{T, U}(states::LIFStates{T},
                              params::LIFSimpleParams{T}) where {T <: AbstractFloat, U <: Unsigned}
    LIFSimpleAgent{T, U}(states, params, [], [], [], [])
    # LIFSimpleAgent{T, U}(states,
    #                      params,
    #                      Vector{Address{U}}(undef, 0),
    #                      Vector{Address{U}}(undef, 0),
    #                      Vector{TimedDeltaV{T}}(undef, 0),
    #                      [])
end


struct LIFSimpleUpdate{T <: AbstractFloat, U <: Unsigned} <: AgentUpdates
    states::LIFStates{T}
    stack_t_delta_v::Vector{TimedDeltaV{T}}
    ports_dc::Vector{DCPort{T}}
end

function update(agent::LIFSimpleAgent{T, U},
                update::LIFSimpleUpdate{T, U}) where {T <: AbstractFloat, U <: Unsigned}
    agent.states = update.states
    agent.stack_t_delta_v = update.stack_t_delta_v
    agent.ports_dc = updates.ports_dc
end

function act(address::Address,
             agent::LIFSimpleAgent{T, U},
             t::T,
             dt::T,
             push_task,
             update_agent,
             push_signal) where{T <: AbstractFloat, U <: Unsigned}

    updates = LIFSimpleUpdate(agent.states, agent.stack_t_delta_v, agent.ports_dc, agent.sum_current)
    fired = false
    next_t = nothing
    
    function inject_fn()
        i_syn, updates.ports_dc = gen_dc_updates(agent.ports_dc)
        
        updates.stack_t_delta_v, tdv_signals = take_due_signals(t, agent.stack_t_delta_v)
        if ! isnothing(agent.states.refractory_end) # at end of refractory
            signals = filter(s -> s.t >= agent.states.refractory_end, signals)
        end
        delta_v = reduce((acc, x) -> acc + x.delta_v, tdv_signals; init=0.0)

        (i_syn, delta_v) # (i_syn, delta_v)
    end

    function lif_update(states::LIFStates)
        updates.states = states
    end

    function fire_fn()
        fired = true
    end

    function lif_push_task(t)
        if isnothing(next_t)
            next_t = t
        else
            next_t = next_t < t ? next_t : t
        end
    end
    
    evolve(t,
           dt,
           agent.states,
           agent.params.lif,
           inject_fn,
           lif_update,
           fire_fn,
           lif_push_task)

    update_agent(address, updates)

    if ! isnothing(next_t)
        push_task(address, next_t)
    end
    if fired
        signal = TimedDeltaV(next_t, agent.params.delta_v)
        for adrs in agent.acceptors_t_delta_v
            push_task(adrs, next_t)
            push_signal(adrs, signal)
        end
    end
end

function accept(agent::LIFSimpleAgent{T, U}, signal::TimedDeltaV{T}) where{T <: AbstractFloat, U <: Unsigned}
    push!(agent.stack_t_delta_v, signal)
end

function accept(agent::LIFSimpleAgent{T, U},
                signal::TimedAdrsDC{T, U}) where{T <: AbstractFloat, U <: Unsigned}
    found_port = false
    for port in agent.ports_dc
        if port.address == signal.address
            push!(port.stack, TimedDC(signal.t, signal.current))
            found_port = true
        end
    end
    if ! found_port
        error(
            "LIFSimpleAgent accept $(name_t_adrs_dc) from unregistered donor $(signal.adress.population)-$(signal.adress.num)!"
        )
    end
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
            push!(agent.ports_dc, DCPort(address, 0.0, []))
        else
            error("Got unhandled signal_name on add_donor.")
        end
    else
        error("LIFSimpleAgent cannot add $signal_name for donor at $(address.population)-$(address.num)!")
    end
end

function can_add_acceptor(agent::LIFSimpleAgent{T, U},
                          signal_name::String) where{T <: AbstractFloat, U <: Unsigned}
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
          "refractory" => isnothing(agent.states.refractory_end) ? 0 : 1])
end

end # module end
