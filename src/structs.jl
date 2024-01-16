abstract type AbstractState end

"""
    State <: AbstractState

Represents the state of the model, which is updated on each iteration. 

# Fields 

- `interest_rate::Float64`: interest rate of investment during the current time period 
- `inflation_rate::Float64`: the inflation rate during the current time period 
- `invest_amount::Float64`: the amount invested during the current time period 
- `withdraw_amount::Float64`: the amount deducted from investments during the current time period 
- `net_worth::Float64`: total value of the investment during the current time period 
"""
mutable struct State <: AbstractState
    interest_rate::Float64
    inflation_rate::Float64  
    invest_amount::Float64
    withdraw_amount::Float64
    net_worth::Float64
end

"""
    State(;
        interest_rate = 0.0, 
        inflation_rate = 0.0,

        withdraw_amount = 0.0, 
        net_worth = 0.0
    )

Constructor for a state object, which represents the state of the model on each iteration. 

# Keywords

- `interest_rate::Float64`: interest rate of investment during the current time period 
- `inflation_rate::Float64`: the inflation rate during the current time period 
- `withdraw_amount::Float64`: the amount deducted from investments during the current time period 
- `net_worth::Float64`: total value of the investment during the current time period 
"""
function State(;
        interest_rate = 0.0, 
        inflation_rate = 0.0, 
        invest_amount = 0.0,
        withdraw_amount = 0.0, 
        net_worth = 0.0
    )

    return State(
        interest_rate,
        inflation_rate,
        invest_amount,
        withdraw_amount,
        net_worth
    )
end

abstract type AbstractEvent end 

"""
    struct Event{T} <: AbstractEvent

An object which indicates the onset of a change in the function of the simulation. 

# Fields 

- `start_time::T`: event onset 
- `end_time::T`: the end time of the event 
"""
mutable struct Event{T} <: AbstractEvent
    start_time::T
    end_time::T
end

"""
    Event(;
        start_time,
        end_time = Inf
    )

An object which indicates the onset of a change in the function of the simulation. 

# Keywords 

- `start_time::T`: event onset 
- `end_time::T` = Inf: the end time of the event 
"""
function Event(;
    start_time,
    end_time = Inf)
    return Event(start_time, end_time)
end

function Event(start_time, end_time)
    s,e = promote_type(start_time, end_time)
    return Event(s, e)
end

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

abstract type AbstractModel end 

"""
    Model{D<:Dict,S} <: AbstractModel

The default retirement simulation Model. 

# Fields 

- `Δt::Float64`:
- `n_years::Int`:
- `rep::Int`: repetition count of simulation 
- `time_step::Int`: time step count of simulation 
- `start_amount::Float64`: initial investment amount 
- `state::S`: the current state of the system 
- `events::D`: a dictionary of events which occur during the simulation
- `withdraw!`: a function called on each time step to withdraw from investments 
- `invest!`: a function called on each time step to invest money into investments 
- `update_inflation!`: a function called on each time step to compute inflation 
- `update_interest!`: a function called on each time step to compute interest on investments
- `update_net_worth!`: a function called on each time step to compute net worth 
- `log!`: a function called on each time step to log data
"""
@concrete mutable struct Model{D<:Dict,S} <: AbstractModel
    Δt::Float64
    n_years::Int
    rep::Int
    time_step::Int
    start_amount::Float64
    state::S
    events::D
    withdraw!
    invest!
    update_inflation!
    update_interest!
    update_net_worth!
    log! 
end

function Model(;
    Δt,
    n_years,
    start_amount,
    state = State(),
    events = Dict(),
    withdraw!,
    invest!,
    update_inflation!,
    update_interest!,
    update_net_worth!,
    log!)

    return Model(    
        Δt,
        n_years,
        0,
        0,
        start_amount,
        state,
        events,
        withdraw!,
        invest!,
        update_inflation!,
        update_interest!,
        update_net_worth!,
        log!)
end