module Signals

using ..Network
using ..Types
export take_due_signals, name_t_delta_v, connect,
    TimedDeltaV, TimedExctDeltaCond, TimedInhbtDeltaCond, TimedMarkram,
    add_acceptor, add_donor, can_add_acceptor, can_add_donor

abstract type TimedSignal <: Signal end

function take_due_signals(t::T, signals::Vector{U}) where {T <: AbstractFloat, U <: TimedSignal}
    keep, take = [], []
    for x in signals
        if x.t <= t
            push!(take, x)
        else
            push!(keep, x)
        end
    end
    return keep, take
end

struct TimedMarkram <: TimedSignal
    t::AbstractFloat
    delta::AbstractFloat
end

struct TimedExctDeltaCond <: TimedSignal
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedInhbtDeltaCond <: TimedSignal
    t::AbstractFloat
    delta_cond::AbstractFloat
end

struct TimedDeltaCond <: TimedSignal
    t::AbstractFloat
    delta_cond::AbstractFloat
end

const name_t_delta_v = "TimedDeltaV"

struct TimedDeltaV <: TimedSignal
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

end # Module end








