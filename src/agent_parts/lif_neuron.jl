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

# return (fired::Bool, triggered::Bool, states::LIFStates) ?
function evolve(dt::T,
                states::LIFStates,
                params::LIFParams,
                delta_v::T) where {T <: AbstractFloat}
    if states.tau_refractory <= zero(T)
        new_v = states.v + dt * ((states.v_equilibrium - states.v) / params.tau_leak) + delta_v
        if new_v >= 30.0
            true, true, LIFStates(params.v_reset, params.tau_refractory, states.dc, states.v_equilibrium)
        else
            new_states = LIFStates(new_v, zero(T), states.dc, states.v_equilibrium)
            if abs(new_v - states.v_equilibrium) > params.lazy_threshold
                false, true, new_states
            else
                false, false, new_states
            end
        end
    else # in refractory period.
        false, true, LIFStates(states.v, states.tau_refractory - dt, states.dc, states.v_equilibrium)
    end    
end

end # module end
