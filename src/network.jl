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
    agent::Agent
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

function gen_all_q(nw::Dict{String, Population{T, V}}, t::V) where{T <: Unsigned, V <: AbstractFloat}
    reduce((q, pair) -> merge(q,
                              reduce((q2, pair2) -> merge(q2,
                                                          Dict{Address{T}, V}([
                                                              Address(pair[1], pair2[1]) => t
                                                          ])),
                                     pair[2].agents;
                                     init=Dict{Address{T}, V}([]))),
           nw;
           init=Dict{Address{T}, V}([]))
end

function simulate(total_t::T,
                  dt::T,
                  network::Dict{String, Population{U, T}},
                  current_q::Dict{Address{U}, T},
                  recording_agents::Vector{Address{U}}) where {T <: AbstractFloat, U <: Unsigned}

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
        t_str = @printf("t: %.1f.", t) # print time.

        processes = Dict{Address{U}, Task}([])
        next_q = Set{Address{U}}([])

        # store record here
        for adrs in recording_agents
            for (k, v) in state_dict(get_agent(network, adrs))
                df[index, col_name(adrs, k)] = v
            end
        end

        function push_task(address::Address)
            push!(next_q, address)
        end

        function run_process(address::Address{U}, fn)
            if haskey(processes, address) && ! istaskdone(processes[address])
                wait(processes[address])
            end
            processes[address] = @task fn()
            schedule(processes[address])
        end
        
        function update_agent(address::Address, updates::AgentUpdates)
            run_process(address, () -> update(get_agent(network, adrs), updates))
        end

        function accept_signal(address::Address, signal::Signal)
            @async run_process(address, () -> accept(get_agent(network, adrs), signal))
        end
        
        for (adrs, work_t) in current_q
            if work_t <= zero(T)
                act(adrs,
                    get_agent(network ,adrs),
                    dt,
                    push_task, # (adress, next_t)
                    update_agent, # (address, update)
                    push_signal) # (adrs, signal)
            else
                next_q[adrs] = work_t - dt
            end
        end

        current_q = next_q
            println(
                "Network simulate ending. t: $(t_str), current_q: $(current_q)."
            )

        t += dt
        index += 1
    end
    df
end


end # Module end
