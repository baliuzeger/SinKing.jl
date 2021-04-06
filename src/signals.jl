module Signals

using ..Network
export take_due_signals, name_t_delta_v, connect, Signal,
    TimedDeltaV, TimedExctDeltaCond, TimedInhbtDeltaCond, TimedMarkram, TimedDC, name_t_dc,
    add_acceptor, add_donor, can_add_acceptor, can_add_donor, TimedAdrsDC, name_t_adrs_dc

abstract type TimedSignal <: Signal end
function after_t end

function take_due_signals(dt::T, signals::Vector{U}) where {T <: AbstractFloat, U <: TimedSignal}
    keep, take = Vector{U}(undef, 0), Vector{U}(undef, 0)
    for x in signals
        if x.t <= dt
            push!(take, x)
        else
            push!(keep, after_t(dt, x))
        end
    end
    return keep, take
end

struct TimedMarkram{T <: AbstractFloat} <: TimedSignal
    t::T
    delta::T
end

after_t(dt::T, s::TimedMarkram{T}) where {T <: AbstractFloat} = TimedMarkram(s.t - dt, s.delta)

struct TimedExctDeltaCond{T <: AbstractFloat} <: TimedSignal
    t::T
    delta_cond::T
end

struct TimedInhbtDeltaCond{T <: AbstractFloat} <: TimedSignal
    t::T
    delta_cond::T
end

struct TimedDeltaCond{T <: AbstractFloat} <: TimedSignal
    t::T
    delta_cond::T
end

const name_t_delta_v = "TimedDeltaV"
struct TimedDeltaV{T <: AbstractFloat} <: TimedSignal
    t::T
    delta_v::T
end

after_t(dt::T, s::TimedDeltaV{T}) where {T <: AbstractFloat} = (s.t - dt, s.delta_v)

const name_t_dc = "TimedDC"
struct TimedDC{T <: AbstractFloat} <: TimedSignal
    t::T # start time of the current
    current::T
end

after_t(dt::T, s::TimedDC{T}) where {T <: AbstractFloat} = (s.t - dt, s.current)

const name_t_adrs_dc = "TimedAdrsDC"
struct TimedAdrsDC{T <: AbstractFloat, U <: Unsigned} <: TimedSignal
    t::T # start time of the current
    current::T
    source::Address{U}
end

after_t(dt::T, s::TimedAdrsDC{T}) where {T <: AbstractFloat} = (s.t - dt, s.current, s.source)

function can_add_acceptor end # (agent, signal_name) -> bool
function can_add_donor end
function add_acceptor end # (agent, signal_name, acptr_address) -> ()
function add_donor end # (agent, signal_name, dnr_address) -> ()

function connect(network::Dict{String, Population{U, T}},
                 signal_name::String,
                 donor_address::Address,
                 acceptor_address::Address) where {T <: AbstractFloat, U <: Unsigned}
    dnr = get_agent(network, donor_address)
    acptr = get_agent(network, acceptor_address)
    if can_add_acceptor(dnr, signal_name) && can_add_donor(acptr, signal_name)
        add_acceptor(dnr, signal_name, acceptor_address)
        add_donor(acptr, signal_name, donor_address)
    else
        error(
            "connect failed. Donor: $donor_address; acceptor: $acceptor_address; signal_name: $signal_name"
        )
    end
end

end # Module end








