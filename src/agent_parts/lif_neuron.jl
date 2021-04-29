module LIFNeuron
export LIFStates, LIFParams, evolve
using ...Signals
using Printf

mutable struct LIFStates{T <: AbstractFloat}
    v::T
    tau_refractory::T
    dc::T
    v_equilibrium::T
end

function gen_v_eqlbrm(dc::T, tau_refractory::T, v_steady::T) where {T <: AbstractFloat}
    dc * tau_refractory + v_steady
end

function LIFStates{T}(v::T, tau_refractory::T, dc::T, v_steady::T) where {T <: AbstractFloat}
    LIFStates(v, tau_refractory, dc, gen_v_eqlbrm(dc, tau_refractory, v_steady))
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    v_reset::T
    tau_leak::T
    tau_refractory::T
    lazy_threshold::T
end

function udpate_dc(states::LIFStates{T},
                   params::LIFParams{T}
                   instruction::DCInstruction{T}) where {T <: AbstractFloat}
    states.dc = states.dc - instruction.previous + instruction.new
    states.v_equilibrium = gen_v_eqlbrm(states.dc, params.tau_refractory, params.v_steady)
end

# return (evolved::Bool, fired::Bool, states::LIFStates)
function evolve(dt::T,
                states::LIFStates,
                params::LIFParams,
                get_delta_v, # () -> delta_v then reset sum_delta_v
                update, # udpate LIF states
                fire_fn, # trigger actions of fire.
                trigger_self) where {T <: AbstractFloat} # trigger self for next step.

    if states.tau_refractory <= zero(T)
        delta_v = get_delta_v()
        new_v = states.v + dt * ((states.v_equilibrium - states.v) / params.tau_leak) + delta_v
        if new_v >= 30.0
            fire_fn()
            update(LIFStates(params.v_reset, params.tau_refractory, states.dc, states.v_equilibrium))
            trigger_self()
        else
            update(LIFStates(new_v, zero(T), states.dc, states.v_equilibrium))
            if abs(new_v - states.v_equilibrium) > params.lazy_threshold
                trigger_self()
            end
        end
    else
        update(LIFStates(states.v, states.tau_refractory - dt, states.dc, states.v_equilibrium))
        trigger_self()
    end
end

end # module end
