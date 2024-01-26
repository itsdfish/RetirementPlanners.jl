"""
    GBM{T<:Real} <: ContinuousUnivariateDistribution

A distribution object for Geometric Brownian Motion (GBM), which is used to model 
growth of stocks. 

# Fields 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
mutable struct GBM{T<:Real} <: ContinuousUnivariateDistribution
    μ::T
    σ::T
    x0::T
    x::T 
end

Base.broadcastable(dist::GBM) = Ref(dist)

"""
    GBM(;μ, σ, x0, x=x0)

A constructor for the Geometric Brownian Motion (GBM) model, which is used to model 
growth of stocks. 

# Keywords 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate 
- `x0::T=1.0`: initial value of stock 
- `x::T=x0`: current value
"""
function GBM(;μ, σ, x0=1.0, x=x0)
    μ,σ,x0,x = promote(μ, σ, x0, x)
    return GBM(μ, σ, x0, x)
end

"""
    increment!(dist::GBM, Δt)

Increment the stock price over the period `Δt`.

# Arguments 

- `dist::GBM`: a distribution object for Geometric Brownian Motion 
- `x`: current stock value 

# Keywords

- `Δt`: the time step for Geometric Brownian Motion
"""
function increment!(dist::GBM; Δt)
    (;μ,σ,x) = dist 
    dist.x += x * (μ * Δt + σ * randn() * √(Δt))
    return nothing
end

function rand(dist::GBM, n_steps, n_reps; Δt)
    return [rand(dist, n_steps; Δt) for _ ∈ 1:n_reps]
end

function rand(dist::GBM, n_steps; Δt)
    prices = fill(0.0, n_steps + 1)
    dist.x = dist.x0 
    prices[1] = dist.x
    for i ∈ 2:(n_steps+1)
        increment!(dist; Δt)
        prices[i] = dist.x
    end
    return prices 
end

mean(dist::GBM, t) = exp(dist.μ * t)
var(dist::GBM, t) = exp(2 * dist.μ * t) * (exp(dist.σ^2 * t) - 1)
std(dist::GBM, t) = √(var(dist, t))