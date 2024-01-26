
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
    model.state.withdraw_amount = 0.0
    if start_age ≤ t 
        if model.state.net_worth < withdraw_amount
            model.state.withdraw_amount = model.state.net_worth
        else
            model.state.withdraw_amount = withdraw_amount
        end
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
        withdraw_amount = rand(distribution)
        if model.state.net_worth < withdraw_amount
            model.state.withdraw_amount = model.state.net_worth
        else
            model.state.withdraw_amount = withdraw_amount
        end
    else 
        model.state.withdraw_amount = 0.0
    end

    return nothing
end