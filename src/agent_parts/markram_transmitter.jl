module MarkramTransmitter
export MarkramStates, Markramparams, fire

struct MarkramStates{T <: AbstractFloat}
    r::T
    w::T
end

struct Markramparams{T <: AbstractFloat}
    d::T
    f::T
    u::T
end

function fire(t, dt, states, params, updater, put_signal)
    rw = states.r * states.w
    updater(dt * (1 - states.r) / params.d - rw_exct,
            dt * (params.u - states.w) / params.f + params.u * (1 - states.w))
    put_signal(TimedDeltaCond(t, rw))
end

end # Module end
