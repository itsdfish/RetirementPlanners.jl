"""
    fixed_withdraw(
        model::AbstractModel,
        t;
        withdraw_amount = 3000.0,
        start_age = 67.0,
        income_adjustment = 0.0
    )

Withdraw a fixed amount from investments per time step once retirement starts.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `withdraw_amount = 3000.0`: the amount withdrawn from investments per time step
- `start_age = 67.0`: the age at which withdraws begin 
- `income_adjustment = 0.0`: a value between 0 and 1 representing the reduction in `withdraw_amount`
    relative to other income (e.g., social security, pension, etc). 1 indicates all income is subtracted from `withdraw_amount`.
"""
function fixed_withdraw(
    model::AbstractModel,
    t;
    withdraw_amount = 3000.0,
    start_age = 67.0,
    income_adjustment = 0.0,
)
    model.state.withdraw_amount = 0.0
    model.state.net_worth == 0.0 ? (return nothing) : nothing
    withdraw_amount =
        max(withdraw_amount - model.state.income_amount * income_adjustment, 0)
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
    variable_withdraw(
            model::AbstractModel,
            t;
            start_age = 67, 
            distribution = Normal(2500, 500),
            income_adjustment = 0.0
    )

Withdraw a variable amount from investments per time step once retirement starts using a specifed 
distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

-  `start_age = 67`: the age at which withdraws begin 
- `distribution = Normal(2500, 500)`: the distribution of withdraws per time step
- `income_adjustment = 0.0`: a value between 0 and 1 representing the reduction in `withdraw_amount`
    relative to other income (e.g., social security, pension, etc). 1 indicates all income is subtracted from `withdraw_amount`.
"""
function variable_withdraw(
    model::AbstractModel,
    t;
    start_age = 67,
    distribution = Normal(2500, 500),
    income_adjustment = 0.0,
)
    model.state.withdraw_amount = 0.0
    model.state.net_worth == 0.0 ? (return nothing) : nothing
    if start_age ≤ t
        withdraw_amount = rand(distribution)
        withdraw_amount =
            max(withdraw_amount - model.state.income_amount * income_adjustment, 0)
        if model.state.net_worth < withdraw_amount
            model.state.withdraw_amount = model.state.net_worth
        else
            model.state.withdraw_amount = withdraw_amount
        end
    end
    return nothing
end

"""
    adaptive_withdraw(
        model::AbstractModel,
        t;
        start_age = 67, 
        min_withdraw = 1000,
        percent_of_real_growth = 1,
        income_adjustment = 0.0,
        volitility = .1,
    )

An adaptive withdraw scheme based on current real growth rate. As long as there are sufficient funds, a minimum amount 
 `min_withdraw` is withdrawn. More can be withdrawn if the current real growth rate supports a larger amount. The parameters below allow
the user to control how much can be withdrawn as a function of real growth rate (`percent_of_real_growth`) and how much volitility in the withdraw 
amount is tolerated (`volitility`). The withdraw amount may also be decreased based on alternative income (e.g., social security, pension).

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `start_age = 67`: the age at which withdraws begin 
- `min_withdraw = 1000`: the minimum withdraw amount
- `percent_of_real_growth = 1`: the percent of real growth withdrawn. If equal to 1, the max of real growth or 
    `min_withdraw`. 
- `income_adjustment = 0.0`: a value between 0 and 1 representing the reduction in `withdraw_amount`
    relative to other income (e.g., social security, pension, etc). 1 indicates all income is subtracted from `withdraw_amount`.
- `volitility = .1`: a value greater than zero which controls the variability in withdraw amount. The standard deviation 
    is the mean withdraw × volitility
"""
function adaptive_withdraw(
    model::AbstractModel,
    t;
    start_age = 67,
    min_withdraw = 1000,
    percent_of_real_growth = 1,
    income_adjustment = 0.0,
    volitility = 0.5,
)
    model.state.withdraw_amount = 0.0
    model.state.net_worth == 0.0 ? (return nothing) : nothing
    if start_age ≤ t
        real_growth_rate = (1 + compute_real_growth_rate(model))^model.Δt
        mean_withdraw =
            model.state.net_worth * (real_growth_rate - 1) * percent_of_real_growth
        mean_withdraw = max(min_withdraw, mean_withdraw)
        withdraw_amount =
            volitility ≈ 0.0 ? mean_withdraw :
            rand(Normal(mean_withdraw, mean_withdraw * volitility))
        withdraw_amount = max(withdraw_amount, min_withdraw)
        withdraw_amount =
            max(withdraw_amount - model.state.income_amount * income_adjustment, 0)
        if model.state.net_worth < withdraw_amount
            model.state.withdraw_amount = model.state.net_worth
        else
            model.state.withdraw_amount = withdraw_amount
        end
    end
    return nothing
end
