module LIFNeuron

struct LIFStates{T <: AbstractFloat}
    v::T
    idle_end::Union{Nothing, T}
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    v_reset::T
    tau_leak::T
    tau_refraction::T
end

function evolve(t, dt, states::LIFStates, params::LIFParams, inject_fn, update, fire_fn, task_fn)
    if isnothing(states.idle_end) || states.idle_end <= t
        i_syn, delta_v = inject_fn()
        new_v = dt * (i_syn + params.v_steady - states.v) / params.tau_leak + delta_v
        if new_v >= 30.0
            fire_fn(t, dt)
            idle_end = t + params.tau_refraction
            update(LIFStates(params.v_reset, idle_end))
            task_fn(idle_end)
        else
            udpate(LIFStates(new_u, nothing))
            task_fn(t + dt)
        end
    end
end

end # module end
