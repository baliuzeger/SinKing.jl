module SinKing

include("./types.jl")

include("./signals")

module AgentParts
include("./agent_parts/iz_neuron.jl")
include("./agent_parts/conductance_injection.jl")
include("./agent_parts/markram_transmitter.jl")
end

module Agents
include(".agents/iz_cond_mrkrm.jl")
end

struct LIFNeuron
end

# function simple_modify_fn(agent: Agent, states)
#     agent.states = states
# end


end # module
