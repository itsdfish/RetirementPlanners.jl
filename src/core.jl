"""
    simulate!(model::AbstractModel, logger::AbstractLogger, n_reps)

Simulate the a retirement scenario a specified number of times. 

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `logger::AbstractLogger`: an object for storing variables of the simulation
- `n_reps`: the number of times to repeat the Monte Carlo simulation
"""
function simulate!(model::AbstractModel, logger::AbstractLogger, n_reps)
    for rep ∈ 1:n_reps
        simulate_once!(model, logger, rep)
    end
    return nothing
end

function simulate_once!(model::AbstractModel, logger::AbstractLogger, rep)
    reset!(model)
    for t ∈ get_all_times(model) 
        update!(model, logger, rep, t)
    end
    return nothing
end

"""
    update!(model::AbstractModel, logger::AbstractLogger, step, rep, t)

Performs an update on each time step by calling the following functions defined in `model`:

- `update_inflation!`: compute inflation
- `update_market!`: compute interest 
- `invest!`: invest money
- `withdraw!`: withdraw money
- `update_income!`: update sources of income, such as social security, pension etc. 
- `update_investments!`: compute net worth for the time step 
- `log!`: log desired variables 

Each function except `log!` has the signature `my_func(model, t; kwargs...)`. The function `log!` has the signature 
`log!(model, logger, step, rep; kwargs...)`. 

# Arguments 

- `model::AbstractModel`: an abstract Model object 
- `rep::Int`: repetition count of simulation 
- `time_step::Int`: time step count of simulation 
- `t`: time in years 
"""
function update!(model::AbstractModel, logger::AbstractLogger, rep, t)
    _update!(model, logger, rep, t; model.config...)
    return nothing
end

"""
    _update!(
        model::AbstractModel,
        logger::AbstractLogger,
        step,
        rep,
        t;
        kw_income = (),
        kw_withdraw = (),
        kw_invest = (),
        kw_inflation = (),
        kw_market = (),
        kw_investments = (),
        kw_log = ()
    )
            
Performs an update on each time step by calling the following functions defined in `model`:

- `update_income!`: update sources of income, such as social security, pension etc. 
- `withdraw!`: withdraw money
- `invest!`: invest money
- `update_inflation!`: compute inflation
- `update_market!`: compute interest 
- `update_investments!`: compute net worth for the time step 
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
- `kw_market = ()`: optional keyword arguments passed to `update_market!` 
- `kw_investments = ()`: optional keyword arguments passed to `update_investments!`
- `kw_log = ()`: optional keyword arguments passed to `log!`
"""
function _update!(
    model::AbstractModel,
    logger::AbstractLogger,
    rep,
    t;
    kw_income = (),
    kw_withdraw = (),
    kw_invest = (),
    kw_inflation = (),
    kw_market = (),
    kw_investments = (),
    kw_log = ()
)
    model.update_inflation!(model, t; kw_inflation...)
    model.update_market!(model, t; kw_market...)
    model.invest!(model, t; kw_invest...)
    model.withdraw!(model, t; kw_withdraw...)
    model.update_income!(model, t; kw_income...)
    model.update_investments!(model, t; kw_investments...)
    model.log!(model, logger, rep, t; kw_log...)
    return nothing
end

"""
    get_times(model::AbstractModel)

Returns the time steps used in the simulation. 

# Arguments

- `model::AbstractModel`: an abstract Model object 
"""
get_times(model::AbstractModel) = model.log_times


function get_all_times(model::AbstractModel)
    (;start_age, Δt, duration) = model
    return get_all_times(start_age, Δt, duration)
end

function get_all_times(start_age, Δt, duration)
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

can_transact(source::AbstractTransaction, t; Δt = 0.0) =
    (source.start_age - Δt / 2 ≤ t) && (source.end_age + Δt / 2 ≥ t)
transact(::AbstractModel, source::AbstractTransaction{T, D}; _...) where {T, D <: Real} =
    source.amount

"""
    transact(
        model::AbstractModel,
        income::Transaction{T, D};
        t
    ) where {T, D <: Distribution}

Sample a amount from a specified distribution and execute a transaction. 

# Arguments

- `::AbstractModel`: unused model object 
- `investment::Transaction{T, D}`: a transaction object specifing an investment rule

# Keywords

- `t`: the current time
"""
function transact(
    ::AbstractModel,
    source::AbstractTransaction{T, D};
    _...
) where {T, D <: Distribution}
    return rand(source.amount)
end

"""
    transact(
        model::AbstractModel,
        income::Transaction{T, D};
        t
    ) where {T, D <: NominalAmount}

Execute a transaction using the nominal value of the transaction amount. 

# Arguments

- `::AbstractModel`: unused model object 
- `investment::Transaction{T, D}`: a transaction object specifing an investment rule

# Keywords

- `t`: the current time
"""
function transact(
    model::AbstractModel,
    income::Transaction{T, D};
    t
) where {T, D <: NominalAmount}
    income.amount.adjust ? nothing : (return income.amount.amount)
    (; Δt, state, start_age) = model
    (; amount) = income
    amount.amount = (start_age + Δt) ≈ t ? (amount.initial_amount) : amount.amount
    r = (1 + state.inflation_rate)^Δt
    amount.amount /= r
    return amount.amount
end
