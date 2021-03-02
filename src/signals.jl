module Signals

# abstract type TimedSingal end

# function take_due_signals{T}(t, acceptor::Acceptor{T})
#     keep, take = [], []
#     for x in acceptor.signals
#         if x.t <= t
#             push!(take, x)
#         else
#             push!(keep, x)
#         end
#     end
#     acceptor.stack = keep
#     return take
# end

# struct TimedDelta
#     t::AbstractFloat
#     delta::AbstractFloat
# end

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

## let agent be pure data without functions / methods., remove Donor / Acceptor.

# struct Donor
#     set # fn for dependency injection of putter & taker.
#     address
#     put # send signal to acceptor side
# end

# struct Acceptor{T}
#     set
#     address
#     take # take signals into stack.
#     stack::Vector{T}
# end

end # Module end
