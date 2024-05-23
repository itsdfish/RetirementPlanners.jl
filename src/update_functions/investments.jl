"""
    update_investments!(model::AbstractModel, t)

Computes net worth for the current time step as follows:

1. withdraw money
2. contribute money
3. multiply by real growth rate.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 
"""
function update_investments!(model::AbstractModel, t; _...)
    model.state.net_worth -= model.state.withdraw_amount
    model.state.net_worth += model.state.invest_amount
    real_growth = compute_real_growth_rate(model)
    model.state.net_worth *= (1 + real_growth)^model.Δt
    return nothing
end

"""
    compute_real_growth_rate(model::AbstractModel)

Computes the real annualized groth rate according to 

``\\frac{1 + r_{interest}}{1 + r_{inflation}} - 1``

# Arguments

- `model::AbstractModel`: an abstract Model object 
"""
function compute_real_growth_rate(model::AbstractModel)
    return (1 + model.state.interest_rate) / (1 + model.state.inflation_rate) - 1
end
