```@setup basic
using Plots
using RetirementPlanners
```
# Overview

The purpose of this example is to illustrate how to use `RetirementPlanners.jl` in a simple scenario. As such, the goal is to understand the API rather than create the most realistic simulation of investment performance. For more realistic examples, please read the documentation for [intermediate example](intermediate_example.md) and [advanced example](advanced_example.md). 

# Example 

 The example below uses simple functions for updating quanties such as inflation, interest, and net worth through out the simulation. Each update function has default parameter values which we will change. You can change the default functions either by selecting predefined functions described in the [API](./api.md/#Update-Methods), or by defining your own custom functions. 

## Load Packages

The first step is to load the packages required for simulating a retirement scenario and analyzing the results. With the keyword `using`, the code block below loads `RetirementPlanners` to run the simulation, and `Plots` to plot the results of the simulation. 

```@example basic 
using Plots
using RetirementPlanners
```

## Configure Model Options

In the code block below, we will specify various parameters of the model in the data structure named `config`. The configuration includes the following information three basic types of information. We will go through each in turn. 

### Required Parameters

The model requires numerous parameters to control the timing of events and the initial investment value. Here is a list of the required parameters:

- `Δt`: the time step in years 
- `start_age`: your age in years at the beginning of the simulation
- `duration`: the number of years to simulate
- `start_amount`: the amount of money you have in investments at the beginning of the simulation

### Optional Functions

The descrete time simulation is governed by seven update functions. Each function is assigned a default method with default arguments. The update functions are as follows:

- `withdraw!`: a function called on each time step to withdraw from investments 
- `invest!`: a function called on each time step to invest money into investments 
- `update_income!`: a function called on each time step to update income sources 
- `update_inflation!`: a function called on each time step to compute inflation 
- `update_interest!`: a function called on each time step to compute interest on investments
- `update_net_worth!`: a function called on each time step to compute net worth 
- `log!`: a function called on each time step to log data

### Update Parameters

Each update function described in the previous section has default parameter values which can be overwritten. For example, we could specify a set of parameters `kw_income = (X₁ = x₁, X₂ = x₂, ..., Xₙ = xₙ)` to pass parameters to the function `update_income!`. The keyword for each update function is given below: 

- `kw_income`: optional keyword arguments passed to `update_income!`
- `kw_withdraw`: optional keyword arguments passed to `withdraw!`
- `kw_invest`: optional keyword arguments passed to `invest!`
- `kw_inflation`: optional keyword arguments passed to `update_inflation!`
- `kw_interest`: optional keyword arguments passed to `update_interest!` 
- `kw_net_worth`: optional keyword arguments passed to `update_net_worth!`
- `kw_log`: optional keyword arguments passed to `log!`

## Construct Model 

We will illustrate how to setup and run a simulation with a simple example. Let's assume that you are 25 years old with an initial investment `of $10,000`, and you invest `$2,000` each month until early retirement at age 40. Assume further that the yearly interest rate on investments is `.08`, which is inflation adjusted by a yearly rate of `.035`. Upon reaching 40 years old, we will assume you will draw `$2,200` per month.  The simulation will update on a monthy basis and continue for 55 years until you reach age 80. For this simple example, we will use the following functions:

- `fixed_withdraw`: withdraw a fixed amount from investments on each time step starting at a specified age
- `fixed_investment`: invest a fixed amount on each time step until a specified age is reached
- `fixed_income`: recieve a fixed income (e.g., social security, or pension) on each time step starting at a specified age
- `fixed_inflation`: a fixed yearly inflation rate used to adjust interest (i.e., growth) earned on investments
- `fixed_interest`: a fixed yearly interest rate earned on intestments 
- `default_net_worth`: computes net worth on each time step based on inflation, interest, investments, and withdraws. 
- `log!`: records interest rate, inflation rate, and net worth on each time step

You can view additional documentation for the update functions above via `? function_name` in the REPL, or referencing the [API](./api.md/#Update-Methods).

Putting all of this information together, we get the following configuration:

```@example basic 
config = (
    Δt = 1 / 12,
    start_age = 25,
    duration = 55,
    start_amount = 10_000,
    withdraw! = fixed_withdraw,
    invest! = fixed_investment,
    update_inflation! = fixed_inflation,
    update_interest! = fixed_interest
)
```

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
logger = Logger(;n_reps, n_steps)
```

## Run Simulation

Now that we have specified the parameters of the simulation, we can use the function `simulate!` to generate retirement numbers and save them to the `Logger` object. As shown below, `simulate!` requires our `Model` object, `Logger` object, and the number of repetitions. 

```@example basic
simulate!(model, logger, n_reps)
```

The code block below plots net worth as a function of age. The time steps are contained in `times` and net worth is contained within the `Logger` object. 

```@example basic 
plot(times, logger.net_worth, grid=false, xlabel="Age", ylabel="Net Worth")
```

Based on the assumptions we have made, you will have `$`263,027 remaining in investments at age 80. Needless to say, this simulation is too simplistic to be of much use. Perhaps the most significant limitation is that is deterministic: investments, withdraws, infation, and interest are fixed throughout. In actuality, these values vary across time, thus introducing uncertainty into the planning process. The [intermediate example](intermediate_example.md) and the [advanced example](advanced_example.md) make progress towards overcoming these limitations.
