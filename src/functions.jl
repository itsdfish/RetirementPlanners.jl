"""
    simulate!(model::AbstractModel, logger::AbstractLogger, n_reps; kwargs...)

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `logger::AbstractLogger`: an object for storing variables of the simulation
- `n_reps`: the number of times to repeat the Monte Carlo simulation

# Keywords 

- `kwargs...`: optional keyword arguments passed to `update!`
"""
function simulate!(model::AbstractModel, logger::AbstractLogger, n_reps; kwargs...)
    for rep ∈ 1:n_reps 
        model.rep = rep
        _simulate!(model, logger; kwargs...)
    end
    return nothing
end

function _simulate!(model::AbstractModel, logger::AbstractLogger; kwargs...)
    (;Δt,) = model
    model.state.net_worth = model.start_amount
    for (s,t) ∈ enumerate(get_times(model))
        model.time_step = s
        update!(model, logger, t; kwargs...)
    end
    return nothing 
end 

"""
    update!(model::AbstractModel, logger::AbstractLogger, t; 
            kw_withdraw=(), kw_invest=(), kw_inflation=(), 
            kw_interest=(), kw_net_worth=(), kw_log=())
        
Performs an update on each time step by calling the following functions defined in `model`:

- `withdraw!`: withdraw money
- `invest!`: invest money
- `update_inflation!`: compute inflation
- `update_interest!`: compute interest 
- `update_net_worth!`: compute net worth for the time step 
- `log!`: log desired variables 

Each function except `log!` has the signature `my_func(model, t; kwargs...)`. The function `log!` has the signature 
`log!(model, logger; kwargs...)`. 

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `t`: time in years 

# Keywords 

- `kw_withdraw = ()`: optional keyword arguments passed to `withdraw!`
- `kw_invest = ()`: optional keyword arguments passed to `invest!`
- `kw_inflation = ()`: optional keyword arguments passed to `update_inflation!`
- `kw_interest = ()`: optional keyword arguments passed to `update_interest!` 
- `kw_net_worth = ()`: optional keyword arguments passed to `update_net_worth!`
- `kw_log = ()`: optional keyword arguments passed to `log!`
"""
function update!(model::AbstractModel, logger::AbstractLogger, t; 
        kw_withdraw=(), kw_invest=(), kw_inflation=(), 
        kw_interest=(), kw_net_worth=(), kw_log=())
    model.withdraw!(model, t; kw_withdraw...)
    model.invest!(model, t; kw_invest...) 
    model.update_inflation!(model, t; kw_inflation...) 
    model.update_interest!(model, t; kw_interest...) 
    model.update_net_worth!(model, t; kw_net_worth...)
    model.log!(model, logger; kw_log...)
    return nothing 
end 

get_times(model::AbstractModel) = model.Δt:model.Δt:model.n_years