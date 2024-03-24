"""
    fixed_investment(
        model::AbstractModel, 
        t;
        invest_amount = 1000.0,
        end_age = 67.0
    )
Contribute a fixed amount into investments per time step.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `invest_amount = 3000.0`: the amount contributed to investments per time step
- `start_age = 67.0`: the age at which investing stops 
"""
function fixed_investment(model::AbstractModel, t; invest_amount = 1000.0, end_age = 67.0)
    model.state.invest_amount = end_age ≥ t ? invest_amount : 0.0
    return nothing
end

"""
    variable_investment(
        model::AbstractModel,
        t; 
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
function variable_investment(
    model::AbstractModel,
    t;
    end_age = 67.0,
    distribution = Normal(1000, 200),
)
    model.state.invest_amount = end_age ≥ t ? rand(distribution) : 0.0
    return nothing
end
