cd(@__DIR__)
using Pkg
Pkg.activate("../../..")
using Random
using RetirementPlanners
using Plots
Random.seed!(25)

gdm = GBM(; μ = 0.07, σ = 0.12)
trajectories = rand(gdm, 365 * 10, 4; Δt = 1 / 365)
plot(
    trajectories,
    leg = false,
    grid = false,
    framestyle = :none,
    # colors = [
    #     RGB(.251, .388, .847)
    #     RGB(.584, .345, .698)
    #     RGB(.220, .596, .149)
    #     RGB(.796, .235, .200)
    # ]
    size = (600, 300),
    background_color = :transparent,
    dpi = 300
)

savefig("logo.svg")

plot(
    trajectories,
    leg = false,
    grid = false,
    framestyle = :none,
    # colors = [
    #     RGB(.251, .388, .847)
    #     RGB(.584, .345, .698)
    #     RGB(.220, .596, .149)
    #     RGB(.796, .235, .200)
    # ]
    size = (1200, 300),
    background_color = :transparent,
    dpi = 300
)

savefig("large_logo.svg")
