"""
    fixed_invest(model::AbstractModel, t; invest_amount = 1000.0, end_age = 67.0)
    
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
    invest!(
        model::AbstractModel,
        t;
        investments = Transaction(0.0, -1.0, 0.0),
        real_growth = 0.0,
        peak_age = 45
    )

Contribute a variable amount into investments per time step using the specifed distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `investments = Transaction(0.0, -1.0, 0.0)`: a transaction or vector of transactions indicating the time frame and amount to invest
"""
function invest!(
    model::AbstractModel,
    t;
    investments = Transaction(0.0, -1.0, 0.0)
)
    model.state.invest_amount = 0.0
    return _invest!(model, t, investments)
end

function _invest!(
    model::AbstractModel,
    t,
    investment::AbstractTransaction;)
    (; start_age, state, Δt) = model
    if is_available(investment, t)
        state.invest_amount += transact(investment; t)
    end
    return nothing
end

function _invest!(
    model::AbstractModel,
    t,
    investments::Vector{<:AbstractTransaction};
)
    for investment ∈ investments
        _invest!(model, t, investment)
    end
    return nothing
end
