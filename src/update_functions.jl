"""
    fixed_income(model::AbstractModel, t;
        income_amount = 1500.0,
        start_age = 67.0
    )

Recieve a fixed amount of income (e.g., social security, pension) per time step

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `income_amount = 1500.0`: the amount contributed to investments per time step
- `start_age = 67.0`: the age at which investing stops 
"""
function fixed_income(model::AbstractModel, t;
        income_amount = 1500.0,
        start_age = 67.0
    )
    if start_age ≤ t 
        model.state.income_amount = income_amount
    end
    return nothing
end


"""
    variable_income(model::AbstractModel, t; 
        start_age = 67,
        distribution = Normal(1500,300)
    )

Recieves variable income (e.g., social security, pension) per time step based on the 
sepcified distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `start_age = 67`: the age at which income begins to be recieved
- `distribution=Normal(1500,300)`: distribution from which income is recieved on each time step
"""
function variable_income(model::AbstractModel, t; 
        start_age = 67,
        distribution = Normal(1500,300)
    )
    if start_age ≤ t 
        model.state.income_amount = rand(distribution)
    end
    return nothing
end

"""
    fixed_inflation(model::AbstractModel, t; inflation_rate = .03)

Returns a fixed inflation rate of a specified value.

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
    variable_inflation(model::AbstractModel, t; distribution = Normal(.03, .01))

Returns an interest rate sampled from a specified distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `distribution = Normal(.03, .01)`: the distribution of inflation per year 
"""
function variable_inflation(model::AbstractModel, t; distribution = Normal(.03, .01))
    model.state.inflation_rate = rand(distribution)
    return nothing
end

"""
    fixed_interest(model::AbstractModel, t; interest_rate = .07)

Returns a fixed interesting rate using a specified value.

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
    variable_interest(model::AbstractModel, t; distribution = Normal(.07, .05))

Returns interest rate sampled from a specified distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `distribution = Normal(.07, .05)`: the distribution of interest per year 
"""
function variable_interest(model::AbstractModel, t; distribution = Normal(.07, .05))
    model.state.interest_rate = rand(distribution)
    return nothing
end

"""
    fixed_investment(model::AbstractModel, t;
        income_amount = 3000.0,
        start_age = 67.0
    )

Contribute a fixed amount into investments per time step.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `invest_amount = 3000.0`: the amount contributed to investments per time step
- `start_age = 67.0`: the age at which investing stops 
"""
function fixed_investment(model::AbstractModel, t;
        invest_amount = 1000.0,
        end_age = 67.0
    )
    if end_age ≥ t 
        model.state.invest_amount = invest_amount
    end
    return nothing
end

"""
    variable_investment(model::AbstractModel, t; 
            end_age = 67.0, 
            distribution = Normal(1000, 200)
    )

Contribute a variable amount into investments per time step using the specifed distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `end_age = 67.0`: the age at which investing stops 
- `distribution = Normal(1000, 200)`: the distribution from which the investment amount is sampled
"""
function variable_investment(model::AbstractModel, t; 
        end_age = 67.0, 
        distribution = Normal(1000, 200)
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
    real_growth = (1 + model.state.interest_rate) / (1 + model.state.inflation_rate) - 1
    model.state.net_worth *= (1 + real_growth)^model.Δt
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
    variable_withdraw(model::AbstractModel, t;
            start_age = 67, 
            distribution = Normal(2500, 500)
    )

Withdraw a variable amount from investments per time step once retirement starts using a specifed 
distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

-  `start_age = 67`: the age at which withdraws begin 
- `distribution = Normal(2500, 500)`: the distribution of withdraws per time step
"""
function variable_withdraw(model::AbstractModel, t;
        start_age = 67, 
        distribution = Normal(2500, 500)
    )
    if start_age ≤ t 
        model.state.withdraw_amount = rand(distribution)
    end
    return nothing
end