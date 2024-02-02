
@safetestset "Geometric Brownian Motion" begin
    @safetestset "rand" begin
        using Distributions
        using Random
        using RetirementPlanners
        using Test
        
        Random.seed!(588)
        
        Δt = 1 / 100 
        n_years = 10 
        n_steps = Int(n_years / Δt)
        n_reps = 15_000 
        times = range(0, n_years, length=n_steps+1)

        μ = .10 
        σ = .10
        dist = GBM(;μ, σ, x0=1)

        prices = rand(dist, n_steps, n_reps; Δt)

        @test mean(prices) ≈ mean.(dist, times) rtol = .01
        @test var(prices) ≈ var.(dist, times) rtol = .01
        @test std(prices) ≈ std.(dist, times) rtol = .01
    end

    @safetestset "fit" begin
        using Random
        using RetirementPlanners
        using Test
        
        Random.seed!(874)
        
        Δt = 1 / 365 
        n_years = 50 
        n_steps = Int(n_years / Δt)
        times = range(0, n_years, length=n_steps+1)

        μ = .10 
        σ = .05
        dist = GBM(;μ, σ, x0=1)

        prices = rand(dist, n_steps; Δt)

        μ′,σ′ = fit(GBM, prices; Δt)

        @test μ ≈ μ′ rtol = .05
        @test σ ≈ σ′ rtol = .05
    end

    @safetestset "estimate_μ" begin
        using RetirementPlanners
        using RetirementPlanners: estimate_μ
        using Test

        series = [1,1.2,1.4,1.5]
        Δt = 1 / 12
        @test estimate_μ(GBM, series; Δt) == 5.44
    end

    @safetestset "estimate_σ" begin
        using RetirementPlanners
        using RetirementPlanners: estimate_σ
        using Test

        series = [1,1.2,1.4,1.5]
        Δt = 1 / 12
        @test estimate_σ(GBM, series; Δt) ≈ 0.5196152422706631
    end

    @safetestset "convert_μ" begin
        using RetirementPlanners: convert_μ
        using Test

        @test convert_μ(1.5, 2) == 3.5
    end
end

@safetestset "Multivariate Geometric Brownian Motion" begin 
    @safetestset "rand" begin
        using Distributions
        using Random
        using RetirementPlanners
        using Test
        
        Random.seed!(684)
        
        Δt = 1 / 100 
        n_years = 5 
        n_steps = Int(n_years / Δt)
        n_reps = 15_000 
        times = range(0, n_years, length=n_steps+1)

        μ = [.10,.05]
        ratios = [.25,.75]

        dist = MvGBM(;
            μ ,
            σ = fill(.05, 2),
            ρ = [1. .4; .4 1],
            ratios
        )

        prices = rand(dist, n_steps, n_reps; Δt)

        for i ∈ 1:(n_steps+1)
            @test mean(map(p -> p[i,:], prices)) ≈ mean.(dist, times[i]) atol = .01
            @test var(map(p -> p[i,:], prices)) ≈ var.(dist, times[i]) atol = .01
            @test std(map(p -> p[i,:], prices)) ≈ std.(dist, times[i]) atol = .01
        end
    end

    @safetestset "increment!" begin 
        using Test 
        using RetirementPlanners

        μ = [.10,.05]
        ratios = [.25,.75]

        dist = MvGBM(;
            μ ,
            σ = fill(eps(), 2),
            ρ = [1. 0; 0. 1],
            ratios
        )

        increment!(dist; Δt = 1)
        dist.x

        true_val = sum(@. ratios * (1 + μ))
        @test sum(dist.x) ≈ true_val
    end
end 