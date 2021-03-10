module Network
using ..Types
export Address, Point3D, Seat, Population, simulate, push_seat, get_agent

# struct Network
#     populations::Dict{string, Vector{Agent}}
#     # queue::Vector{(AbstractFloat, Address)} # (time, address)
# end

struct Address{T <: Unsigned}
    population::String
    num::T
end

struct Point3D{T <: AbstractFloat}
    x1::T
    x2::T
    x3::T
end

struct Seat{T <: AbstractFloat}
    position::Point3D{T}
    agent::Agent
end

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
function update end

function simulate(start_t::T,
                  end_t::T,
                  dt::T,
                  network::Dict{String, Population{U, T}},
                  current_q::Dict{Address{U}, T}) where {T <: AbstractFloat, U <: Unsigned}
    
    t = start_t
    while t < end_t
        state_updates::Dict{Address, Any} = Dict([])
        accepted_signals::Dict{Address, Vector{Signal}} = Dict([])
        next_q = Dict([])

        function push_task(address, next_t)
            next_q[address] = next_t
        end

        function update_agent(address, states)
            state_updates[address] = states
        end

        function push_signal(address, signal)
            if haskey(accepted_signals, address)
                push!(accepted_signals[address], signal)
            else
                accepted_signals[address] = [signal]
            end
        end
        
        for (adrs, work_t) in current_q
            if work_t <= t
                act(adrs,
                    get_agent(network ,adrs),
                    t,
                    dt,
                    push_task,
                    update_agent,
                    push_signal)
            else
                next_q[adrs] = work_t
            end
        end

        current_q = next_q
        for (adrs, states) in state_updates
            update(get_agent(network, adrs), states)
        end
        for (adrs, signals) in accepted_signals
            foreach(s -> accept(get_agent(network, adrs), s), signals)
        end
        t += dt
    end
    
end


end # Module end
