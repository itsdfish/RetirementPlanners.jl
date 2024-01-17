"""
    fixed_inflation(model::AbstractModel, t; inflation_rate = .03)

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `inflation_rate = .03`: a constant rate of inflation per year
"""
function fixed_inflation(model::AbstractModel, t; inflation_rate = .03)
    model.state.inflation_rate = inflation_rate
    return nothing
end

"""
    interest_rate(model::AbstractModel, t; inflation_rate = .07)

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `interest_rate = .07`: a constant rate of investment growth per year
"""
function fixed_interest(model::AbstractModel, t; interest_rate = .07)
    model.state.interest_rate = interest_rate
    return nothing
end

"""
    fixed_withdraw(model::AbstractModel, t; withdraw_amount = 3000.0)

Withdraw a fixed amount from investments per time step once retirement starts. The beginning of retirement 
is determined by an event with the keyword `:retirement`. 

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `withdraw_amount = 3000.0`: the amount withdrawn from investments per time step
"""
function fixed_withdraw(model::AbstractModel, t; withdraw_amount = 3000.0)
    if model.events[:retirement].start ≤ t 
        model.state.withdraw_amount = withdraw_amount
    end
    return nothing
end