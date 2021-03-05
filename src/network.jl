using Sinking.Types

module Network

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

struct Seat{T <: AbstractFloat, U <: Agent}
    position::Position{T}
    agent::Agent
end

struct Population{T <: Unsigned, V<: AbstractFloat, U <: Agent}
    max::T
    agents::Dict{T, Seat{V, U}}

    Population(agents::Dict{U, Seat{V, U}}) = new(0, agents)
end

function run(start_t::T,
             end_t::T,
             dt::T,
             network::Dict{String, Population{U, T, Agent}},
             current_q::Dict{Address, T}) where {T <: AbstractFloat, U <: Unsigned}
    
    t = start_t
    while t < end_t
        state_updates::Dict{Address, T} = Dict([])
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
                    network[adrs.population][adrs.num],
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
        for (adrs, update) in updates
        end
        t += dt
    end
    
end


end # Module end
