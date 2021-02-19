module IZCondMarkram

struct IZCondMrkrmStates{T <: AbstractFloat} <: AgentStates{T}
    iz::IZStates{T}
    cond::ConductanceStates{T}
    mrkrm::MarkramStates{T}
end

end
