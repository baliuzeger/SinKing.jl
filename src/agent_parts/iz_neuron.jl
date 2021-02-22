module IZNeuron

struct IZStates{T <: AbstractFloat}
    iz_v::T
    iz_u::T
    idle_end::Union{Nothing, T}
end

struct IZParams{T <: AbstractFloat}
    a::T
    b::T
    c::T
    d::T
    tau_refraction::T
end

function evolve(t, dt, states::IZStates, params::IZParams, inject_fn, updater, fire_fn, task_fn)
    if isnothing(states.idle_end) || states.idle_end <= t
        i_syn, delta_v = inject_fn()
        new_v = states.iz_v + dt * (0.04 states.iz_v^2 + 5 states.iz_v + 140 - states.iz_u - i_syn) + delta_v
        new_u = states.iz_u + dt * params.iz_a (params.iz_b * states.iz_v - states.iz_u)
        
        if new_v >= 30
            new_v = params.iz_c
            new_u += params.iz_d
            fire_fn(t, dt)
            idle_end = t + params.tau_refraction
            updater(IZStates(new_v, new_u, idle_end))
            task_fn(idle_end)
            
        else
            updater(IZStates(new_v, new_u, nothing))
            task_fn(t + dt)
        end
    end
end

end # Module end
