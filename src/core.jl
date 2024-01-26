"""
    simulate!(model::AbstractModel, logger::AbstractLogger, n_reps; kwargs...)

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `logger::AbstractLogger`: an object for storing variables of the simulation
- `n_reps`: the number of times to repeat the Monte Carlo simulation

# Keywords 

- `kwargs...`: optional keyword arguments passed to `update!`
"""
function simulate!(model::AbstractModel, n_reps; kwargs...)
    data = setup_data(model, n_reps)
    model.step_count = 1
    for rep ∈ 1:n_reps 
        _simulate!(model, data, rep; kwargs...)
    end
    return data
end

function _simulate!(model::AbstractModel, data, rep; kwargs...)
    (;Δt,) = model
    reset!(model)
    for (s,t) ∈ enumerate(get_times(model))
        update!(model, data, s, rep, t; kwargs...)
        model.step_count += 1
    end
    return nothing 
end 

function setup_data(model::AbstractModel, n_reps)
    times = get_times(model)
    n_steps = length(times)
    fields = fieldnames(typeof(model.state))
    n_cols = length(fields)
    df = DataFrame(fill(0.0, n_reps * n_steps, n_cols), [fields...,])
    df.rep = repeat(1:n_reps, inner=n_steps)
    df.time = repeat(times, n_reps)
    return df
end

"""
    update!(model::AbstractModel, logger::AbstractLogger, step, rep, t; 
            kw_income=(), kw_withdraw=(), kw_invest=(), kw_inflation=(), 
            kw_interest=(), kw_net_worth=(), kw_log=())
        
Performs an update on each time step by calling the following functions defined in `model`:

- `update_income!`: update sources of income, such as social security, pension etc. 
- `withdraw!`: withdraw money
- `invest!`: invest money
- `update_inflation!`: compute inflation
- `update_interest!`: compute interest 
- `update_net_worth!`: compute net worth for the time step 
- `log!`: log desired variables 

Each function except `log!` has the signature `my_func(model, t; kwargs...)`. The function `log!` has the signature 
`log!(model, logger, step, rep; kwargs...)`. 

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `rep::Int`: repetition count of simulation 
- `time_step::Int`: time step count of simulation 
- `t`: time in years 

# Keywords 

- `kw_income = ()`: optional keyword arguments passed to `update_income!`
- `kw_withdraw = ()`: optional keyword arguments passed to `withdraw!`
- `kw_invest = ()`: optional keyword arguments passed to `invest!`
- `kw_inflation = ()`: optional keyword arguments passed to `update_inflation!`
- `kw_interest = ()`: optional keyword arguments passed to `update_interest!` 
- `kw_net_worth = ()`: optional keyword arguments passed to `update_net_worth!`
- `kw_log = ()`: optional keyword arguments passed to `log!`
"""
function update!(model::AbstractModel, logger, step, rep, t; 
        kw_income=(), kw_withdraw=(), kw_invest=(), kw_inflation=(),
        kw_interest=(), kw_net_worth=(), kw_log=())
    model.update_income!(model, t; kw_income...)
    model.invest!(model, t; kw_invest...) 
    model.withdraw!(model, t; kw_withdraw...)
    model.update_inflation!(model, t; kw_inflation...) 
    model.update_interest!(model, t; kw_interest...) 
    model.update_net_worth!(model, t; kw_net_worth...)
    model.log!(model, logger, t, rep; kw_log...)
    return nothing 
end 

"""
    get_times(model::AbstractModel)

Returns the time steps used in the simulation. 

# Arguments

- `model::AbstractModel`: an abstract Model object 
"""
function get_times(model::AbstractModel)
    (;start_age,Δt,duration) = model 
    return (start_age+Δt):Δt:(start_age+duration)
end

"""
    reset!(model::AbstractModel)

Sets all values of the state object to zero, except net worth, which is set to `start_amount`.

# Arguments

- `model::AbstractModel`: an abstract Model object 
"""
function reset!(model::AbstractModel)
    model.state = State()
    model.state.net_worth = model.start_amount
    return nothing
end