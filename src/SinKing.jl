module SinKing

include("./types.jl")
include("./network.jl")
include("./signals.jl")

module AgentParts
include("./agent_parts/iz_neuron.jl")
# include("./agent_parts/conductance_injection.jl")
# include("./agent_parts/markram_transmitter.jl")
include("./agent_parts/lif_neuron.jl")
include("./agent_parts/dc.jl")
end

module Agents
#include("./agents/iz_cond_mrkrm.jl")
include("./agents/lif_simple.jl")
include("./agents/dc_source.jl")
include("./agents/delayer.jl")
end

end # module
