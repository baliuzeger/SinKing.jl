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
        put_signal(dnr.putter, TimedDeltaCond(t, rw)) # fix here to match Donor!!!
    end
end
