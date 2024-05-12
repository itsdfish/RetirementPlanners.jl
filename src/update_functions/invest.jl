"""
    invest!(
        model::AbstractModel,
        t;
        investments = Transaction(0.0, -1.0, 0.0),
        real_growth = 0.0,
        peak_age = 45
    )

Contribute a specified amount into investments on each time step.

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
    if can_transact(investment, t; Δt)
        state.invest_amount += transact(model, investment; t)
    end
    return nothing
end

function _invest!(
    model::AbstractModel,
    t,
    investments;
)
    for investment ∈ investments
        _invest!(model, t, investment)
    end
    return nothing
end

"""
    transact(
        ::AbstractModel,
        investment::Transaction{T, D};
        t
    ) where {T, D <: AdaptiveInvestment}

Execute an adaptive investment transaction in which the real invested amount increased until reaching 
a peak earning potential. 

# Arguments

- `::AbstractModel`: unused model object 
- `investment::Transaction{T, D}`: a transaction object specifing an investment rule

# Keywords

- `t`: the current time
"""
function transact(
    ::AbstractModel,
    investment::Transaction{T, D};
    t
) where {T, D <: AdaptiveInvestment}
    (; start_age, real_growth_rate, peak_age, mean, std) =
        investment.amount
    base_investment = rand(Normal(mean, std))
    n_years = t ≥ peak_age ? (peak_age - start_age) : (t - start_age)
    growth_factor = (1 + real_growth_rate)^floor(n_years)
    return base_investment * growth_factor
end
