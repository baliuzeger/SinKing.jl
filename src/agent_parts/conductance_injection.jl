module ConductanceInjection

struct ConductanceStates{T <: AbstractFloat}
    g_ampa::T
    g_nmda::T
    g_gaba_a::T
    g_gaba_b::T
end

end
