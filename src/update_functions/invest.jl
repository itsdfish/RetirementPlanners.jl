"""
    fixed_invest(
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
function fixed_invest(model::AbstractModel, t; invest_amount = 1000.0, end_age = 67.0)
    model.state.invest_amount = end_age ≥ t ? invest_amount : 0.0
    return nothing
end

"""
    variable_invest(
        model::AbstractModel,
        t;
        end_age = 67.0,
        distribution = Normal(1000, 200),
        lump_sum_investments = nothing
    )

Contribute a variable amount into investments per time step using the specifed distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `end_age = 67.0`: the age at which investing stops 
- `distribution = Normal(1000, 200)`: the distribution from which the investment amount is sampled
- `lump_sum_investments = nothing`: single investments to occur at a specified age. Values in the dictionary are
    `Dict(age => amount)`. 
"""
function variable_invest(
    model::AbstractModel,
    t;
    end_age = 67.0,
    distribution = Normal(1000, 200),
    lump_sum_investments = nothing
)
    state = model.state
    Δt = model.Δt
    state.invest_amount = end_age ≥ t ? rand(distribution) : 0.0
    isnothing(lump_sum_investments) ? (return nothing) : nothing
    for k ∈ keys(lump_sum_investments)
        if (k > (t - Δt)) && (k < (t + Δt))
            invest_amount = lump_sum_investments[k]
            state.invest_amount += invest_amount
        end
    end
    return nothing
end
