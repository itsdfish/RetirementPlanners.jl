


"""
    default_net_worth(model::AbstractModel, t)

Computes net worth for the current time step as follows:

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 
"""
function default_net_worth(model::AbstractModel, t; _...)
    # println("age $t net worth $(model.state.net_worth) withdraw amount $(model.state.withdraw_amount)")
    model.state.net_worth -= model.state.withdraw_amount
    model.state.net_worth += model.state.invest_amount
    real_growth = (1 + model.state.interest_rate) / (1 + model.state.inflation_rate) - 1
    model.state.net_worth *= (1 + real_growth)^model.Δt
end