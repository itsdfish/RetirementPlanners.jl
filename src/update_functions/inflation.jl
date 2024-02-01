"""
    fixed_inflation(
        model::AbstractModel, 
        t;
        inflation_rate = .03
    )

Returns a fixed inflation rate of a specified value.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `inflation_rate = .03`: a constant rate of inflation per year
"""
function fixed_inflation(
        model::AbstractModel, 
        t;
        inflation_rate = .03
    )
    model.state.inflation_rate = inflation_rate
    return nothing
end

"""
    variable_inflation(
        model::AbstractModel,
        t;
        distribution = Normal(.03, .01)
    )

Returns an interest rate sampled from a specified distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `distribution = Normal(.03, .01)`: the distribution of inflation per year 
"""
function variable_inflation(
        model::AbstractModel,
        t;
        distribution = Normal(.03, .01)
    )
    model.state.inflation_rate = rand(distribution)
    return nothing
end

"""
    dynamic_inflation(
        model::AbstractModel, 
        t; 
        gbm = GBM(; μ=.03, σ=.01, x0=1)
    )

Models inflation in the stock market as a geometric brownian motion process. 

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keyword

- `gbm = GBM(; μ=.03, σ=.01, x0=1)`: a geometric brownian motion object with parameters 
`μ` reflecting mean growth rate, and `σ` reflecting volitility in growth rate. The parameter `x0`
sets an arbitrary scale. The function also supports `VarGBM`. 
"""
function dynamic_inflation(
        model::AbstractModel, 
        t; 
        gbm = GBM(; μ=.03, σ=.01, x0=1)
    )
    Δt = model.Δt
    # reset model at the beginning of each simulation 
    t ≈ model.start_age + Δt ? reset!(gbm) : nothing
    # set previous value
    x_prev = gbm.x 
    increment!(gbm; Δt)
    # annualized growth
    growth = (gbm.x / x_prev)^(1 / Δt) - 1
    model.state.inflation_rate = growth 
    return nothing 
end