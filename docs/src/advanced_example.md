```@setup intermediate
using Distributions
using Plots
using RetirementPlanners
```
# Overview

The goal of this example is to illustrate how to setup a realistic simulation to stress test your retirement plan. This example builds upon the [basic example](basic_example.md) and attempts to overcome some of its limitations. The primary limitation with the basic example is its failure to capture uncertainty in various quantaties, such as interest rates, and the amount withdrawn from investments during retirement. To capture the inherent uncertainty of future events, we will sample these quantities from specified distributions. In so doing, we will be able to stress test the retirement plan under a wide variety of uncertain scenarios to determine the survival probability as a function of time. This will allow us to answer questions, such as *what is the chance of running out of money after 20 years?*

# Example 

## Scenario

In this example, we will assume that you have completed the [basic example](basic_example.md) and have a rudimentary understanding of the API. If that is not the case, please review the basic example before proceeding. We will use the same scenario described in the basic example, which is reproduced below for your convienence: 

*Let's assume that you are 27 years old with an initial investment of `$`10,000, and you invest `$`625 each month until early retirement at age 60. Assume further that the yearly interest rate on investments is .07, and inflation is .035. Upon reaching 60 years old, we will assume you will withdraw `$`2,200 per month until reaching age 85.*

## Load Packages

The first step is to load the required packages. In the code block below, we will load `RetirementPlanners` to run the retirement simulation, `Distributions` to make the simulation stochastic, and `Plots` to plot the results of the simulation. 

```@example advanced
using Distributions 
using Plots
using RetirementPlanners
```

## Configure Update Options

The configuration for the simulation is presented below. 

```@example advanced 
# configuration options
config = (
    # time step in years 
    Δt = 1 / 12,
    # start age of simulation 
    start_age = 27,
    # duration of simulation in years
    duration = 58,
    # initial investment amount 
    start_amount = 10_000,
    # withdraw parameters 
    kw_withdraw = (withdraws = Transaction(;
        start_age = 60,
        amount = AdaptiveWithdraw(;
            min_withdraw = 2200,
            percent_of_real_growth = 0.15,
            income_adjustment = 0.0,
            volitility = 0.05
        )
    ),),
    # invest parameters
    kw_invest = (investments = Transaction(;
        start_age = 27,
        end_age = 60,
        amount = Normal(625, 100)
    ),),
    # interest parameters
    kw_market = (
        # dynamic model of the stock market
        gbm = VarGBM(;
            # non-recession parameters
            αμ = 0.070,
            ημ = 0.010,
            ασ = 0.035,
            ησ = 0.010,
            # recession parameters
            αμᵣ = -0.05,
            ημᵣ = 0.010,
            ασᵣ = 0.035,
            ησᵣ = 0.010
        ),
        # recession: age => duration
        recessions = Dict(0 => 0)
    ),
    # inflation parameters
    kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
    # income parameters 
    kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
)
```

Notice that many parameters are the same as those from the basic example. However, there are importance differences, which we will examine below. 

### Adaptive Withdraw

In this simulation, we will use the type `AdaptiveWithdraw` to specify the withdraw strategy. Rather than withdrawing a fixed amount each time step, `AdaptiveWithdraw` will withdraw more money during periods of high growth, subject to the contraint that a minimum required amount is withdrawn if funds permit.

`AdaptiveWithdraw` has the following fields:
- `start_age`: specifies age at which funds are withdrawn from the investments.
- `income_adjustment`: allows you to subtract a portion of the your income (e.g., social security or pension) from the investment amount. Doing so, would provide the opportunity for the investments to grow. 
- `percent_of_real_growth`: specifies the percent of real growth withdrawn. If real growth in one month was `$`6,000, and `percent_of_real_growth = .5`, the withdraw amount would be `$`3,000. However, the withdraw amount cannot be less than the amount specified by the parameter `min_withdraw` (unless the total investments are less than `min_withdraw`). 
- `volitility` controls the variability of the withdraw amount. The variance is proportional to the mean withdraw amount. 

### Investment

In the advanced example, we will sample each investment contribution from a normal distribution to reflect fluctuations due to factors such as, unexpected expenses and bonuses. This is accomplished by setting the `amount` field of `Transaction` to `Normal(μ, σ)`. `Normal` has the following parameters:

- `μ`: the average contribution
- `σ`: the standard deviation of the contribution

### Interest

In this example, we will simulate growth the stock market using a stochastic process model called Geometric Brownian Motion (GBM). One advantage of GBM is that it provides a more accurate description of the temporal dynamics of stock market growth: the value of the stock market is noisy, but current value depends on the previous value.  Below, we will use the function `dynamic_interest` to simulate stock market growth with the GBM. A standard GBM has two parameters:

- `μ`: growth rate
- `σ`: volitility in growth rate

More information can be found by expanding the details option below.
```@raw html
<details>
<summary><b>Show Details</b></summary>
```
Brownian motion component of GBM is based on random movement of particles in space when no force is present to move the particles in a specific direction. Although particle physics seems disconnected from stock market behavior, it turns out to be a reasonable model because there is inherent randomness in stock prices as well as a general tendency to grow. If we add a growth rate parameter to Brownian motion and force the price to change proportially to its current value, the result is the GBM. The stochastic differential equation for the GBM is given by:

``X(t) = X(t)[ \mu dt + s \sqrt{dt}],``

where ``X(t)`` is the stock market value at time ``t``, ``dt`` is the infintesimal time step,  ``\mu`` is the average growth rate, and ``s \sim \mathrm{normal}(0,\sigma)`` is normally distributed noise with standard deviation ``\sigma``. The stochastic differential equation has two terms:

- ``\mu dt``: represents the average growth rate of the stock market. 
- ``s \sqrt{dt}``: represents the diffusion or *jitter* in the growth rate, which sometimes causes the price to increase or decrease more than the average growth rate. 

An important implication of multipling the two terms on the right hand side by ``X(t)`` is that growth and volitiliy scale with the current price, and the price cannot be negative. The code block below illustrates how to simulate and plot 10 trajectories of the GBM. The growth rate is ``\mu=.07`` with a standard deviation of ``\sigma=.07``, indicating moderately high volitility. 
```@raw html
</details>
```

The figure below shows 10 example trajectories of GBM over a 10 year period. The average growth rate is 10% with moderate volitility of 7%. 
```@example advanced 
gdm = GBM(; μ = .10, σ = .07)
trajectories = rand(gdm, 365 * 10, 10; Δt = 1 / 365)
plot(trajectories, leg=false, grid=false)
```

Although we set parameters `μ` and `σ` to plausible values, there are other plausible values we could have selected. Setting `μ` to .07 is reasonable (albiet somewhat pessimistic), but setting `μ` to .11 would be reasonable also. In an effort to account for uncertainty in growth rate and volitility, we will use a variation of GBM in which `μ` and `σ` are sampled from a distribution for each simulation of a 58 year period. `VarGBM` has four required parameters:

- `αμ`: mean of growth rate distribution
- `ασ`: mean of volitility of growth rate distribution
- `ημ`: standard deviation of growth rate distribution
- `ησ`: standard deviation of volitility of growth rate distribution

In addition, you may optionally specify corresponding parameters for periods of recession: `αμᵣ`, `ημᵣ`, `ασᵣ`, `ησᵣ`. One advantage of specifying the timing of recessions manually is to examine sequence of return risk. The timing of a recession is important because it is more difficult to recover if it occurs near the beginning of retirement. The time and duration of a recession can be specified by passing a dictionary called `recession`. Note that recessions may emerge naturally from GBM under suitible parameters. 

## Create Model Object 

Now that we have configured the parameters of the simulation, we are now in the position to create the model object:

```@example advanced 
model = Model(; config...)
```

## Setup Logger

The next step is to initialize the data logger. On each time step, the data logger stores the following quantities: annualized interest rate, annualized inflation rate, and net worth. The `Logger` object requires two inputs: `n_steps`: the total number of time steps in one simulation, and `n_reps`: the total repetitions of the simulation. The total number of time steps can be found by getting the length of the time steps. In this simple scenario, we will repeat the simulation `10,000` times to provide a stable estimate of the variability in the investment and retirement conditions. 

```@example advanced 
times = get_times(model)
n_reps = 1000
n_steps = length(times)
logger = Logger(; n_steps, n_reps)
```

## Run Simulation

Now that we have specified the parameters of the simulation, we can use the function `simulate!` to generate retirement numbers and save them to the `Logger` object. As shown below, `simulate!` requires our model object, the logger, and the number of repetitions. 

```@example advanced
simulate!(model, logger, n_reps)
```

One of the biggest changes from the basic example is the use of random values for withdraw and interest. In the code block below, we will use the function `plot_gradient` to represent variability in networth projections. Darker values correspond to higher density or more likely trajectories.   

```@raw html
<details>
<summary><b>Show Details</b></summary>
```
```@example advanced 
survival_probs = mean(logger.net_worth .> 0, dims = 2)
survival_plot = plot(
    times,
    survival_probs,
    leg = false,
    xlabel = "Age",
    grid = false,
    ylabel = "Survival Probability",
    xlims = (config.kw_withdraw.withdraws.start_age, times[end]),
    ylims = (0.5, 1.05),
    color = :black
)

# networth as a function of time. Darker shading indicates more likely values
net_worth_plot = plot_gradient(
    times,
    logger.net_worth;
    xlabel = "Age",
    ylabel = "Investment Value",
    n_lines = 0
)

# growth rate distribution across repetitions of the simulation 
growth = logger.interest[:]
interest_plot = histogram(
    growth,
    norm = true,
    xlabel = "Market Growth",
    ylabel = "Density",
    color = RGB(148 / 255, 173 / 255, 144 / 255),
    bins = 100,
    label = false,
    grid = false,
    xlims = (-0.7, 0.7)
)
vline!(
    interest_plot,
    [0.0],
    color = :black,
    linewidth = 1.5,
    linestyle = :dash,
    label = false
)

# income as a function of time. 
income_plot = plot_gradient(
    times,
    logger.total_income;
    xlabel = "Age",
    ylabel = "Total Income",
    xlims = (config.kw_withdraw.withdraws.start_age, times[end]),
    n_lines = 0,
    color = :blue
)
```
```@raw html
</details>
```

```@example advanced
plot(survival_plot, net_worth_plot, interest_plot, income_plot, layout = (2, 2))
```

```@raw html
<details>
<summary><b>All Code</b></summary>
```
```julia
###############################################################################################################
#                                           load dependencies
###############################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Distributions
using Plots
using RetirementPlanners
###############################################################################################################
#                                           setup simulation
###############################################################################################################
# montly contribution 
contribution = (50_000 / 12) * 0.15
# configuration options
config = (
    # time step in years 
    Δt = 1 / 12,
    # start age of simulation 
    start_age = 27,
    # duration of simulation in years
    duration = 58,
    # initial investment amount 
    start_amount = 10_000,
    # withdraw parameters 
    kw_withdraw = (withdraws = Transaction(;
        start_age = 60,
        amount = AdaptiveWithdraw(;
            min_withdraw = 2200,
            percent_of_real_growth = 0.15,
            income_adjustment = 0.0,
            volitility = 0.05
        )
    ),),
    # invest parameters
    kw_invest = (investments = Transaction(;
        start_age = 27,
        end_age = 60,
        amount = Normal(contribution, 100)
    ),),
    # interest parameters
    kw_market = (
        # dynamic model of the stock market
        gbm = VarGBM(;
            # non-recession parameters
            αμ = 0.070,
            ημ = 0.010,
            ασ = 0.035,
            ησ = 0.010,
            # recession parameters
            αμᵣ = -0.05,
            ημᵣ = 0.010,
            ασᵣ = 0.035,
            ησᵣ = 0.010
        ),
        # recession: age => duration
        recessions = Dict(0 => 0)
    ),
    # inflation parameters
    kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
    # income parameters 
    kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
)
# setup retirement model
model = Model(; config...)
###############################################################################################################
#                                           run simulation
###############################################################################################################
times = get_times(model)
n_reps = 1000
n_steps = length(times)
logger = Logger(; n_steps, n_reps)
simulate!(model, logger, n_reps)
###############################################################################################################
#                                            plot results 
###############################################################################################################
# plot of survival probability as a function of time
survival_probs = mean(logger.net_worth .> 0, dims = 2)
survival_plot = plot(
    times,
    survival_probs,
    leg = false,
    xlabel = "Age",
    grid = false,
    ylabel = "Survival Probability",
    xlims = (config.kw_withdraw.withdraws.start_age, times[end]),
    ylims = (0.5, 1.05),
    color = :black
)

# networth as a function of time. Darker shading indicates more likely values
net_worth_plot = plot_gradient(
    times,
    logger.net_worth;
    xlabel = "Age",
    ylabel = "Investment Value",
    n_lines = 0
)

# growth rate distribution across repetitions of the simulation 
growth = logger.interest[:]
interest_plot = histogram(
    growth,
    norm = true,
    xlabel = "Market Growth",
    ylabel = "Density",
    color = RGB(148 / 255, 173 / 255, 144 / 255),
    bins = 100,
    label = false,
    grid = false,
    xlims = (-0.7, 0.7)
)
vline!(
    interest_plot,
    [0.0],
    color = :black,
    linewidth = 1.5,
    linestyle = :dash,
    label = false
)

# income as a function of time. 
income_plot = plot_gradient(
    times,
    logger.total_income;
    xlabel = "Age",
    ylabel = "Total Income",
    xlims = (config.kw_withdraw.withdraws.start_age, times[end]),
    n_lines = 0,
    color = :blue
)
plot(survival_plot, net_worth_plot, interest_plot, income_plot, layout = (2, 2))
```
```@raw html
</details>
```