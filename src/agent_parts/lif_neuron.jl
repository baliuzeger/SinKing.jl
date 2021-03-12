module LIFNeuron
export LIFStates, LIFParams, evolve

struct LIFStates{T <: AbstractFloat}
    v::T
    refractory_end::Union{Nothing, T}
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    v_reset::T
    tau_leak::T
    tau_refractory::T
    lazy_threshold::T
end

function evolve(t::T,
                dt::T,
                states::LIFStates,
                params::LIFParams,
                inject_fn, # trigger handling accepted signals & return injections
                update, # udpate LIF states
                fire_fn, # trigger actions of fire.
                push_task) where {T <: AbstractFloat} # push self's next task by next_t
    
    if isnothing(states.refractory_end) || states.refractory_end <= t
        i_syn, delta_v = inject_fn()
        new_v = states.v +  dt * (i_syn + (states.v - params.v_steady) / params.tau_leak) + delta_v
        if new_v >= 30.0
            fire_fn()
            refractory_end = t + params.tau_refractory
            update(LIFStates(params.v_reset, refractory_end))
            # push_task(refractory_end) # lazy!!!
        else
            update(LIFStates(new_v, nothing))
            if abs(new_v - params.v_steady) > params.lazy_threshold
                push_task(t + dt)
            end
        end
    end
end

end # module end
