```@setup basic
using Plots
using RetirementPlanners
```
# Overview

The purpose of this example is to demonstrate how to use `RetirementPlanners.jl` with a simple, retirement simulation. Our focus on a simple simulation will have the benfit of making the API clear, but will not result in in a valid stress test of your retirement plan. For more realistic examples, please read the documentation for the [advanced example](advanced_example.md). 

# API

In this section, we will provide an overview of the API for configuring a retirement simulation. As detailed below, some parameters require user input, whereas other parameters have default values which can optionally be overwritten with your desired values. 

## Required Parameters

The model requires numerous parameters to control the timing of events and the initial value of the investment. The required parameters are as follows:

- `Δt`: the time step in years 
- `start_age`: your age in years at the beginning of the simulation
- `duration`: the number of years to simulate
- `start_amount`: the amount of money you have in investments at the beginning of the simulation

## Optional Update Functions

The discrete time simulation is governed by seven update functions, which are executed on each time step:

- `withdraw!`: a function called on each time step to withdraw from investments 
- `invest!`: a function called on each time step to invest money into investments 
- `update_income!`: a function called on each time step to update income sources 
- `update_inflation!`: a function called on each time step to compute inflation 
- `update_interest!`: a function called on each time step to compute interest on investments
- `update_net_worth!`: a function called on each time step to compute net worth 
- `log!`: a function called on each time step to log data

Each function is assigned a default method with default arguments. Note that in advanced applications, you can specify a new model type and `update!` to execute a different sequence of update functions. The update functions listed above will suffice for a wide range of use cases.

## Optional Update Function Parameters

Each update function described in the previous section has default parameter values which can be overwritten. For example, we could specify a set of parameters `kw_income = (X₁ = x₁, X₂ = x₂, ..., Xₙ = xₙ)` to pass the function `update_income!`. The keyword for each update function is given below: 

- `kw_income`: optional keyword arguments passed to `update_income!`
- `kw_withdraw`: optional keyword arguments passed to `withdraw!`
- `kw_invest`: optional keyword arguments passed to `invest!`
- `kw_inflation`: optional keyword arguments passed to `update_inflation!`
- `kw_interest`: optional keyword arguments passed to `update_interest!` 
- `kw_net_worth`: optional keyword arguments passed to `update_net_worth!`
- `kw_log`: optional keyword arguments passed to `log!`

# Example 

Now that we have explained the API for configuring simulations, we are now in the position to develop a simple, retirement simulation based on the following scenario:

*Let's assume that you are 27 years old with an initial investment of `$`10,000, and you invest `$`625 each month until early retirement at age 60. Assume further that the yearly interest rate on investments is .07, and inflation is .035. Upon reaching 60 years old, we will assume you will withdraw `$`2,200 per month until reaching age 85.*

## Load Packages

The first step is to load the required packages. The code block below loads the package `RetirementPlanners` to configure and run the retirement simulation, and the package `Plots` to visualize the results. 

```@example basic 
using RetirementPlanners
using Plots
```

## Configure Simulation

In this section, we will configure the simulation based on the scenario described above. As shown below, all of the configuration details will be defined in a data structure named `config`.

### Required Parameters

Based on the scenario above, we will use the following required parameters: 

- `Δt`: $\frac{1}{12}$
- `start_age`: $27$
- `duration`: $58$
- `start_amount`: $\$10,000$

### Optional Update Functions

In this simple simulation, we use several, simple update functions pre-fixed with the word `fixed`. As the names suggest, these simplified functions use fixed quantities in the simulation. However, for `update_net_worth!` and `log!`, we will use the default update functions. Each update function is described below:

- `fixed_withdraw`: withdraw a fixed amount from investments on each time step starting at a specified age
- `fixed_investment`: invest a fixed amount on each time step until a specified age is reached
- `fixed_income`: recieve a fixed income (e.g., social security, or pension) on each time step starting at a specified age
- `fixed_inflation`: a fixed yearly inflation rate used to adjust interest (i.e., growth) earned on investments
- `fixed_interest`: a fixed yearly interest rate earned on intestments 
- `default_net_worth`: computes net worth on each time step based on inflation, interest, investments, and withdraws. 
- `log!`: records interest rate, inflation rate, and net worth on each time step

Note: you can view additional documentation for the update functions above via `? function_name` in the REPL, or by referencing the [API](./api.md/#Update-Methods).

### Optional Update Function Parameters 

Putting all of this information together, we get the following configuration:

```@example basic 
config = (
    # time step in years
    Δt = 1 / 12,
    # starting age of simulation
    start_age = 25,
    # duration of simulation
    duration = 58,
    # initial investment amount 
    start_amount = 10_000,
    # withdraw function
    withdraw! = fixed_withdraw,
    # invest function
    invest! = fixed_invest,
    # function for updating inflation
    update_inflation! = fixed_inflation,
    # function for updating interest (growth)
    update_interest! = fixed_interest,
    # invest parameters
    kw_invest = (
        invest_amount = 625.0,
        end_age = 60,
    ),
    # interest parameters
    kw_interest = (
        interest_rate = .07,
    ),
    # inflation parameters
    kw_inflation = (
        inflation_rate = .035,
    ),
    # withdraw parameters
    kw_withdraw = (
        withdraw_amount = 2200.0,
        start_age = 60,
    )
)
```
## Construct Model 

Now that the model settings have been configured, we can create the model. To do so, we will pass the configuration settings to the model constructor. 

```@example basic 
model = Model(; config...)
```

The output above summarizes the configuration of the `Model` object. First, we can see the provided inputs at the top of the table. The field called `state` stores current values of the system for each time step, including investment amount, and net worth. You can see the details of the `State` object by expanding the menu below.

```@raw html
<details>
<summary><b>Show State</b></summary>
```
```@example basic
model.state
```
```@raw html
</details>
```

## Setup Logger

The next step is to initialize the data logger. On each time step, the data logger stores the following quantities: 

- annualized interest rate
- annualized inflation rate
- net worth
- income summed across all sources

The `Logger` object requires two inputs: 

- `n_steps`: the total number of time steps in one simulation
- `n_reps`: the total repetitions of the simulation. 

The total number of time steps can be found by getting the length of the time steps. In this simple scenario, we will set `n_reps=1` because the simulation is deterministic (i.e., it provides the same result each time). 

```@example basic 
times = get_times(model)
n_steps = length(times)
n_reps = 1
logger = Logger(; n_reps, n_steps)
```

## Run Simulation

Now that we have specified the parameters of the simulation, we can use the function `simulate!` to generate quantities of interest and save them to the `Logger` object. As shown below, `simulate!` requires our `Model` object, `Logger` object, and the number of repetitions, `n_reps`. 

```@example basic
simulate!(model, logger, n_reps)
```

## Visualize the Results

The code block below plots net worth as a function of age. The time steps are contained in `times` and net worth is contained within the `Logger` object. 

```@example basic 
plot(times, logger.net_worth, grid=false, label=false, xlabel="Age", ylabel="Net Worth")
```

Based on the assumptions we have made, you will have `$`219,771 remaining in investments at age 85. Needless to say, this simulation is too simplistic stress test your financial situation. Perhaps the most significant limitation is that is deterministic: investments, withdraws, infation, and interest are fixed throughout. In actuality, these values vary across time, thus introducing uncertainty into the planning process. The [advanced example](advanced_example.md) will show you how to introduce random variables into the simulation to account for various sources of uncertainty.
