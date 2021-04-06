module DCSource
export DCSourceAgent
using ...Types
using ...Network
import ...Network: act, update, state_dict, accept
using ...Signals
import ...Signals: add_acceptor, add_donor, can_add_acceptor, can_add_donor, accept

mutable struct DCSourceAgent{T <: AbstractFloat, U <: Unsigned} <: Agent
    current::T
    acceptors_t_adrs_dc::Vector{Address{U}}
    stack_t_dc::Vector{TimedDC{T}}
end

function DCSourceAgent{T, U}(current::T) where {T <: AbstractFloat, U <: Unsigned}
    DCSourceAgent{T, U}(current, [], [])
    # DCSourceAgent{T, U}(current,
    #                     Vector{Address{U}}(undef, 0),
    #                     Vector{TimedDC{T}}(undef, 0))
end

struct DCSourceUpdates{T <: AbstractFloat} <: AgentUpdates
    current::T
    stack_t_dc::Vector{TimedDC{T}}
end

function update(agent::DCSourceAgent{T, U},
                updates::DCSourceUpdates) where {T <: AbstractFloat, U <: Unsigned}
    agent.current = updates.current
    agent.stack_t_dc = updates.stack_t_dc
end

state_dict(agent::DCSourceAgent) = Dict(["current" => agent.current])

function act(address::Address{U},
             agent::DCSourceAgent{T, U},
             dt::T,
             push_task,
             update_agent,
             push_signal) where {T <: AbstractFloat, U <: Unsigned}

    new_current = agent.current
    new_stack_t_dc, due_stack = take_due_signals(dt, agent.stack_t_dc)
    
    if length(due_stack) > 0 # update current by the latest TimedDC
        # println("t = $(t)")
        # println("DCSourceAgent due_stack > 0!")
        # println(agent.acceptors_t_adrs_dc)
        signal_upd = reduce((acc, x) -> x.t > acc.t ? x : acc, due_stack; init=due_stack[1])
        new_current = signal_upd.current
        tadc = TimedAdrsDC(signal_upd.t, signal_upd.current, address)
        #println(tadc)
        for adrs in agent.acceptors_t_adrs_dc
            #println("donate to $(adrs)")
            push_task(adrs, signal_upd.t)
            push_signal(adrs, tadc)
        end
    end

    if length(new_stack_t_dc) > 0 # push task for the next update
        next_t_dc = reduce((acc, x) -> x.t < acc.t ? x : acc, new_stack_t_dc; init=new_stack_t_dc[1])
        push_task(address, next_t_dc.t - dt)
    end

    update_agent(address, DCSourceUpdates(new_current, new_stack_t_dc))
end

function can_add_acceptor(agent::DCSourceAgent{T, U},
                          signal_name::String) where {T <: AbstractFloat, U <: Unsigned}
    signal_name == name_t_adrs_dc ? true : false
end

function add_acceptor(agent::DCSourceAgent{T, U},
                      signal_name::String,
                      address::Address{U}) where{T <: AbstractFloat, U <: Unsigned}
    if can_add_acceptor(agent, signal_name)
        #println("push acceptor of DCSourceAgent!")
        push!(agent.acceptors_t_adrs_dc, address)
        #println(agent.acceptors_t_adrs_dc)
    else
        error("DCSourceAgent cannot add $signal_name acceptors!")        
    end
end

# function can_add_donor(agent::DCSourceAgent{T, U},
#                        signal_name::String) where {T <: AbstractFloat, U <: Unsigned}
#     false
# end

# function add_donor(agent::DCSourceAgent{T, U},
#                    signal_name::String,
#                    address::Address{U}) where {T <: AbstractFloat, U <: Unsigned}
#     error("DCSourceAgent cannot add $signal_name donors!")
# end

function accept(agent::DCSourceAgent{T, U}, signal::TimedDC{T}) where {T <: AbstractFloat, U <: Unsigned}
    push!(agent.stack_t_dc, signal)
end

end # module end
