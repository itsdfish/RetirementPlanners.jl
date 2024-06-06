```@setup custom_example
using Distributions
using Plots
using Random
using RetirementPlanners
```

# Overview

The purpose of this example is to illustrate how to customize update functions in `RetirementPlanners.jl`. The general process of creating a custom update function involves the following steps:

1. Define a function with the following signature `your_update_function(model::AbstractModel, t; kwargs...)` where `kwargs...` is an optional set of keyword arguments. 
2. Pass the function to the configuration data structure `config`. For example `update_investments! = your_update_function`.
3. Optionally pass keyword arguments to `config`, e.g., `kw_investments = (kwargs...)`

As an illustrative example, consider a person who is considering the cost of a financial advisor who charges an annual 1% fee of the value of the assets. Estimating the cost is not straightforward because the fee decreases future growth potential. To estimate the cost, we will run simulations of identical scenarios, except in one case there is a 1% fee, but in the other case there is no fee.   

# Load Packages 

Below, we load the required packages. 
```@example custom_example
using Plots
using Random
using RetirementPlanners
```

# Custom Functions

We will define an custom update function for `update_investments!`, which requires `model` and time `t` as positional inputs, and `fee_rate` as a keyword argument. The custom function is the same as the default function for `update_investments!`, except the fee is applied once a year to the net_worth of investments. 

```@example custom_example
function update_investments_fee!(model::AbstractModel, t; fee_rate = 0.0, _...)
    model.state.net_worth -= model.state.withdraw_amount
    model.state.net_worth += model.state.invest_amount
    if mod(t, 1) ≈ 0
        model.state.net_worth *= (1 - fee_rate)
    end
    real_growth = compute_real_growth_rate(model)
    model.state.net_worth *= (1 + real_growth)^model.Δt
    return nothing
end
```

In most cases, it is sufficient to define the new update function. However, in this particular case, it is necessary to develop a custom `simulate!` function which runs each repetition with a different seed for the random number generator. This allows us to generate random simulations which only differ by the fee. In other words, the simulations are correlated between the different conditions. If we did not equate the seeds between the two conditions, the cost would be negative in some cases because we would be comparing simulations under different conditions (e.g., the random growth rate might differ).

```@example custom_example
import RetirementPlanners: simulate!
using RetirementPlanners: simulate_once! 
using RetirementPlanners: compute_real_growth_rate
```

```@example custom_example
function simulate!(model::AbstractModel, logger::AbstractLogger, n_reps, seed)
    for rep ∈ 1:n_reps
        Random.seed!(seed + rep)
        simulate_once!(model, logger, rep)
    end
    return nothing
end
```

# Configuration 

We will define a configuration for both conditions. The first configuration corresponds to the advisor fee condition. The second configuration is identical except the fee is eliminated.  

```@example custom_example
config = (
    # time step in years 
    Δt = 1 / 12,
    # start age of simulation 
    start_age = 50,
    # duration of simulation in years
    duration = 40,
    # initial investment amount 
    start_amount = 1_000_000,
    update_investments! = update_investments_fee!,
    # investment parameters
    kw_investments = (; fee_rate = 0.01),
    # withdraw parameters 
    kw_withdraw = (;
        withdraws = Transaction(; start_age = 55, amount = Normal(2000, 200)),),
    # invest parameters
    kw_invest = (investments = Transaction(; start_age = 0, end_age = 0, amount = 0.0),),
    # interest parameters
    kw_market = (; gbm = VarGBM(; αμ = 0.080, ημ = 0.010, ασ = 0.035, ησ = 0.010),),
    # inflation parameters
    kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
    # income parameters 
    kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000.0),)
)
# setup retirement model
model = Model(; config...)
```

```@example custom_example
config2 = (
    # time step in years 
    Δt = 1 / 12,
    # start age of simulation 
    start_age = 50,
    # duration of simulation in years
    duration = 40,
    # initial investment amount 
    start_amount = 1_000_000,
    update_investments! = update_investments_fee!,
    # investment parameters
    kw_investments = (; fee_rate = 0.00),
    # withdraw parameters 
    kw_withdraw = (;
        withdraws = Transaction(; start_age = 55, amount = Normal(2000, 200)),),
    # invest parameters
    kw_invest = (investments = Transaction(; start_age = 0, end_age = 0, amount = 0.0),),
    # interest parameters
    kw_market = (; gbm = VarGBM(; αμ = 0.080, ημ = 0.010, ασ = 0.035, ησ = 0.010),),
    # inflation parameters
    kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
    # income parameters 
    kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000.0),)
)
# setup retirement model
model2 = Model(; config2...)
```

# Run Simulations 

In the code block below, we will run both simulations 1000 times each. 

```@example custom_example
seed = 8564
times = get_times(model)
n_reps = 1000
n_steps = length(times)
logger1 = Logger(; n_steps, n_reps)
logger2 = Logger(; n_steps, n_reps)

# simulate scenario with fee
simulate!(model, logger1, n_reps, seed)

# simulate scenario without fee
simulate!(model2, logger2, n_reps, seed)
```

The code block below computes the cost as the difference in investment value between the simulations with an advisor fee and the simulations without the advisor fee. The units are expressed in millions of dollars for ease of interpretation. 

```@example custom_example
net_worth_diff = (logger2.net_worth .- logger1.net_worth) / 1_000_000
```

# Plot Results

Histograms of the cost are panneled at 10, 20, 30, and 40 years. As expected, the cost increases across time and become increasingly variable. Importantly, the cost is quite large. After 20 years the interquartile range is .32 - .48 million, and increases to .60 - 1.10 million after 30 years. 

```@raw html
<details>
<summary><b>Show Code </b></summary>
```
```@example custom_example
idx = 12 * 10
p10 = histogram(
    net_worth_diff[idx, :],
    norm = true,
    leg = false,
    grid = false,
    title = "10 years"
)

idx = 12 * 20
p20 = histogram(
    net_worth_diff[idx, :],
    norm = true,
    leg = false,
    grid = false,
    title = "20 years"
)

idx = 12 * 30
p30 = histogram(
    net_worth_diff[idx, :],
    norm = true,
    leg = false,
    grid = false,
    title = "30 years"
)

idx = 12 * 40
p40 = histogram(
    net_worth_diff[idx, :],
    norm = true,
    leg = false,
    grid = false,
    title = "40 years"
)
```
```@raw html
</details>
```

```@example custom_example
plot(p10, p20, p30, p40, layout = (2, 2), xlabel = "Cost in millions")
```