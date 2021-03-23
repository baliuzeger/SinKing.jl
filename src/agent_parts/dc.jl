module DC
export DCPort, gen_dc_updates
using ...Network
using ...Signals

struct DCPort{T <: AbstractFloat}
    address::Address
    current::T
    stack::Vector{TimedDC{T}}
end

function gen_dc_updates(ports::Vector{DCPort{T}}) where{T <: AbstractFloat}
    reduce(ports; init=(zero(T), Vector{DCPort{T, U}}(undef, 0))) do acc, port
        keep, take = take_due_signals(port.stack)
        last_t_dc = reduce((acc2, x2) -> acc2.t < x2.t ? x2 : acc2,
                           take;
                           init=TimedDC(t - dt, port.current))
        (acc[1] + last_t_dc.current, [acc[2]..., DCPort(port.address, last_t_dc.current, keep)])
    end
end # return (i_syn, updates.ports_dc) for DC acceptor.

end # module end
