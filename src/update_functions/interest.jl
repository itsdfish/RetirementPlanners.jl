"""
    fixed_interest(model::AbstractModel, t; interest_rate = .07)

Returns a fixed interesting rate using a specified value.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `interest_rate = .07`: a constant rate of investment growth per year
"""
function fixed_interest(model::AbstractModel, t; interest_rate = .07)
    model.state.interest_rate = interest_rate
    return nothing
end

"""
    variable_interest(
        model::AbstractModel,
        t;
        distribution = Normal(.07, .05)
    )

Returns interest rate sampled from a specified distribution.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `distribution = Normal(.07, .05)`: the distribution of interest per year 
"""
function variable_interest(
        model::AbstractModel,
        t;
        distribution = Normal(.07, .05)
    )
    model.state.interest_rate = rand(distribution)
    return nothing
end

"""
    dynamic_interest(
        model::AbstractModel,
        t; 
        gbm=GBM(; μ=.07, σ=.05, x0=1)
    )
Models interest in the stock market as a geometric brownian motion processes. 

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keyword

- `gbm=GBM(; μ=.07, σ=.05, x0=1)`: a geometric brownian motion object with parameters 
`μ` reflecting mean growth rate, and `σ` reflecting volitility in growth rate. The parameter `x0`
sets an arbitrary scale. 
"""
function dynamic_interest(
        model::AbstractModel,
        t; 
        gbm=GBM(; μ=.07, σ=.05, x0=1)
    )
    Δt = model.Δt
    # reset model at the beginning of each simulation 
    if t == model.start_age + Δt
        gbm.x0 = 1.0 
        gbm.x = 1.0
    end
    x_prev = gbm.x 
    increment!(gbm; Δt)
    # annualized growth
    growth = (gbm.x / x_prev)^(1 / Δt) - 1
    model.state.interest_rate = growth 
    return nothing 
end