module Signals

using ..Network
using ..Types
export take_due_signals, name_t_delta_v, connect,
    TimedDeltaV, TimedExctDeltaCond, TimedInhbtDeltaCond, TimedMarkram,
    add_acceptor, add_donor, can_add_acceptor, can_add_donor

abstract type TimedSignal <: Signal end

function take_due_signals(t, signals::Vector{TimedSignal})
    keep, take = [], []
    for x in signals
        if x.t <= t
            push!(take, x)
        else
            push!(keep, x)
        end
    end
    acceptor.stack = keep
    return keeo, take
end

struct TimedMarkram <: Signal
    t::AbstractFloat
    delta::AbstractFloat
end

struct TimedExctDeltaCond <: Signal
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedInhbtDeltaCond <: Signal
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedDeltaCond <: Signal
    t::AbstractFloat
    delta_cond::AbstractFloat
end

const name_t_delta_v = "TimedDeltaV"

struct TimedDeltaV <: Signal
    t::AbstractFloat
    delta_v::AbstractFloat
end

function can_add_acceptor end
function can_add_donor end
function add_acceptor end
function add_donor end

function connect(network::Dict{String, Population{U, T}},
                 signal_name::String,
                 donor_address::Address,
                 acceptor_address::Address) where {T <: AbstractFloat, U <: Unsigned}
    dnr = get_agent(network, donor_address)
    acptr = get_agent(network, acceptor_address)
    if can_add_acceptor(dnr, signal_name) && can_add_donor(acptr, signal_name)
        add_acceptor(dnr, acceptor_address, signal_name)
        add_donor(acptr, donor_address, signal_name)
    else
        error(
            "connect failed. Donor: $donor_address; acceptor: $acceptor_address; signal_name: $signal_name"
        )
    end
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








