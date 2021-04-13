module DC
export DCPort, gen_dc_updates
using ...Network
using ...Signals

struct DCPort{T <: AbstractFloat}
    address::Address
    current::T # value of the current from the port now.
    stack::Vector{TimedDC{T}} # accepted instructions of pairs of start-time and current.
end

function gen_dc_updates(t::T, dt::T, ports::Vector{DCPort{T}}) where{T <: AbstractFloat}
    reduce(ports; init=(zero(T), Vector{DCPort{T}}(undef, 0))) do acc, port
        keep, take = take_due_signals(t, port.stack)
        #println("take: $(take).")
        last_t_dc = reduce((acc2, x2) -> acc2.t <= x2.t ? x2 : acc2,
                           take;
                           init=TimedDC(t - dt, port.current))
        #println("last_t_dc: $(last_t_dc)")
        (acc[1] + last_t_dc.current, [acc[2]..., DCPort(port.address, last_t_dc.current, keep)])
    end
end # return (i_syn, updates.ports_dc) for DC acceptor.

end # module end
