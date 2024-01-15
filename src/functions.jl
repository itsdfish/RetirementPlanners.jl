"""
    simulate!(calc::AbstractCalculator, logger::AbstractLogger, n_reps; kwargs...)

# Arguments 

- `calc::AbstractCalculator`: an abstract calculator object 
- `logger::AbstractLogger`: an object for storing variables of the simulation
- `n_reps`: the number of times to repeat the Monte Carlo simulation

# Keywords 

- `kwargs...`: optional keyword arguments passed to `update!`
"""
function simulate!(calc::AbstractCalculator, logger::AbstractLogger, n_reps; kwargs...)
    for rep ∈ 1:n_reps 
        calc.rep = rep
        _simulate!(calc, logger; kwargs...)
    end
    return nothing
end

function _simulate!(calc::AbstractCalculator, logger::AbstractLogger; kwargs...)
    (;Δt,) = calc
    calc.state.net_worth = calc.start_amount
    for (s,t) ∈ enumerate(get_times(calc))
        calc.time_step = s
        update!(calc, logger, t; kwargs...)
    end
    return nothing 
end 

"""
    update!(calc::AbstractCalculator, logger::AbstractLogger, t; 
            kw_withdraw=(), kw_invest=(), kw_inflation=(), 
            kw_interest=(), kw_net_worth=(), kw_log=())
        
Performs an update on each time step by calling the following functions defined in `calc`:

- `withdraw!`: withdraw money
- `invest!`: invest money
- `update_inflation!`: compute inflation
- `update_interest!`: compute interest 
- `update_net_worth!`: compute net worth for the time step 
- `log!`: log desired variables 

Each function except `log!` has the signature `my_func(calc, t; kwargs...)`. The function `log!` has the signature 
`log!(calc, logger; kwargs...)`. 

# Arguments 

- `calc::AbstractCalculator`: an abstract calculator object 
- `t`: time in years 

# Keywords 

- `kw_withdraw = ()`: optional keyword arguments passed to `withdraw!`
- `kw_invest = ()`: optional keyword arguments passed to `invest!`
- `kw_inflation = ()`: optional keyword arguments passed to `update_inflation!`
- `kw_interest = ()`: optional keyword arguments passed to `update_interest!` 
- `kw_net_worth = ()`: optional keyword arguments passed to `update_net_worth!`
- `kw_log = ()`: optional keyword arguments passed to `log!`
"""
function update!(calc::AbstractCalculator, logger::AbstractLogger, t; 
        kw_withdraw=(), kw_invest=(), kw_inflation=(), 
        kw_interest=(), kw_net_worth=(), kw_log=())
    calc.withdraw!(calc, t; kw_withdraw...)
    calc.invest!(calc, t; kw_invest...) 
    calc.update_inflation!(calc, t; kw_inflation...) 
    calc.update_interest!(calc, t; kw_interest...) 
    calc.update_net_worth!(calc, t; kw_net_worth...)
    calc.log!(calc, logger; kw_log...)
    return nothing 
end 

get_times(calc::AbstractCalculator) = calc.Δt:calc.Δt:calc.n_years