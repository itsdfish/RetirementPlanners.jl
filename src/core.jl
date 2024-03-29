"""
    simulate!(
        model::AbstractModel,
        logger::AbstractLogger,
        n_reps;
        kwargs...
    )

Simulate the a retirement scenario a specified number of times. 

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `logger::AbstractLogger`: an object for storing variables of the simulation
- `n_reps`: the number of times to repeat the Monte Carlo simulation

# Keywords 

- `kwargs...`: optional keyword arguments passed to `update!`
"""
function simulate!(
    model::AbstractModel,
    logger::AbstractLogger,
    n_reps;
    kwargs...
)
    for rep ∈ 1:n_reps
        _simulate!(model, logger, rep; kwargs...)
    end
    return nothing
end

function _simulate!(model::AbstractModel, logger::AbstractLogger, rep; kwargs...)
    (; Δt,) = model
    reset!(model)
    for (s, t) ∈ enumerate(get_times(model))
        update!(model, logger, s, rep, t; kwargs...)
    end
    return nothing
end

"""
    update!(
        model::AbstractModel,
        logger::AbstractLogger,
        step,
        rep,
        t; 
        kw_income=(),
        kw_withdraw=(),
        kw_invest=(),
        kw_inflation=(),
        kw_interest=(),
        kw_net_worth=(),
        kw_log=()
    )
            
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
function update!(
    model::AbstractModel,
    logger::AbstractLogger,
    step,
    rep,
    t;
    kw_income = (),
    kw_withdraw = (),
    kw_invest = (),
    kw_inflation = (),
    kw_interest = (),
    kw_net_worth = (),
    kw_log = ()
)
    model.update_income!(model, t; kw_income...)
    model.invest!(model, t; kw_invest...)
    model.withdraw!(model, t; kw_withdraw...)
    model.update_inflation!(model, t; kw_inflation...)
    model.update_interest!(model, t; kw_interest...)
    model.update_net_worth!(model, t; kw_net_worth...)
    model.log!(model, logger, step, rep; kw_log...)
    return nothing
end

"""
    get_times(model::AbstractModel)

Returns the time steps used in the simulation. 

# Arguments

- `model::AbstractModel`: an abstract Model object 
"""
function get_times(model::AbstractModel)
    (; start_age, Δt, duration) = model
    return (start_age + Δt):Δt:(start_age + duration)
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

"""
    is_event_time(model::AbstractModel, t, rate)

Indicate whether it is time for a periodic event to occur.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time (or age) in years
- `rate`: the interval between repeating events measured in years 
"""
function is_event_time(model::AbstractModel, t, rate)
    start_time = model.start_age
    return mod(t - start_time, rate) ≈ 0
end
