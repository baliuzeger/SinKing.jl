module IZNeuron

struct IZStates{T <: AbstractFloat}
    v::T
    u::T
    idle_end::Union{Nothing, T}
end

struct IZParams{T <: AbstractFloat}
    a::T
    b::T
    c::T
    d::T
    tau_refraction::T
end

function evolve(t, dt, states::IZStates, params::IZParams, inject_fn, update, fire_fn, put_task)
    if isnothing(states.idle_end) || states.idle_end <= t
        i_syn, delta_v = inject_fn()
        new_v = states.v + dt * (0.04 states.v^2 + 5 states.v + 140 - states.u + i_syn) + delta_v
        new_u = states.u + dt * params.iz_a (params.iz_b * states.v - states.u)
        
        if new_v >= 30.0
            new_v = params.iz_c
            new_u += params.iz_d
            fire_fn(t, dt)
            idle_end = t + params.tau_refraction
            update(IZStates(new_v, new_u, idle_end))
            put_task(idle_end)
            
        else
            update(IZStates(new_v, new_u, nothing))
            put_task(t + dt)
        end
    end
end

end # Module end
