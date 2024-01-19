```@setup intermediate
using Distributions
using Plots
using RetirementPlanners
```
# Overview

The purpose of this example is to illustrate how to use RetirementPlanners.jl in the simplest scenario. The example below uses simple default functions for updating quanties such as inflation, interest, and net worth during the simulation. The [advanced example](advanced_example.md) demonstates the process of overwriting default update functions with custom functions. 

# Example 

## Load Packages

The first step is to load the packages required for simulating a retirement scenario and analyzing the results. With the `using` keyword, the code block below loads `RetirementPlanners` to run the simulation, and `Plots` to plot the results of the simulation. 

```@example intermediate 
using Plots
using RetirementPlanners
```

## Create Model

The code block below shows the minimum setup required to create a model object, which maintains various parameters of the simulation, including timing variables and update functions. You must enter a value for the following keyword parameters:

- `Δt`: the time step in years 
- `start_age`: the age of the person at the beginning of the simulation
- `duration`: the number of years to simulate
- `start_amount`: the amount of money in investments at the beginning of the simulation

In this basic example, we will assume the subject starts saving for retirement at age 25, and begins with a modest amount of `$`10,000. The simulation will update on a monthy basis and continue for 45 years, or until the subject is 80 years old. 

```@example intermediate 
model = Model(;
    Δt = 1 / 12,
    start_age = 25,
    duration = 45,
    start_amount = 10_000,
    withdraw! = variable_withdraw,
    invest! = variable_investment,
    update_income! = variable_income,
    update_inflation! = variable_inflation,
    update_interest! = variable_interest 
)
```

The output above summarizes the configuration of the `Model` object. First, we can see the provided inputs at the top of the table. The field called `state` stores current values of the system for each time step, including investment amount, and net worth. The next seven fields correspond to default update functions called interally by a function called `update!`. Many users will find the default update functions to be overly simplistic. 

## Configure Update Options

The seven update functions described above include default input values for relevant quantities, such as interest rate on investments (see `? function_name` for details). However, you can optionally overwrite the default values by passing a configuration data structure to the function `simulate!`, as described below. 

The configuration data structure is a nested `NamedTuple` (i.e., immutable keyword-value pairs), where the keywords in the first level correspond to the keyword inputs of the update functions. For example, the keyword `kw_invest` (short for keyword invest) is a set of keywords passed to the function `fixed_investment`.

In our running scenario, we will assume the subject invests `$`2,000 each month until early retirement at age 40. The yearly interest rate on investments is `.08`, which is inflation adjusted by a yearly rate of `.035`. Upon retirement at age 40, the subject withdraws `$`2,200 per month.  

```@example intermediate 
config = (
    # invest parameters
    kw_invest = (
        distribution = Normal(2000, 500),
        end_age = 40,
    ),
    # interest parameters
    kw_interest = (
        distribution = Normal(.08, .08),
    ),
    # inflation parameters
    kw_inflation = (
        distribution = Normal(.035, .015),
    ),
    # withdraw parameters 
    kw_withdraw = (
        distribution = Normal(2200, 500),
        start_age = 40,
    )
 )
```
## Setup Logger

The next step is to initialize the data logger. On each time step, the data logger stores the following quantities: annualized interest rate, annualized inflation rate, and net worth. The `Logger` object requires two inputs: `n_steps`: the total number of time steps in one simulation, and `n_reps`: the total repetitions of the simulation. The total number of time steps can be found by getting the length of the time steps. In this simple scenario, we will set `n_reps=1` because the simulation is deterministic (i.e., it provides the same result each time). 

```@example intermediate 
times = get_times(model)
n_steps = length(times)
n_reps = 1
logger = Logger(;n_reps, n_steps)
```

## Run Simulation

Now that we have specified the parameters of the simulation, we can use the function `simulate!` to generate retirement numbers and save them to the `Logger` object. As shown below, `simulate!` requires our model object, the logger, and the number of repetitions. The optional configuration object is passed as a variable keyword using `; config...`, which maps the nested keywords in the `NamedTuple` to the corresponding keywords defined in the `simulate!` method signature. 

```@example intermediate
simulate!(model, logger, n_reps; config...)
```

The code block below plots net worth as a function of age. The time steps are contained in `times` and net worth is contained within the `Logger` object. 

```@example intermediate 
plot(times, logger.net_worth, xlabel="Age", ylabel="Net Worth")
```