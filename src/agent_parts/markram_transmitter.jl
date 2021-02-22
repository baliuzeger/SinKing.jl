module MarkramTransmitter

struct MarkramStates{T <: AbstractFloat}
    exct_r::T
    exct_w::T
    inhbt_r::T
    inhbt_w::T
end

struct Markramparams{T <: AbstractFloat}
    exct_d::T
    exct_f::T
    exct_u::T
    inhbt_d::T
    inhbt_f::T
    inhbt_u::T
end

struct fire(t, dt, states, params, updater, exct_donors, inhbt_donors)
    rw_exct = states.exct_r * states.exct_w
    rw_inhbt = states.inhbt_r * states.inhbt_w
    
    updater(dt * (1 - states.exct_r) / params.exct_d - rw_exct,
            dt * (params.exct_u - states.exct_w) / params.exct_f + params.exct_u * (1 - states.exct_w),
            dt * (1 - states.inhbt_r) / params.inhbt_d - rw_inhbt,
            dt * (params.inhbt_u - states.inhbt_w) / params.inhbt_f + params.inhbt_u * (1 - states.inhbt_w))
    
    
    for dnr in agent.donors
        x =1
    end
end
