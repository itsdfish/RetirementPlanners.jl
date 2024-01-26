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
    model.state.income_amount = start_age ≤ t ? income_amount : 0.0
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
    model.state.income_amount = start_age ≤ t ? rand(distribution) : 0.0
    return nothing
end