"""
    AbstractState

An abstract type for tracking the state of the model during simulation.     
"""
abstract type AbstractState end

"""
    State <: AbstractState

Represents the state of the model, which is updated on each iteration. 

# Fields 

- `interest_rate::Float64`: interest rate of investment during the current time period 
- `inflation_rate::Float64`: the inflation rate during the current time period 
- `income_amount::Float64`: income during the current time period from various sources, e.g., social 
    security, pension, etc.
- `invest_amount::Float64`: the amount invested during the current time period 
- `withdraw_amount::Float64`: the amount deducted from investments during the current time period 
- `net_worth::Float64`: total value of the investment during the current time period 
"""
mutable struct State <: AbstractState
    interest_rate::Float64
    inflation_rate::Float64  
    income_amount::Float64
    invest_amount::Float64
    withdraw_amount::Float64
    net_worth::Float64
end

"""
    State(;
        interest_rate = 0.0, 
        inflation_rate = 0.0,
        income_amount = 0.0,
        invest_amount = 0.0,
        withdraw_amount = 0.0, 
        net_worth = 0.0
    )

Constructor for a state object, which represents the state of the model on each iteration. 

# Keywords

- `interest_rate::Float64`: interest rate of investment during the current time period 
- `inflation_rate::Float64`: the inflation rate during the current time period 
- `income_amount::Float64`: income during the current time period from various sources, e.g., social 
    security, pension, etc. 
- `invest_amount::Float64`: the amount invested during the current time period
- `withdraw_amount::Float64`: the amount deducted from investments during the current time period 
- `net_worth::Float64`: total value of the investment during the current time period 
"""
function State(;
        interest_rate = 0.0, 
        inflation_rate = 0.0, 
        income_amount = 0.0,
        invest_amount = 0.0,
        withdraw_amount = 0.0, 
        net_worth = 0.0
    )

    return State(
        interest_rate,
        inflation_rate,
        income_amount,
        invest_amount,
        withdraw_amount,
        net_worth
    )
end

"""
    AbstractLogger

An abstract type for recording the state of the model during simulation.     
"""
abstract type AbstractLogger end 

"""
    Logger{T<:Real} <: AbstractLogger

An object for storing variables of the simulation. 

# Fields 

- `net_worth::Array{T,2}`: total value of investments
- `interest::Array{T,2}`: growth rate of investment 
- `inflation::Array{T,2}`: inflation rate 

In each array above, rows are time steps and columns are repetitions of the simulation. 
"""
mutable struct Logger{T<:Real} <: AbstractLogger
    net_worth::Array{T,2}
    interest::Array{T,2}
    inflation::Array{T,2}
end

"""
    Logger(;n_steps, n_reps)

An object for storing variables of the simulation. 

# Keywords 

- `net_worth::Array{T,2}`: total value of investments
- `interest::Array{T,2}`: growth rate of investment 
- `inflation::Array{T,2}`: inflation rate 

In each array above, rows are time steps and columns are repetitions of the simulation. 
"""
function Logger(;n_steps, n_reps)
    return Logger(zeros(n_steps, n_reps), zeros(n_steps, n_reps), zeros(n_steps, n_reps))
end

"""
    AbstractModel

An abstract model type for simulating retirement investments.
"""
abstract type AbstractModel end 

"""
    Model{S} <: AbstractModel

The default retirement simulation Model. 

# Fields 

- `Δt::Float64`: the time step of the simulation in years
- `duration::Float64`: the duration of the simulation in years
- `start_age::Float64`: age at the beginning of the simulation
- `start_amount::Float64`: initial investment amount 
- `state::S`: the current state of the system 
- `withdraw!`: a function called on each time step to withdraw from investments 
- `invest!`: a function called on each time step to invest money into investments 
- `update_income!`: a function called on each time step to update income sources 
- `update_inflation!`: a function called on each time step to compute inflation 
- `update_interest!`: a function called on each time step to compute interest on investments
- `update_net_worth!`: a function called on each time step to compute net worth 
- `log!`: a function called on each time step to log data

# Constructor

    Model(;
            Δt,
            duration,
            start_age,
            start_amount,
            state = State(),
            withdraw! = variable_withdraw,
            invest! = variable_invest,
            update_income! = fixed_income,
            update_inflation! = dynamic_inflation,
            update_interest! = dynamic_interest,
            update_net_worth! = default_net_worth,
            log! = default_log!
        )
"""
@concrete mutable struct Model{S,T} <: AbstractModel
    Δt::T
    duration::T
    start_age::T
    start_amount::T
    state::S
    withdraw!
    invest!
    update_income!
    update_inflation!
    update_interest!
    update_net_worth!
    log! 
end

function Model(;
        Δt,
        duration,
        start_age,
        start_amount,
        state = State(),
        withdraw! = variable_withdraw,
        invest! = variable_investment,
        update_income! = fixed_income,
        update_inflation! = dynamic_inflation,
        update_interest! = dynamic_interest,
        update_net_worth! = default_net_worth,
        log! = default_log!
    )
    Δt,duration,start_age,start_amount = promote(Δt, duration, start_age, start_amount)
    return Model(    
        Δt,
        duration,
        start_age,
        start_amount,
        state,
        withdraw!,
        invest!,
        update_income!,
        update_inflation!,
        update_interest!,
        update_net_worth!,
        log!
    )
end