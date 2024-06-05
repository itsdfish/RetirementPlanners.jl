"""
    AbstractState

An abstract type for tracking the state of the model during simulation.     
"""
abstract type AbstractState end

"""
    State{T<:Real} <: AbstractState

Represents the state of the model, which is updated on each iteration. 

# Fields 

- `interest_rate::T`: interest rate of investment during the current time period 
- `inflation_rate::T`: the inflation rate during the current time period 
- `income_amount::T`: income during the current time period from various sources, e.g., social 
    security, pension, etc.
- `invest_amount::T`: the amount invested during the current time period 
- `withdraw_amount::T`: the amount deducted from investments during the current time period 
- `net_worth::T`: total value of the investment during the current time period 
"""
mutable struct State{T <: Real} <: AbstractState
    interest_rate::T
    inflation_rate::T
    income_amount::T
    invest_amount::T
    withdraw_amount::T
    net_worth::T
    log_idx::Int
end

"""
    State(;
        interest_rate = 0.0, 
        inflation_rate = 0.0,
        income_amount = 0.0,
        invest_amount = 0.0,
        withdraw_amount = 0.0, 
        net_worth = 0.0
    )

Constructor for a state object, which represents the state of the model on each iteration. 

# Keywords

- `interest_rate::T`: interest rate of investment during the current time period 
- `inflation_rate::T`: the inflation rate during the current time period 
- `income_amount::T`: income during the current time period from various sources, e.g., social 
    security, pension, etc. 
- `invest_amount::T`: the amount invested during the current time period
- `withdraw_amount::T`: the amount deducted from investments during the current time period 
- `net_worth::T`: total value of the investment during the current time period 
"""
function State(;
    interest_rate = 0.0,
    inflation_rate = 0.0,
    income_amount = 0.0,
    invest_amount = 0.0,
    withdraw_amount = 0.0,
    net_worth = 0.0
)
    return State(
        interest_rate,
        inflation_rate,
        income_amount,
        invest_amount,
        withdraw_amount,
        net_worth,
        1
    )
end

function State(
    interest_rate,
    inflation_rate,
    income_amount,
    invest_amount,
    withdraw_amount,
    net_worth
)
    return State(
        promote(
        interest_rate,
        inflation_rate,
        income_amount,
        invest_amount,
        withdraw_amount,
        net_worth
    )...
    )
end

"""
    AbstractLogger

An abstract type for recording the state of the model during simulation.     
"""
abstract type AbstractLogger end

"""
    Logger{T <: Real} <: AbstractLogger

An object for storing variables of the simulation. 

# Fields 

- `net_worth::Array{T, 2}`: total value of investments
- `interest::Array{T, 2}`: growth rate of investment 
- `inflation::Array{T, 2}`: inflation rate 
- `total_income::Array{T, 2}`: income from investment withdraws, social security etc.

In each array above, rows are time steps and columns are repetitions of the simulation. 
"""
mutable struct Logger{T <: Real} <: AbstractLogger
    net_worth::Array{T, 2}
    interest::Array{T, 2}
    inflation::Array{T, 2}
    total_income::Array{T, 2}
end

"""
    Logger(; n_steps, n_reps)

An object for storing variables of the simulation. 

# Keywords 

- `net_worth::Array{T, 2}`: total value of investments
- `interest::Array{T, 2}`: growth rate of investment 
- `inflation::Array{T, 2}`: inflation rate 
- `total_income::Array{T, 2}`: income from investment withdraws, social security etc.

In each array above, rows are time steps and columns are repetitions of the simulation. 
"""
function Logger(; n_steps, n_reps)
    return Logger(
        zeros(n_steps, n_reps),
        zeros(n_steps, n_reps),
        zeros(n_steps, n_reps),
        zeros(n_steps, n_reps)
    )
end

"""
    AbstractModel

An abstract model type for simulating retirement investments.
"""
abstract type AbstractModel end

"""
    Model{S, T<:Real} <: AbstractModel

The default retirement simulation Model. 

# Fields 

- `Δt::T`: the time step of the simulation in years
- `duration::T`: the duration of the simulation in years
- `start_age::T`: age at the beginning of the simulation
- `start_amount::T`: initial investment amount 
- `state::S`: the current state of the system 
- `withdraw!`: a function called on each time step to withdraw from investments 
- `invest!`: a function called on each time step to invest money into investments 
- `update_income!`: a function called on each time step to update income sources 
- `update_inflation!`: a function called on each time step to compute inflation 
- `update_market!`: a function called on each time step to compute interest on investments
- `update_investments!`: a function called on each time step to compute net worth 
- `log!`: a function called on each time step to log data

# Constructor

    Model(;
        Δt,
        duration,
        start_age,
        start_amount,
        state = State(),
        withdraw! = withdraw!,
        invest! = invest!,
        update_income! = update_income!,
        update_inflation! = dynamic_inflation,
        update_market! = dynamic_market,
        update_investments! = update_investments!,
        log! = default_log!,
        config...
    )
"""
@concrete mutable struct Model{S, R, T <: Real} <: AbstractModel
    Δt::T
    duration::T
    start_age::T
    start_amount::T
    log_times::R
    state::S
    withdraw!
    invest!
    update_income!
    update_inflation!
    update_market!
    update_investments!
    log!
    config
end

function Model(;
    Δt,
    duration,
    start_age,
    start_amount,
    log_times = (start_age + Δt):Δt:(start_age + duration),
    state = State(),
    withdraw! = withdraw!,
    invest! = invest!,
    update_income! = update_income!,
    update_inflation! = dynamic_inflation,
    update_market! = dynamic_market,
    update_investments! = update_investments!,
    log! = default_log!,
    config...
)
    Δt, duration, start_age, start_amount = promote(Δt, duration, start_age, start_amount)

    return Model(
        Δt,
        duration,
        start_age,
        start_amount,
        log_times,
        state,
        withdraw!,
        invest!,
        update_income!,
        update_inflation!,
        update_market!,
        update_investments!,
        log!,
        NamedTuple(config)
    )
end

"""
    AbstractTransaction{T, D}
    
An abstract type for scheduling transactions. 
"""
abstract type AbstractTransaction{T, D} end

"""
    Transaction{T, D} <: AbstractTransaction{T, D}

Specifies the time range and amount of a transaction. 

# Fields 

- `start_age = 0.0`: the age at which a series of transactions begin
- `end_age = Inf`: the age at which a series of transactions end
- `amount = 0`: the amount of each transaction

# Constructor

    Transaction(; start_age = 0.0, end_age = Inf, amount = 0)
"""
struct Transaction{T, D} <: AbstractTransaction{T, D}
    start_age::T
    end_age::T
    amount::D
end

function Transaction(; start_age = 0.0, end_age = Inf, amount = 0)
    return Transaction(promote(start_age, end_age)..., amount)
end

Base.broadcastable(dist::Transaction) = Ref(dist)

"""
    AdaptiveWithdraw{T <: Real}

An adaptive withdraw scheme based on current real growth rate. As long as there are sufficient funds, a minimum amount 
`min_withdraw` is withdrawn. More can be withdrawn if the current real growth rate supports a larger amount. The parameters below allow
the user to control how much can be withdrawn as a function of real growth rate (`percent_of_real_growth`) and how much volitility in the withdraw 
amount is tolerated (`volitility`). The withdraw amount may also be decreased based on alternative income (e.g., social security, pension).


# Fields 

- `min_withdraw = 1000`: the minimum withdraw amount
- `percent_of_real_growth = 1`: the percent of real growth withdrawn. If equal to 1, the max of real growth or 
    `min_withdraw`. 
- `income_adjustment = 0.0`: a value between 0 and 1 representing the reduction in `withdraw_amount`
    relative to other income (e.g., social security, pension, etc). 1 indicates all income is subtracted from `withdraw_amount`.
- `volitility = .1`: a value greater than zero which controls the variability in withdraw amount. The standard deviation 
    is the mean withdraw × volitility

# Constructor

    AdaptiveWithdraw(;
        min_withdraw,
        volitility = 0.0,
        income_adjustment = 0.0,
        percent_of_real_growth = 0.0
    )
"""
mutable struct AdaptiveWithdraw{T <: Real}
    min_withdraw::T
    volitility::T
    income_adjustment::T
    percent_of_real_growth::T
end

function AdaptiveWithdraw(;
    min_withdraw,
    volitility = 0.0,
    income_adjustment = 0.0,
    percent_of_real_growth = 0.0
)
    return AdaptiveWithdraw(promote(
        min_withdraw,
        volitility,
        income_adjustment,
        percent_of_real_growth
    )...)
end

"""

    AdaptiveInvestment{T <: Real}

# Fields 

- `start_age`: the age at which investing begins
- `peak_age`: the age at which investment amount stops growing. Many people reach their maximum income around 45-50.
- `real_growth = 0`: percent of annual growth in investment amount. The growth factor (1 + real_growth)^n_years 
    is multiplied by the random invest amount from `distribution`, meaning the mean and variance increase over time 
    assuming `real_growth` > 0.
- `mean`: the average amount invested
- `std`: the standard deviation of the amount invested

# Constructor

    AdaptiveInvestment(;
        start_age,
        peak_age,
        real_growth_rate,
        mean,
        std
    )
"""
mutable struct AdaptiveInvestment{T <: Real}
    start_age::T
    peak_age::T
    real_growth_rate::T
    mean::T
    std::T
end

function AdaptiveInvestment(;
    start_age,
    peak_age,
    real_growth_rate,
    mean,
    std
)
    return AdaptiveInvestment(promote(
        start_age,
        peak_age,
        real_growth_rate,
        mean,
        std)...)
end

"""
    NominalAmount{T <: AbstractFloat}

Allows a specified income source to change with inflation.

# Fields

- `amount::T`: the nominal amount
- `adjust::Bool`: adjust if true, otherwise don't adjust 
- `initial_amount::T`: the initial value used to reset `amount`
"""
mutable struct NominalAmount{T <: AbstractFloat}
    amount::T
    adjust::Bool
    initial_amount::T
end

function NominalAmount(; amount, adjust = true)
    return NominalAmount(amount, adjust, amount)
end

function NominalAmount(amount, adjust = true, initial_amount = amount)
    amount, initial_amount, _ = promote(amount, initial_amount, Float32(0))
    return NominalAmount(amount, adjust, initial_amount)
end
