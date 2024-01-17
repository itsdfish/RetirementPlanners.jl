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
    fixed_withdraw(model::AbstractModel, t;
        withdraw_amount = 3000.0,
        start_age = 67.0
    )

Withdraw a fixed amount from investments per time step once retirement starts.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `withdraw_amount = 3000.0`: the amount withdrawn from investments per time step
- `start_age = 67.0`: the age at which withdraws begin 
"""
function fixed_withdraw(model::AbstractModel, t;
        withdraw_amount = 3000.0,
        start_age = 67.0
    )
    if start_age ≤ t 
        model.state.withdraw_amount = withdraw_amount
    end
    return nothing
end

"""
    fixed_investment(model::AbstractModel, t;
        invest_amount = 3000.0,
        end_age = 67.0
    )

Contibute a fixed amount to investments per time step.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `invest_amount = 3000.0`: the amount contributed to investments per time step
- `end_age = 67.0`: the age at which investing stops 
"""
function fixed_investment(model::AbstractModel, t;
        invest_amount = 3000.0,
        end_age = 67.0
    )
    if end_age ≥ t 
        model.state.invest_amount = invest_amount
    end
    return nothing
end

"""
    default_net_worth(model::AbstractModel, t)

Computes net worth for the current time step as follows:



# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 
"""
function default_net_worth(model::AbstractModel, t; _...)
    model.state.net_worth -= model.state.withdraw_amount
    model.state.net_worth += model.state.invest_amount
    total_growth = model.state.interest_rate - model.state.inflation_rate
    model.state.net_worth *= (1 + total_growth)^model.Δt
end

"""
    default_log!(model::AbstractModel, logger, step, rep)

Logs the following information on each time step of each simulation repetition:

- `net worth`
- `interest rate`
- `inflation rate`

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `logger`: a logger object
"""
function default_log!(model::AbstractModel, logger, step, rep; _...)
    logger.net_worth[step,rep] = model.state.net_worth
    logger.interest[step,rep] = model.state.interest_rate
    logger.inflation[step,rep] = model.state.inflation_rate
    return nothing
end