module AsyncHandler

struct AsyncPorcStates{U <: Unsigned}
    handling_agents::Dict{Address{U}, Task}
    act_queue::Vector{Any}
end

function init_proc()
    Dict{Address{U}, Task}([])
end

function run_process(proc_states::Dict{Address{U}, Task}, address::Address{U}, fn)
    if haskey(proc_states, address) && ! istaskdone(proc_states[address])
        println("wait for existing process.")
        wait(proc_states[address])
    end
    proc_states[address] = @task fn()
    schedule(proc_states[address])
end

# need handle race too!!
function gen_trigger(proc_states::Dict{Address{U}, Task}, next_q::Set{Address{U}})
    function trigger(address::Address)
        println("trigger $(adrs)!!")
        push!(next_q, address)
        println(next_q)
    end
end

function gen_push_signal(proc_states::Dict{Address{U}, Task}, network::Dict{String, Population{U, T}})
    function push_signal(address::Address, signal::Signal)
        println("simultae push_signal!!")
        @async run_process(proc_states, address, () -> accept(get_agent(network, adrs), signal))
    end
end

function gen_exec_proc(proc_states::Dict{Address{U}, Task})
    function exec_proc(current_q::Set{Address{U}},
                       network::Dict{String, Population{U, T}},
                       trigger,
                       push_signal)
        step_proc = @task begin
            for adrs in current_q
                @async run_process(adrs,
                                   act(adrs,
                                       get_agent(network ,adrs),
                                       dt,
                                       trigger, # (adress)
                                       push_signal)) # (adrs, signal)
            end
        end
        schedule(step_proc)
        wait(step_proc)
    end
end # module end
