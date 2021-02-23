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

next step: make synapses. how to deal with passive connections?

the handler of signals should be produced by dependency-injection before each execution. before an execution, the network remember the connections without pre-defined handlers of signals. let vectors of donors and acceptors take setter functions that can perofrm dependency-injection on executions. a setter function set the sognal handlers of both connecting sides.

# function simple_modify_fn(agent: Agent, states)
#     agent.states = states
# end


end # module
