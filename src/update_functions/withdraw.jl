"""
    withdraw!(
        model::AbstractModel,
        t;
        withdraws = Transaction(0.0, -1.0, 0.0)
    )

Schedules withdraws from investments as specified in `withdraws`.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `withdraws = Transaction(0.0, -1.0, 0.0)`: a transaction or vector of transactions indicating the amount and time period
    in which money is withdrawn from investments per time step 

"""
function withdraw!(
    model::AbstractModel,
    t;
    withdraws = Transaction(0.0, -1.0, 0.0)
)
    state = model.state
    state.withdraw_amount = 0.0
    state.net_worth == 0.0 ? (return nothing) : nothing
    _withdraw!(model, t, withdraws)
    return nothing
end

function _withdraw!(model::AbstractModel, t, withdraw::AbstractTransaction)
    (; Δt) = model
    if can_transact(withdraw, t; Δt)
        withdraw_amount = transact(model, withdraw; t)
        if model.state.net_worth < withdraw_amount
            withdraw_amount = model.state.net_worth
        end
        model.state.withdraw_amount += withdraw_amount
    end
    return nothing
end

function _withdraw!(model::AbstractModel, t, withdraws)
    for withdraw ∈ withdraws
        _withdraw!(model, t, withdraw)
    end
    return nothing
end

function transact(
    model::AbstractModel,
    withdraw::AbstractTransaction{T, D};
    t
) where {T, D <: AdaptiveWithdraw}
    (; Δt, state) = model
    (; min_withdraw, volitility, income_adjustment, percent_of_real_growth) =
        withdraw.amount
    real_growth_rate = (1 + compute_real_growth_rate(model))^Δt
    mean_withdraw =
        state.net_worth * (real_growth_rate - 1) * percent_of_real_growth
    mean_withdraw = max(min_withdraw, mean_withdraw)
    withdraw_amount =
        volitility ≈ 0.0 ? mean_withdraw :
        rand(Normal(mean_withdraw, mean_withdraw * volitility))
    withdraw_amount = max(withdraw_amount, min_withdraw)
    withdraw_amount =
        max(withdraw_amount - state.income_amount * income_adjustment, 0)
    return withdraw_amount
end
