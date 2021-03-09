module SinKing

include("./types.jl")
include("./signals.jl")
include("./network.jl")

module AgentParts
include("./agent_parts/iz_neuron.jl")
include("./agent_parts/conductance_injection.jl")
include("./agent_parts/markram_transmitter.jl")
end

module Agents
include(".agents/iz_cond_mrkrm.jl")
include(".agents/lif_simple.jl")
end

end # module
