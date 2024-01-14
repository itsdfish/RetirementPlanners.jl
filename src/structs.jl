abstract type AbstractState end

mutable struct State <: AbstractState
    interest_rate::Float64
    inflation_rate::Float64  
    withdraw_amount::Float64
    invest_amount::Float64
    net_worth::Float64
end

function State(;
    interest_rate = 0.0, 
    inflation_rate = 0.0, 
    withdraw_amount = 0.0, 
    invest_amount = 0.0, 
    net_worth = 0.0)
    return State(interest_rate, inflation_rate, withdraw_amount, invest_amount, net_worth)
end

abstract type AbstractEvents end 

mutable struct Events <: AbstractEvents
    withdraw_start::Float64
    n_work_years::Float64
    social_security_start::Float64  
end

function Events(;
    withdraw_start,
    n_work_years,
    social_security_start)
    Events(withdraw_start, n_work_years, social_security_start)
end

abstract type AbstractLogger end 

mutable struct Logger{T<:Real} <: AbstractLogger
    amount::Vector{T}
    time::Vector{T}
    interest::Vector{T}
end

function Logger()
    return Logger(Float64[], Float64[], Float64[])
end

abstract type AbstractCalculator end 

mutable struct Calculator{E<:AbstractEvents,S<:AbstractState} <: AbstractCalculator
    Δt::Float64
    n_years::Int
    start_amount::Float64
    state::S
    events::E 
end

function Calculator(;
    Δt,
    n_years,
    start_amount,
    state = State(),
    events)
    return Calculator(Δt, n_years, start_amount, state, events)
end