```@setup intermediate
using Distributions
using Plots
using RetirementPlanners
```
# Overview

This example builds upon the [basic example](basic_example.md) and attempts to overcome some of its limitations. The primary limitation with the basic example is that it lacked the means to capture uncertainy in future events, such as interest rates, and the amount withdrawn from investments during retirement. To capture the inherent uncertainty of future events, we will sample these quantities from specified distributions. In so doing, we will be able to stress test the retirement plan under a wide variety of uncertain scenarios to determine the survival probability as a function of time. This will allow us to answer questions, such as *what is the chance of running out of money after 20 years?*

# Example 

## Load Packages

The first step is to load the packages required for simulating a retirement scenario and analyzing the results. In the code block below, we will load `RetirementPlanners` to run the simulation, `Distributions` to make the simulation stochastic, and `Plots` to plot the results of the simulation. 

```@example intermediate
using Distributions 
using Plots
using RetirementPlanners
```

## Create Model

The `Model` object defines the parameters and behavior of the retirement investment simulation. As in the basic example, you must enter a value for the following keyword parameters:

- `Δt`: the time step in years 
- `start_age`: the age of the person at the beginning of the simulation
- `duration`: the number of years to simulate
- `start_amount`: the amount of money in investments at the beginning of the simulation

In this example, we will use the same timing paramers used in the basic example: we will assume you start saving for retirement at age 25 with a modest initial amount of `$`10,000. The simulation will update on a monthy basis and continue for 55 years until you reach age 80. 

```@example intermediate 
model = Model(;
    Δt = 1 / 12,
    start_age = 25,
    duration = 55,
    start_amount = 10_000,
    withdraw! = variable_withdraw,
    invest! = variable_investment,
    update_income! = variable_income,
    update_inflation! = variable_inflation,
    update_interest! = variable_interest 
)
```

Unlike the basic example, you can see in the output above that we have overwritten the default update function with pre-defined update functions described in the [API](api.md). The function names are prefixed with `variable` to signify that they allow us to introduce variability in the simulation behavior by sampling relevant quantities from distributions specified by the user. The distribution can be any univariate distribution defined in [Distributions.jl](https://juliastats.org/Distributions.jl/stable/). In cases where the desired distribution is not available in `Distributions.jl`, you may use their API to create custom distribution types. You can find more details on these update functions in the [API](api.md)
or by typing `? function_name` in the the REPL. 

## Configure Update Options

We will specify the parameters of the update function in a nested configuration data structure, which passes keyword arguments to their corresponding update funtions. The configuration data structure is a nested `NamedTuple` (i.e., immutable keyword-value pairs), where the keywords in the first level correspond to the keyword inputs of the update functions. For example, the keyword `kw_invest` (short for keyword invest) is a set of keywords passed to the function `fixed_investment`.

The configuration data structure below defines distributions over quanties, such as investment and withdraw amount. Aside from drawling random values from probability distributions, the simulation is the same as that described in the [basic example](basic_example.md).

 The mean monthly investment follows a normal distribution with a mean of `$2,000` and a standard deviation of `$500` to reflect fluctuations in income and expenses. As before, investments are made until an early retirement at age 40. The yearly interest rate on investments has a mean of `.08` with a large standard deviation of `.08` to reflect inherent volitility in the stock market. The yearly inflation rate has a mean of `.035` and a standard deviation of `.015`. Upon retirement at age 40, we assume that you withdraw `$2,200` per month with a standard deviation of `$500` to reflect fluctuation in monthly expenses. 

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

The next step is to initialize the data logger. On each time step, the data logger stores the following quantities: annualized interest rate, annualized inflation rate, and net worth. The `Logger` object requires two inputs: `n_steps`: the total number of time steps in one simulation, and `n_reps`: the total repetitions of the simulation. The total number of time steps can be found by getting the length of the time steps. In this simple scenario, we will repeat the simulation `10,000` to provide a stable estimate of the variability in the investment and retirement conditions. 

```@example intermediate 
times = get_times(model)
n_steps = length(times)
n_reps = 10_000
logger = Logger(;n_reps, n_steps)
```

## Run Simulation

Now that we have specified the parameters of the simulation, we can use the function `simulate!` to generate retirement numbers and save them to the `Logger` object. As shown below, `simulate!` requires our model object, the logger, and the number of repetitions. The optional configuration object is passed as a variable keyword using `; config...`, which maps the nested keywords in the `NamedTuple` to the corresponding keywords defined in the `simulate!` method signature. 

```@example intermediate
simulate!(model, logger, n_reps; config...)
```

The code block below plots net worth as a function of age. The time steps are contained in `times` and net worth is contained within the `Logger` object. 

```@example intermediate 
plot(times, logger.net_worth[:,1:5], xlabel="Age", 
    leg=false, ylabel="Net Worth")
```

```@example intermediate
survival_probs = mean(logger.net_worth .> 0, dims=2)
plot(times, survival_probs,  leg=false, xlabel="Age (years)", 
    ylabel="Survival Probability", ylims = (0,1.05))
```