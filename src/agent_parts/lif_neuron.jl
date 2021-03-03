module LIFNeuron

struct LIFStates{T <: AbstractFloat}
    v::T
    refraction_end::Union{Nothing, T}
end

struct LIFParams{T <: AbstractFloat}
    v_steady::T
    v_reset::T
    tau_leak::T
    tau_refraction::T
    lazy_threshold::T
end

function evolve(t, dt, states::LIFStates, params::LIFParams, inject_fn, update, fire_fn, push_task)
    if isnothing(states.refraction_end) || states.refraction_end <= t
        i_syn, delta_v = inject_fn()
        new_v = dt * (i_syn + params.v_steady - states.v) / params.tau_leak + delta_v
        if new_v >= 30.0
            fire_fn(t, dt)
            refraction_end = t + params.tau_refraction
            update(LIFStates(params.v_reset, refraction_end))
            # push_task(refraction_end) # lazy!!!
        else
            udpate(LIFStates(new_v, nothing))
            if abs(new_v - v_steady) > params.lazy_threshold
                push_task(t + dt)
            end
        end
    end
end

end # module end
