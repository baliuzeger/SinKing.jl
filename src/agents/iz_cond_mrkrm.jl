module IZCondMarkram

struct IZCondMrkrmStates{T <: AbstractFloat} <: AgentStates{T}
    iz::IZStates{T}
    cond::ConductanceStates{T}
    mrkrm::MarkramStates{T}
end

struct IZCondMrkrmParams{T <: AbstractFloat} <: AgentStates{T}
    iz::IZParams
    cond::ConductanceParams
    mrkrm::Markramparams
end

struct IZCondMrkrmAgent{T <: AbstractFloat} <: Agent{IZStates{T}}
    states::IZCondMrkrmStates{T}
    params::IZCondMrkrmParams{T}
    donors::Vector{Donor}
    acceptors::Vector{Acceptor}
end

# accept(acceptor) return [] of msgs
function act(agent::IZCondMrkrmAgent, t, dt, task_handler)
    inject_fn = () -> reduce(
        acc, x -> (acc[1] + x[1], acc[2] + x[2], acc[3] + x[3]),
        vcat(accept(agent.acceptors)),
        (0., 0., 0.,)
    )
end

end
