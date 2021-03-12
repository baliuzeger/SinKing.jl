using ...Network

module DC

struct DCPort{T <: AbstractFloat}
    address::Address
    current::T
end

end # module end
