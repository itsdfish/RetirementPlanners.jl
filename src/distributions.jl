"""
    AbstractGBM <: ContinuousUnivariateDistribution

Abstract type for simulating investment growth using Geometric Brownian Motion. 
"""
abstract type AbstractGBM <: ContinuousUnivariateDistribution end

"""
    GBM{T<:Real} <: AbstractGBM

A distribution object for Geometric Brownian Motion (GBM), which is used to model 
growth of stocks. 

# Fields 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
mutable struct GBM{T<:Real} <: AbstractGBM
    μ::T
    σ::T
    x0::T
    x::T 
end

Base.broadcastable(dist::AbstractGBM) = Ref(dist)

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
    increment!(dist::AbstractGBM, Δt)

Increment the stock price over the period `Δt`.

# Arguments 

- `dist::GBM`: a distribution object for Geometric Brownian Motion 
- `x`: current stock value 

# Keywords

- `Δt`: the time step for Geometric Brownian Motion
"""
function increment!(dist::AbstractGBM; Δt)
    (;μ,σ,x) = dist 
    dist.x += x * (μ * Δt + σ * randn() * √(Δt))
    return nothing
end

"""
    rand(dist::AbstractGBM, n_steps, n_reps; Δt)

Simulate a random trajector of a Geometric Brownian motion process. 

# Arguments 

- `dist::GBM`: a distribution object for Geometric Brownian Motion 
- `n_steps`: the number of discrete time steps in the simulation 
- `n_reps`: the number of times the simulation is repeated 

# Keywords

- `Δt`: the time step for Geometric Brownian Motion
"""
function rand(dist::AbstractGBM, n_steps, n_reps; Δt)
    return [rand(dist, n_steps; Δt) for _ ∈ 1:n_reps]
end

function rand(dist::AbstractGBM, n_steps; Δt)
    prices = fill(0.0, n_steps + 1)
    dist.x = dist.x0 
    prices[1] = dist.x
    for i ∈ 2:(n_steps+1)
        increment!(dist; Δt)
        prices[i] = dist.x
    end
    return prices 
end

function reset!(dist::AbstractGBM)
    dist.x0 = 1.0
    dist.x = 1.0
    return nothing 
end

mean(dist::AbstractGBM, t) = exp(dist.μ * t)
var(dist::AbstractGBM, t) = exp(2 * dist.μ * t) * (exp(dist.σ^2 * t) - 1)
std(dist::AbstractGBM, t) = √(var(dist, t))

function fit(dist::Type{<:AbstractGBM}, ts; Δt)
    ts = log.(ts)
    _μ = estimate_μ(dist, ts; Δt)
    σ = estimate_σ(dist, ts; Δt)
    μ = convert_μ(_μ, σ)
    return μ, σ
end

# series = [1,1.2,1.4,1.5]
# Δt = 1 / 12
# estimate_μ(dist, series; Δt = 1/12) == 5.44
function estimate_μ(dist::Type{<:AbstractGBM}, ts; Δt)
    x = Δt:Δt:length(ts)*Δt 
    total = sum((1 / Δt) * (x.^2))
    return sum((1/total) * (1 / Δt) * (x .* ts))
end

function convert_μ(μ, σ)
    return μ + .50 * σ^2 
end

# series = [1,1.2,1.4,1.5]
# Δt = 1 / 12
# estimate_σ(gbm, ts; Δt) ≈ 0.5196152422706631
function estimate_σ(gbm, ts; Δt)
    n = length(ts)
    return √(sum(diff(ts).^2) / (n * Δt))
end
# 3.5
# convert_μ(1.5, 2)

"""
    VarGBM{T<:Real} <: AbstractGBM

A distribution object for variable Geometric Brownian Motion (vGBM), which is used to model 
growth of stocks. Unlike GBM, vGBM selects growth rate (`μ`) and volitility (`σ`) parameters from a normal distribution
on each simulation run to capture uncertainy in these parameters. 

# Fields 

- `μ::T`: growth rate sampled from normal distribution
- `σ::T`: volitility in growth rate sampled from truncated normal distribution 
- `αμ::T`: mean of growth rate distribution 
- `ασ::T`: mean of volitility of growth rate distribution 
- `ημ::T`: standard deviation of growth rate distribution 
- `ησ::T`: standard deviation of volitility of growth rate distribution 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
mutable struct VarGBM{T<:Real} <: AbstractGBM
    μ::T
    σ::T
    αμ::T 
    ασ::T
    ημ::T
    ησ::T
    x0::T
    x::T 
end

"""
    VarGBM(; αμ, ασ, ημ, ησ, x0=1.0, x=x0)

A constructor for variable Geometric Brownian Motion (vGBM), which is used to model 
growth of stocks. Unlike GBM, vGBM selects growth rate (`μ`) and volitility (`σ`) parameters from a normal distribution
on each simulation run to capture uncertainy in these parameters. 

# Keywords 

- `αμ::T`: mean of growth rate distribution 
- `ασ::T`: mean of volitility of growth rate distribution 
- `ημ::T`: standard deviation of growth rate distribution 
- `ησ::T`: standard deviation of volitility of growth rate distribution 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
function VarGBM(; αμ, ασ, ημ, ησ, x0=1.0, x=x0)
    μ,σ,x0,x = promote(αμ, ασ, ημ, ησ, x0, x)
    return VarGBM(zero(αμ), zero(αμ), αμ, ασ, ημ, ησ, x0, x)
end

function reset!(dist::VarGBM)
    dist.x0 = 1.0
    dist.x = 1.0
    dist.μ = rand(Normal(dist.αμ, dist.ημ))
    dist.σ = rand(truncated(Normal(dist.ασ, dist.ησ), 0.0, Inf))
    return nothing 
end