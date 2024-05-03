"""
    AbstractGBM <: ContinuousUnivariateDistribution

Abstract type for simulating investment growth using Geometric Brownian Motion. 
"""
abstract type AbstractGBM <: ContinuousUnivariateDistribution end

"""
    GBM{T <: Real} <: AbstractGBM

A distribution object for Geometric Brownian Motion (GBM), which is used to model 
growth of stocks. 

# Fields 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate
- `μᵣ::T`: growth rate during recession 
- `σᵣ::T`: volitility in growth rate during recession 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
mutable struct GBM{T <: Real} <: AbstractGBM
    μ::T
    σ::T
    μᵣ::T
    σᵣ::T
    x0::T
    x::T
end

Base.broadcastable(dist::AbstractGBM) = Ref(dist)

"""
    GBM(; μ, σ, μᵣ = μ, σᵣ = σ, x0 = 1.0, x = x0)

A constructor for the Geometric Brownian Motion (GBM) model, which is used to model 
growth of stocks. 

# Keywords 

- `μ::T`: growth rate
- `σ::T`: volitility in growth rate
- `μᵣ::T`: growth rate during recession 
- `σᵣ::T`: volitility in growth rate during recession 
- `x0::T=1.0`: initial value of stock 
- `x::T=x0`: current value

# Example 

```julia 
using RetirementPlanners

Δt = 1 / 100
n_years = 30
n_steps = Int(n_years / Δt)
n_reps = 5
times = range(0, n_years, length = n_steps + 1)
dist = GBM(; μ=.10, σ=.05, x0 = 1)
prices = rand(dist, n_steps, n_reps; Δt)
```
"""
function GBM(; μ, σ, μᵣ = μ, σᵣ = σ, x0 = 1.0, x = x0)
    return GBM(promote(μ, σ, μᵣ, σᵣ, x0, x)...)
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
function increment!(
    dist::AbstractGBM;
    Δt,
    t = 0,
    recession_onset = -1,
    recession_duration = 0,
    _...
)
    (; x) = dist
    μ′, σ′ = modify(dist, t, recession_onset, recession_duration)
    dist.x += x * (μ′ * Δt + σ′ * randn() * √(Δt))
    return nothing
end

function modify(dist::AbstractGBM, t, recession_onset, recession_duration)
    (; μ, μᵣ, σ, σᵣ) = dist
    if (t ≥ recession_onset) && (t < (recession_onset + recession_duration))
        return μᵣ, σᵣ
    end
    return return μ, σ
end

"""
    rand(dist::AbstractGBM, n_steps, n_reps; Δt)

Simulate a random trajector of a Geometric Brownian motion process. 

# Arguments 

- `dist::AbstractGBM`: a distribution object for Geometric Brownian Motion 
- `n_steps`: the number of discrete time steps in the simulation 
- `n_reps`: the number of times the simulation is repeated 

# Keywords

- `Δt`: the time step for Geometric Brownian Motion
"""
function rand(dist::AbstractGBM, n_steps, n_reps; Δt, kwargs...)
    return [rand(dist, n_steps; Δt, kwargs...) for _ ∈ 1:n_reps]
end

function rand(dist::AbstractGBM, n_steps; Δt, kwargs...)
    reset!(dist)
    prices = fill(0.0, n_steps + 1)
    prices[1] = dist.x
    for i ∈ 2:(n_steps + 1)
        increment!(dist; Δt, kwargs...)
        prices[i] = dist.x
    end
    return prices
end

function reset!(dist::AbstractGBM)
    dist.x = dist.x0
    return nothing
end

compute_total(dist::AbstractGBM) = sum(dist.x)

mean(dist::AbstractGBM, t) = exp(dist.μ * t)
var(dist::AbstractGBM, t) = exp(2 * dist.μ * t) * (exp(dist.σ^2 * t) - 1)
std(dist::AbstractGBM, t) = sqrt(var(dist, t))

function fit(dist::Type{<:AbstractGBM}, ts; Δt)
    ts = log.(ts)
    _μ = estimate_μ(dist, ts; Δt)
    σ = estimate_σ(dist, ts; Δt)
    μ = convert_μ(_μ, σ)
    return μ, σ
end

function estimate_μ(dist::Type{<:AbstractGBM}, ts; Δt)
    x = Δt:Δt:(length(ts) * Δt)
    total = sum((1 / Δt) * (x .^ 2))
    return sum((1 / total) * (1 / Δt) * (x .* ts))
end

function convert_μ(μ, σ)
    return μ + 0.50 * σ^2
end

function estimate_σ(gbm, ts; Δt)
    n = length(ts)
    return √(sum(diff(ts) .^ 2) / (n * Δt))
end

"""
    rebalance!(dist::AbstractGBM)

Rebalance portfolio. Not applicable by default. 

# Arguments
- `dist::AbstractGBM`: a distribution object for Geometric Brownian Motion 
"""
function rebalance!(dist::AbstractGBM)
    return nothing
end

"""
    VarGBM{T <: Real} <: AbstractGBM

A distribution object for variable Geometric Brownian Motion (vGBM), which is used to model 
growth of stocks. Unlike GBM, vGBM selects growth rate (`μ`) and volitility (`σ`) parameters from a normal distribution
on each simulation run to capture uncertainy in these parameters. 

# Fields 

- `μ::T`: growth rate sampled from normal distribution
- `σ::T`: volitility in growth rate during, sampled from truncated normal distribution
- `μᵣ::T`: growth rate during a recession sampled from normal distribution
- `σᵣ::T`: volitility in growth rate during a recession, sampled from truncated normal distribution
- `αμ::T`: mean of growth rate distribution 
- `ασ::T`: mean of volitility of growth rate distribution 
- `ημ::T`: standard deviation of growth rate distribution 
- `ησ::T`: standard deviation of volitility of growth rate distribution 
- `αμ::T`: mean of growth rate distribution during a recession
- `ασ::T`: mean of volitility of growth rate distribution during a recession
- `ημ::T`: standard deviation of growth rate distribution during a recession
- `ησ::T`: standard deviation of volitility of growth rate distribution during a recession 
- `x0::T`: initial value of stock 
- `x::T`: current value

# Constructor

    VarGBM(; αμ, ασ, ημ, ησ, x0=1.0, x=x0)
"""
mutable struct VarGBM{T <: Real} <: AbstractGBM
    μ::T
    σ::T
    μᵣ::T
    σᵣ::T
    αμ::T
    ασ::T
    ημ::T
    ησ::T
    αμᵣ::T
    ασᵣ::T
    ημᵣ::T
    ησᵣ::T
    x0::T
    x::T
end

"""
    VarGBM(; αμ, ασ, ημ, ησ, αμᵣ = αμ, ασᵣ = ασ, ημᵣ = 0, ησᵣ = 0, x0 = 1.0, x = x0)

A constructor for variable Geometric Brownian Motion (vGBM), which is used to model 
growth of stocks. Unlike GBM, vGBM selects growth rate (`μ`) and volitility (`σ`) parameters from a normal distribution
on each simulation run to capture uncertainy in these parameters. 

# Keywords 

- `αμ::T`: mean of growth rate distribution 
- `ασ::T`: mean of volitility of growth rate distribution 
- `ημ::T`: standard deviation of growth rate distribution 
- `ησ::T`: standard deviation of volitility of growth rate distribution 
- `αμ::T`: mean of growth rate distribution during a recession
- `ασ::T`: mean of volitility of growth rate distribution during a recession
- `ημ::T`: standard deviation of growth rate distribution during a recession
- `ησ::T`: standard deviation of volitility of growth rate distribution during a recession 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
function VarGBM(; αμ, ασ, ημ, ησ, αμᵣ = αμ, ασᵣ = ασ, ημᵣ = 0, ησᵣ = 0, x0 = 1.0, x = x0)
    αμ, ασ, ημ, ησ, αμᵣ, ασᵣ, ημᵣ, ησᵣ, x0, x =
        promote(αμ, ασ, ημ, ησ, αμᵣ, ασᵣ, ημᵣ, ησᵣ, x0, x)
    return VarGBM(zeros(typeof(αμ), 4)..., αμ, ασ, ημ, ησ, αμᵣ, ασᵣ, ημᵣ, ησᵣ, x0, x)
end

function reset!(dist::VarGBM)
    dist.x0 = 1.0
    dist.x = 1.0
    dist.μ = rand(Normal(dist.αμ, dist.ημ))
    dist.σ = rand(truncated(Normal(dist.ασ, dist.ησ), 0.0, Inf))
    dist.μᵣ = rand(Normal(dist.αμᵣ, dist.ημᵣ))
    dist.σᵣ = rand(truncated(Normal(dist.ασᵣ, dist.ησᵣ), 0.0, Inf))
    return nothing
end

"""
    MvGBM{T <: Real} <: AbstractGBM

A distribution object for Multivariate Geometric Brownian Motion (MvGBM), which is used to model 
growth of multiple stocks and bonds. 

# Fields 

- `μ::Vector{T}`: growth rates
- `σ::Vector{T}`: volitility in growth rates 
- `x0::Vector{T}`: initial value of stocks
- `x::Vector{T}`: value of stocks 
- `ratios::Vector{T}`: allocation proportion of stocks/bonds
- `ρ::Array{T, 2}`: correlation matrix between stocks/bonds 
- `Σ::Array{T, 2}`: covariance matrix between stocks/bonds 

# Constructor 

    MvGBM(; μ, σ, ρ, ratios)
"""
mutable struct MvGBM{T <: Real} <: AbstractGBM
    μ::Vector{T}
    σ::Vector{T}
    x0::Vector{T}
    x::Vector{T}
    ratios::Vector{T}
    ρ::Array{T, 2}
    Σ::Array{T, 2}
end

"""
    MvGBM(; μ, σ, ρ, ratios)

A constructor for Multivariate Geometric Brownian Motion (MvGBM), which is used to model 
growth of multiple stocks and bonds. 

# Keywords 

- `μ::Vector{T}`: growth rates
- `σ::Vector{T}`: volitility in growth rates 
- `ratios::Vector{T}`: allocation proportion of stocks/bonds
- `ρ::Array{T, 2}`: correlation matrix between stocks/bonds 

# Example Usage 

The example below shows how to simulate general stock investments and bond investments. 
The first element corresponds to stocks and second element corresponds to bonds.
```julia
dist = MvGBM(;
    μ = [.10,.03],
    σ = [.05,.01],
    ρ = [1.0 .50; .50 1.0],
    ratios = [.8,.2]
)

values = rand(dist, 120, 10; Δt = 1/12) 
```
"""
function MvGBM(; μ, σ, ρ, ratios)
    x0 = copy(ratios)
    x = copy(x0)
    μ, σ, x0, x, ratios = promote(μ, σ, x0, x, ratios)
    Σ = cor2cov(ρ, σ)
    return MvGBM(μ, σ, x0, x, ratios, ρ, Σ)
end

function rand(dist::MvGBM, n_steps; Δt)
    reset!(dist)
    n = length(dist.x)
    prices = fill(0.0, n_steps + 1, n)
    prices[1, :] = dist.x
    for i ∈ 2:(n_steps + 1)
        increment!(dist; Δt)
        prices[i, :] = dist.x
    end
    return prices
end

"""
    increment!(dist::MvGBM, Δt)

Increment the stock price over the period `Δt`.

# Arguments 

- `dist::GBM`: a distribution object for Geometric Brownian Motion 
- `x`: current stock value 

# Keywords

- `Δt`: the time step for Geometric Brownian Motion
"""
function increment!(dist::MvGBM; Δt, kwargs...)
    (; μ, σ, Σ, x) = dist
    μn = fill(0.0, length(μ))
    dist.x .+= x .* (μ .* Δt .+ rand(MvNormal(μn, Σ)) * √(Δt))
    return nothing
end

function reset!(dist::MvGBM)
    dist.x0 = copy(dist.ratios)
    dist.x = copy(dist.ratios)
    return nothing
end

"""
    rebalance!(dist::MvGBM)

Rebalance portfolio. 

# Arguments

- `dist::MvGBM`: a distribution object for Geometric Brownian Motion 
"""
function rebalance!(dist::MvGBM)
    total = sum(dist.x)
    dist.x = total * dist.ratios
    return nothing
end

"""
    MGBM{T <: Real} <: AbstractGBM

A distribution object for modified Geometric Brownian Motion (MGBM), which is used to model 
growth of stocks. 

# Fields 

- `μₙ::T`: growth rate during non-recession
- `σₙ::T`: volitility in growth rate during non-recession
- `μᵣ::T`: growth rate during recession 
- `σᵣ::T`: volitility in growth rate during recession 
- `t_mat::Array{T,2}`: transition matrix for moving between recession and non-recession states
- `state::Int`: 1 if non-recession state, 2 if recession state 
- `x0::T`: initial value of stock 
- `x::T`: current value
"""
mutable struct MGBM{T <: Real} <: AbstractGBM
    μₙ::T
    σₙ::T
    μᵣ::T
    σᵣ::T
    t_mat::Array{T, 2}
    state::Int
    x0::T
    x::T
end

"""
    MGBM(;
        μₙ,
        σₙ,
        μᵣ,
        σᵣ,
        pₙᵣ,
        pᵣₙ,
        state = sample(1:2, Weights([1 - pₙᵣ, pₙᵣ])),
        x0 = 1.0,
        x = x0,
        t = 0
    )

A constructor for the Geometric Brownian Motion (GBM) model, which is used to model 
growth of stocks. 

# Keywords 

- `μₙ::T`: growth rate during non-recession
- `σₙ::T`: volitility in growth rate during non-recession
- `μᵣ::T`: growth rate during recession 
- `σᵣ::T`: volitility in growth rate during recession 
- `t_mat::Array{T,2}`: transition matrix for moving between recession and non-recession states
- `state::Int`: 1 if non-recession state, 2 if recession state 
- `x0::T`: initial value of stock 
- `x::T`: current value

# Example 

```julia 
using RetirementPlanners

Δt = 1 / 12
n_years = 10
n_steps = Int(n_years / Δt)
n_reps = 10
times = range(0, n_years, length = n_steps + 1)
dist = MGBM(; μₙ =.15, μᵣ = -.05,  σₙ = .05, σᵣ = .05, pₙᵣ = .05, pᵣₙ = .15, x0 = 1)
prices = rand(dist, n_steps, n_reps; Δt)
plot(times, prices, leg = false)
```
"""
function MGBM(;
    μₙ,
    σₙ,
    μᵣ,
    σᵣ,
    pₙᵣ,
    pᵣₙ,
    state = sample(1:2, Weights([1 - pₙᵣ, pₙᵣ])),
    x0 = 1.0,
    x = x0,
    t = 0
)
    μₙ, σₙ, μᵣ, σᵣ, pₙᵣ, pᵣₙ, x0, x = promote(μₙ, σₙ, μᵣ, σᵣ, pₙᵣ, pᵣₙ, x0, x)
    t_mat = [(1-pₙᵣ) pₙᵣ; pᵣₙ (1-pᵣₙ)]

    return MGBM(μₙ, σₙ, μᵣ, σᵣ, t_mat, state, x0, x)
end

function increment!(dist::MGBM; Δt)
    (; μₙ, σₙ, μᵣ, σᵣ, t_mat, state, x) = dist
    w = @view t_mat[state, :]
    next_state = sample(1:2, Weights(w))
    μ = next_state == 1 ? μₙ : μᵣ
    σ = next_state == 1 ? σₙ : σᵣ
    dist.state = next_state
    dist.x += x * (μ * Δt + σ * randn() * √(Δt))
    return nothing
end

mean(dist::MvGBM, t) = dist.ratios .* exp.(dist.μ * t)
var(dist::MvGBM, t) =
    dist.ratios .^ 2 .* exp.(2 .* dist.μ .* t) .* (exp.(dist.σ .^ 2 .* t) .- 1)
std(dist::MvGBM, t) = sqrt.(var(dist, t))
