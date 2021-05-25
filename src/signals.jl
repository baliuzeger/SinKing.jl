module Signals

using ..Network
export take_due_signals, connect, Signal, add_acceptor, add_donor, can_add_acceptor, can_add_donor,
    name_back_spike, BackSpike, name_delta_v, DeltaV, name_dc_instruction, DCInstruction,
    name_new_dc, NewDC, ForwardSignal, BackwardSignal

abstract type ForwardSignal <: Signal end
abstract type BackwardSignal <: Signal end
function amplify end

# struct MarkramDelta{T <: AbstractFloat} <: ForwardSignal
#     delta::T
# end

# struct ExctDeltaCond{T <: AbstractFloat} <: ForwardSignal
#     delta_cond::T
# end

# struct InhbtDeltaCond{T <: AbstractFloat} <: ForwardSignal
#     delta_cond::T
# end

# struct DeltaCond{T <: AbstractFloat} <: ForwardSignal
#     delta_cond::T
# end

const name_delta_v = "DeltaV"
struct DeltaV{T <: AbstractFloat} <: ForwardSignal
    delta_v::T
end

amplify(s::DeltaV{T}, w::T) where {T <: AbstractFloat} = DeltaV(s.delta_v * w)

## state_dict is for recording states, not for network-serialization. temporarily commented.
#state_dict(s::DeltaV{T}) where {T <: AbstractFloat} = Dict(["delta_v" => s.delta_v])

const name_dc_instruction = "DCInstruction"
struct DCInstruction{T <: AbstractFloat} <: ForwardSignal
    previous::T
    new::T
end

amplify(s::DCInstruction{T}, w::T) where {T <: AbstractFloat} = DCInstruction(s.previous * w, s.new * w)

const name_new_dc = "NewDC"
struct NewDC{T <: AbstractFloat} <: ForwardSignal
    current::T
end


const name_back_spike = "BackSpike"
struct BackSpike <: BackwardSignal
end

## state_dict is for recording states, not for network-serialization. temporarily commented.
#state_dict(s::DCInstruction{T}) where {T <: AbstractFloat} = Dict(["precious" => s.previous, "new" => s.new])

function can_add_acceptor end # (agent, signal_name) -> bool
function can_add_donor end
function add_acceptor end # (agent, signal_name, acptr_address) -> ()
function add_donor end # (agent, signal_name, dnr_address) -> ()

function connect(network::Dict{String, Population{T}},
                 signal_name::String,
                 donor_address::Address,
                 acceptor_address::Address) where {T <: Unsigned}
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








