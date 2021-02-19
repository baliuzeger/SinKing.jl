module IZNeuron

struct IZStates{T <: AbstractFloat}
    iz_u::T
    iz_v::T
    idle_end::Union{Nothing, T}
end

struct IZParams{T <: AbstractFloat}
    a::T
    b::T
    c::T
    d::T
    tau_refraction::T
end

end
