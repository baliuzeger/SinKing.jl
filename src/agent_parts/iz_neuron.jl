module IZNeuron

struct IZStates{T <: AbstractFloat}
    iz_u::T
    iz_v::T
    idle_end::Union{Nothing, T}
end

end
