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

function v_eqlbrm(dc::T, tau_refractory::T, v_steady::T) where {T <: AbstractFloat}
    dc * tau_refractory + v_steady
end

function LIFStates{T}(v::T, tau_refractory::T, dc::T, v_steady::T) where {T <: AbstractFloat}
    LIFStates(v, tau_refractory, dc, v_eqlbrm(dc, tau_refractory, v_steady))
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    v_reset::T
    tau_leak::T
    tau_refractory::T
    lazy_threshold::T
end

function udpate_dc(states::LIFStates{T},
                   tau_refractory::T,
                   v_steady::T,
                   instruction::DCInstruction{T}) where {T <: AbstractFloat}
    states.dc = states.dc - instruction.previous + instruction.new
    states.v_equilibrium = v_eqlbrm(states.dc, tau_refractory, v_steady)
end

function evolve(dt::T,
                states::LIFStates,
                params::LIFParams,
                inject_fn, # trigger handling accepted signals & return injections
                update, # udpate LIF states
                fire_fn, # trigger actions of fire.
                push_task) where {T <: AbstractFloat} # push self's next task by next_t

    if states.tau_refractory <= zero(T)
        i_syn, delta_v = inject_fn()
        new_v = states.v + dt * (i_syn + (params.v_steady - states.v) / params.tau_leak) + delta_v
        if new_v >= 30.0
            fire_fn()
            update(LIFStates(params.v_reset, params.tau_refractory))
            push_task(dt)
        else
            update(LIFStates(new_v, zero(T)))
            if i_syn !== zero(T) || abs(new_v - params.v_steady) > params.lazy_threshold
                push_task(dt)
            end
        end
    else
        update(LIFStates(states.v, states.tau_refractory - dt))
        push_task(dt)
    end
end

end # module end
