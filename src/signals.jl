module Signals

abstract type TimedSingal end

function take_due_signals{T}(t, acceptor::Acceptor{T})
    keep, take = [], []
    for x in acceptor.signals
        if x.t <= t
            push!(take, x)
        else
            push!(keep, x)
        end
    end
    acceptor.stack = keep
    return take
end

struct TimedExctDeltaCond
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedInhbtDeltaCond
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedDeltaCond
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedDeltaV
    t::AbstractFloat
    delta_v::AbstractFloat
end

struct Donor
    setter # fn for dependency injection of putter & taker
    putter # send signal to acceptor side
end

struct Acceptor{T}
    setter
    taker # take signals into stack.
    stack::Vector{T}
end

end # Module end
