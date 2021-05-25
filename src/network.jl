module Network
using Printf
export Address, Point3D, Seat, Population, async_simulate, push_seat, get_agent, Agent,
    gen_all_q, Signal, accept, serial_simulate, NullNote
using DataFrames
using Dates
using Logging

abstract type Agent end
#abstract type AgentUpdates end
abstract type Signal end
abstract type AgentNote end

struct Address{T <: Unsigned}
    population::String
    num::T
end

struct NullNote <: AgentNote end

struct Point3D{T <: AbstractFloat} <: AgentNote
    x1::T
    x2::T
    x3::T
end

Point3D{T}() where {T <: AbstractFloat} = Point3D{T}(zero(T), zero(T), zero(T))

struct Seat
    note::AgentNote
    agent::Agent # use abstract type but noet generic type for get_agent.
end

Seat(agent::Agent) = Seat(NullNote(), agent)

mutable struct Population{T <: Unsigned}
    max::T
    seats::Dict{T, Seat}

    Population{T}() where{T <: Unsigned} = new(0, Dict([]))
end

function push_seat(ppln::Population{T}, seats::Vararg{Seat}) where {T <: Unsigned}
    for s in seats
        ppln.max += 1
        ppln.seats[ppln.max] = s
    end
end

function get_agent(network::Dict{String, Population{T}},
                   address::Address) where{T <: Unsigned}
    return network[address.population].seats[address.num].agent
end

function act end
#function update end # (address, AgentUpdates) -> ()
function state_dict end # () -> Dict
function accept end # (agent, signal)

function gen_all_q(nw::Dict{String, Population{T}}) where {T <: Unsigned}
    # reduce((q, ppltn_pair) -> union(q,
    #                                 reduce((q2, seat_pair) -> union(q2,
    #                                                                 Set{Address{T}}([
    #                                                                     Address(ppltn_pair[1], seat_pair[1])
    #                                                                 ])),
    #                                        ppltn_pair[2].seats;
    #                                        init=Set{Address{T}}([]))),
    #        nw;
    #        init=Set{Address{T}}([]))
    
    reduce(nw; init=Set{Address{T}}([])) do q, ppltn_pair
        union(q,
              reduce((q2, seat_pair) -> union(q2,
                                              Set{Address{T}}([
                                                  Address(ppltn_pair[1], seat_pair[1])
                                              ])),
                     ppltn_pair[2].seats;
                     init=Set{Address{T}}([])))
    end
end

function gen_all_lk(nw::Dict{String, Population{T}}) where {T <: Unsigned}
    reduce(nw; init=Dict{Address{T}, ReentrantLock}([])) do dict, ppltn_pair
        merge(dict,
              reduce((dict2, seat_pair) -> merge(dict2,
                                                 Dict{Address{T}, ReentrantLock}([
                                                     (Address(ppltn_pair[1], seat_pair[1]), ReentrantLock())
                                                 ])),
                     ppltn_pair[2].seats;
                     init=Dict{Address{T}, ReentrantLock}([])))
    end
end

function col_name(adrs::Address, state_name::String)
    "$(adrs.population)_$(adrs.num)_$(state_name)"
end

function init_df{V}(network::Dict{String, Population{T}},
                    recording_agents::Set{Address{T}},
                    total_steps::T) where {T <: Unsigned, V <: AbstractFloat}
    col_names = reduce((acc, adrs) -> [acc;
                                       reduce((acc, x) -> [acc; [col_name(adrs, x[1])]],
                                              state_dict(get_agent(network, adrs)),
                                              init = [])],
                       recording_agents;
                       init = ["t"])
    df = DataFrame()
    for name in col_names
        df[!, name] = repeat([zero(V)], total_steps)
    end
    df
end

function async_simulate(total_t::T,
                        dt::T,
                        network::Dict{String, Population{U}},
                        current_q::Set{Address{U}},
                        recording_agents::Set{Address{U}}) where {T <: AbstractFloat, U <: Unsigned}

    total_steps = UInt(fld(total_t, dt)) + 1
    df = init_df{T}(network, recording_agents, total_steps)
    t = zero(T)
    index = 1

    start_t = now()
    while index <= total_steps
        #t_str = @printf("t: %.1f.", t) # print time.

        df[index, "t"] = t
        for adrs in recording_agents
            for (k, v) in state_dict(get_agent(network, adrs))
                println("k: $(col_name(adrs, k)), v: $(v).")
                df[index, col_name(adrs, k)] = v
            end
        end
        
        agent_proccesses = Dict{Address{U}, Task}([])
        agent_lks = gen_all_lk(network)
        next_q_lk = ReentrantLock()
        next_q = Set{Address{U}}([])
        accepting_signals_lk = ReentrantLock()
        accepting_signals = Vector{Tuple{Signal, Vector{Address{U}}}}([])
        
        act_tasks = reduce(current_q; init=Vector{Task}([])) do acc, adrs
            task = @task begin
                # use update to let act be puer function?
                triggered_agents, generated_signals = act(adrs,
                                                          get_agent(network ,adrs),
                                                          dt)
                lock(next_q_lk) do
                    union!(next_q, triggered_agents)
                end
                lock(accepting_signals_lk) do
                    append!(accepting_signals, generated_signals)
                end
            end
            schedule(task)
            [acc..., task]
        end
        foreach((task) -> wait(task), act_tasks)

        accept_tasks = map(accepting_signals) do signal_acceptors
            task = @task begin
                for adrs in signal_acceptors[2]
                    lock(agent_lks[adrs]) do
                        accept(get_agent(network, adrs), signal_acceptors[1])
                    end
                end
            end
            schedule(task)
            task            
        end
        foreach((task) -> wait(task), accept_tasks)
                    
        current_q = next_q
        t += dt
        index += 1
    end
    println(now() - start_t)
    df
end

function serial_simulate(total_t::T,
                         dt::T,
                         network::Dict{String, Population{U}},
                         current_q::Set{Address{U}},
                         recording_agents::Set{Address{U}}) where {T <: AbstractFloat, U <: Unsigned}
    
    total_steps = UInt(fld(total_t, dt)) + 1
    df = init_df{T}(network, recording_agents, total_steps)
    t = zero(T)
    index = UInt(1)

    start_t = now()
    while index <= total_steps
        #t_str = @printf("t: %.1f.", t) # print time.
        
        next_q = Set{Address{U}}([])
        push_q = Vector{Tuple{Signal, Vector{Address{U}}}}([])

        df[index, "t"] = t
        for adrs in recording_agents
            for (k, v) in state_dict(get_agent(network, adrs))
                df[index, col_name(adrs, k)] = v
            end
        end

        for adrs in current_q
            triggered_agents, signals_acceptors = act(adrs,
                                                      get_agent(network ,adrs),
                                                      dt)
            union!(next_q, triggered_agents)
            append!(push_q, signals_acceptors)
        end

        for st in push_q
            for adrs in st[2]
                accept(get_agent(network, adrs), st[1])
            end
        end
        
        current_q = next_q
        t += dt
        index += 1
    end
    println(now() - start_t)
    df
end


end # Module end
