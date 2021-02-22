module MarkramTransmitter

struct MarkramStates{T <: AbstractFloat}
    r::T
    w::T
end

struct Markramparams{T <: AbstractFloat}
    d::T
    f::T
    u::T
end

struct fire(t, dt, states, params, updater, donors)
    rw = states.r * states.w
    
    updater(dt * (1 - states.r) / params.d - rw_exct,
            dt * (params.u - states.w) / params.f + params.u * (1 - states.w))

    for dnr in donors
        push_signal(dnr, TimedDeltaCond(t, rw))
    end
end