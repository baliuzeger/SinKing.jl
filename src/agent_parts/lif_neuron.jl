module LIFNeuron

struct LIFStates{T <: AbstractFloat}
    v::T
    idle_end::Union{Nothing, T}
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    tau_leak::T
    tau_refraction::T
end

function evolve(t, dt, states::LIFStates, params::LIFParams, inject_fn, updater, fire_fn, task_fn)
    if isnothing(states.idle_end) || states.idle_end <= t
        i_syn, delta_v = inject_fn()
        new_v = dt * (i_syn + params.v_steady - states.v) / params.tau_leak
    else
    end
end

end # module end
