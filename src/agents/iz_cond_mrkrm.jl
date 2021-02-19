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

end
