```@setup plotting
using Distributions
using Plots
using RetirementPlanners
```

# Plotting Support

Currently, `RetirementPlanners.jl` only provides one specialized plotting function. More plotting functionality might be included in the future. 


## gradient_plot 

 In simulations involving hundreds or thousands of repetitions, it is not feasible to plot all trajectories of net worth due to overplotting. The function `gradient_plot` overcomes this challenge by representing variability as a density gradient, where darker regions correspond to more likely trajectories. `gradient_plot` is conditionally loaded into your active session when `RetirementPlanners` and `Plots` are loaded. The example below shows a gradient density plot for 1000 simulations with 10 individual trajectories optionally added through the keyword `n_lines`. The full set of code can be seen by expanding the hidden code under *Show Code*.


```@raw html
<details>
<summary><b>Show Code</b></summary>
```
```@example plotting

using Distributions
using Plots
using Random
using RetirementPlanners

Random.seed!(535)

# configuration options
config = (
    # withdraw parameters 
    kw_withdraw = (
        distribution = Normal(4000, 1000),
        start_age = 65,
    ),
    # invest parameters
    kw_invest = (
        distribution = Normal(1200, 300),
        end_age = 65,
    ),
    # interest parameters
    kw_interest = (
        gbm = GBM(; μ = .07, σ = .05),
    ),
    # inflation parameters
    kw_inflation = (
        gbm = GBM(; μ = .035, σ = .005),
    )
)

# setup retirement model
model = Model(;
    Δt = 1 / 12,
    start_age = 32.0,
    duration = 55.0,
    start_amount = 10_000.0,
    withdraw! = variable_withdraw,
    invest! = variable_investment,
    update_inflation! = dynamic_inflation,
    update_interest! = dynamic_interest,
)

times = get_times(model)
n_reps = 1000
n_steps = length(times)
logger = Logger(;n_steps, n_reps)
simulate!(model, logger, n_reps; config...);

```
```@raw html
</details>
```

```@example plotting 
plot_gradient(times, logger.net_worth; xlabel="Age", ylabel="Net Worth", n_lines = 10)
```
