module IZNeuron
export IZStates, IZParams, evolve

struct IZStates{T <: AbstractFloat}
    v::T
    u::T
end

struct IZParams{T <: AbstractFloat}
    a::T
    b::T
    c::T
    d::T
    bc::T
    lazy_threshold::T

    IZParams(a, b, c, d, lazy_threshold) = new{T}(a, b, c, d, lazy_threshold, b * c)
end

function evolve(t, dt, states::IZStates, params::IZParams, inject_fn, update, fire_fn, put_task)

    i_syn, delta_v = inject_fn()
    new_v = states.v + dt * (0.04 * states.v^2 + 5 * states.v + 140 - states.u + i_syn) + delta_v
    new_u = states.u + dt * params.a * (params.b * states.v - states.u)
    
    if new_v >= 30.0
        new_v = params.c
        new_u += params.d
        fire_fn(t, dt)
    end

    update(IZStates(new_v, new_u))

    if abs(new_v - params.c) > params.lazy_threshold || abs(new_u - params.bc) > params.lazy_threshold
        put_task(t + dt)
    end

end

end # Module end
