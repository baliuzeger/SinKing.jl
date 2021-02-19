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

function evolve(agent::IZNeuron, dt, task_handler) # should extract the pure IZ model part from act
    
end

end
