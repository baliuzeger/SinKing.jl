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
