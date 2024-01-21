"""
    GBM{T<:Real} <: ContinuousUnivariateDistribution

A distribution object for Geometric Brownian Motion (GBM), which is used to model 
growth of stocks. 

# Fields 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate 
- `x0::T`: initial value of stock 
"""
mutable struct GBM{T<:Real} <: ContinuousUnivariateDistribution
    μ::T
    σ::T
    x0::T 
end

"""
    GBM(;μ, σ, x0)

A constructor for the Geometric Brownian Motion (GBM) model, which is used to model 
growth of stocks. 

# Keywords 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate 
- `x0::T`: initial value of stock 
"""
function GBM(;μ, σ, x0)
    μ,σ,x0 = promote(μ, σ, x0)
    return GBM(μ, σ, x0)
end

"""
    increment(dist::GBM, x; Δt)

Increment the stock price over the period `Δt`.

# Arguments 

- `dist::GBM`: a distribution object for Geometric Brownian Motion 
- `x`: current stock value 

# Keywords

- `Δt`: the time step for Geometric Brownian Motion
"""
function increment(dist::GBM, x; Δt)
    (;μ,σ) = dist 
    return x * (μ * Δt + σ * randn() * √(Δt))
end

function rand(dist::GBM, n_steps, n_reps; Δt)
    return [rand(dist, n_steps; Δt) for _ ∈ 1:n_reps]
end

function rand(dist::GBM, n_steps; Δt)
    x = dist.x0 
    prices = fill(0.0, n_steps + 1)
    prices[1] = x
    for i ∈ 2:(n_steps+1)
        x += increment(dist, x; Δt)
        prices[i] = x
    end
    return prices 
end