module DC
export DCPort
using ...Network
using ...Signals

struct DCPort{T <: AbstractFloat, U <: Unsigned}
    address::Address
    current::T
    stack::Vector{TimedAdrsDC{T, U}}
end



end # module end
