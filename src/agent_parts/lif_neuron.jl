module LIFNeuron
export LIFStates, LIFParams, evolve
using Printf

struct LIFStates{T <: AbstractFloat}
    v::T
    t_refractory::T
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    v_reset::T
    tau_leak::T
    tau_refractory::T
    lazy_threshold::T
end

function evolve(dt::T,
                states::LIFStates,
                params::LIFParams,
                inject_fn, # trigger handling accepted signals & return injections
                update, # udpate LIF states
                fire_fn, # trigger actions of fire.
                push_task) where {T <: AbstractFloat} # push self's next task by next_t

    if states.t_refractory <= zero(T)
        i_syn, delta_v = inject_fn()
        new_v = states.v + dt * (i_syn + (params.v_steady - states.v) / params.tau_leak) + delta_v
        if new_v >= 30.0
            fire_fn()
            update(LIFStates(params.v_reset, params.tau_refractory))
            push_task(dt)
        else
            update(LIFStates(new_v, zero(T)))
            if i_syn !== zero(T) || abs(new_v - params.v_steady) > params.lazy_threshold
                push_task(dt)
            end
        end
    else
        update(LIFStates(states.v, states.t_refractory - dt))
        push_task(dt)
    end
end

end # module end
