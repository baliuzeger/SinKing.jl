module Network
using Printf
export Address, Point3D, Seat, Population, simulate, push_seat, get_agent, Agent, AgentUpdates,
    gen_all_q, Signal, accept
using DataFrames

abstract type Agent end
abstract type AgentUpdates end
abstract type Signal end

struct Address{T <: Unsigned}
    population::String
    num::T
end

struct Point3D{T <: AbstractFloat}
    x1::T
    x2::T
    x3::T
end

Point3D{T}() where {T <: AbstractFloat} = Point3D{T}(zero(T), zero(T), zero(T))

struct Seat{T <: AbstractFloat}
    position::Point3D{T}
    agent::Agent # use abstract type but noet generic type for get_agent.
end

Seat{T}(agent::Agent) where {T <: AbstractFloat} = Seat(Point3D{T}(zero(T), zero(T), zero(T)), agent)

mutable struct Population{T <: Unsigned, V <: AbstractFloat}
    max::T
    agents::Dict{T, Seat{V}}

    Population{T, V}() where{T <: Unsigned, V <: AbstractFloat} = new(0, Dict([]))
end

function push_seat(ppln::Population{T, V}, seat::Seat{V}) where {T <: Unsigned, V<: AbstractFloat}
    ppln.max += 1
    ppln.agents[ppln.max] = seat
end

function get_agent(network::Dict{String, Population{T, V}},
                   address::Address) where{T <: Unsigned, V <: AbstractFloat}
    return network[address.population].agents[address.num].agent
end

function act end
function update end # (address, AgentUpdates) -> ()
function state_dict end # () -> Dict
function accept end # (agent, signal)

function gen_all_q(nw::Dict{String, Population{T, V}}) where {T <: Unsigned, V <: AbstractFloat}
    # reduce((q, ppltn_pair) -> union(q,
    #                                 reduce((q2, seat_pair) -> union(q2,
    #                                                                 Set{Address{T}}([
    #                                                                     Address(ppltn_pair[1], seat_pair[1])
    #                                                                 ])),
    #                                        ppltn_pair[2].agents;
    #                                        init=Set{Address{T}}([]))),
    #        nw;
    #        init=Set{Address{T}}([]))
    
    reduce(nw; init=Set{Address{T}}([])) do q, ppltn_pair
        union(q,
              reduce((q2, seat_pair) -> union(q2,
                                              Set{Address{T}}([
                                                  Address(ppltn_pair[1], seat_pair[1])
                                              ])),
                     ppltn_pair[2].agents;
                     init=Set{Address{T}}([])))
    end
end

# function gen_trigger end # (next_q) -> (address) -> trigger
# function gen_push_signal end # (network) -> (address, signal) -> push_signal
# abstract type ProcStates end
# function init_proc end
# function exec_proc end

function simulate(total_t::T,
                  dt::T,
                  network::Dict{String, Population{U, T}},
                  current_q::Set{Address{U}},
                  recording_agents::Vector{Address{U}},
                  init_proc) where {T <: AbstractFloat, U <: Unsigned}

    total_steps = Int(total_t ÷ dt + 1)
    col_name = (adrs::Address, state_name::String) -> "$(adrs.population)_$(adrs.num)_$(state_name)"
    col_names = reduce((acc, adrs) -> [acc;
                                       reduce((acc, x) -> [acc; [col_name(adrs, x[1])]],
                                              state_dict(get_agent(network, adrs)),
                                              init = [])],
                       recording_agents;
                       init = [])
    df = DataFrame()
    for name in col_names
        df[!, name] = repeat([zero(T)], total_steps)
    end
    
    t = zero(T)
    index = 1
    while index <= total_steps
        proc_states = init_proc()
        next_q = Set{Address{U}}([])

        # store record here
        for adrs in recording_agents
            for (k, v) in state_dict(get_agent(network, adrs))
                df[index, col_name(adrs, k)] = v
            end
        end

        trigger = gen_trigger(proc_states, next_q)
        push_signal = gen_push_signal(proc_states, network)
        exec_proc = gen_exec_proc(proc_states)

        for adrs in current_q
            taks_task(proc_states,
                      adrs,
                      () -> act(adrs,
                                get_agent(network ,adrs),
                                dt,
                                trigger, # (address) -> trigger address
                                push_signal)) # (adrs, signal) -> push signal to adrs
        end

        exec_proc(current_q, network, trigger, push_signal)
        
        current_q = next_q
        t += dt
        index += 1
    end
    df
end


end # Module end
