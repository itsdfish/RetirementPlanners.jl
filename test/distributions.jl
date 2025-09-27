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
        times = range(0, n_years, length = n_steps + 1)

        μ = 0.10
        σ = 0.10
        dist = GBM(; μ, σ, x0 = 1)

        prices = rand(dist, n_steps, n_reps; Δt)

        @test mean(prices) ≈ mean.(dist, times) rtol = 0.01
        @test var(prices) ≈ var.(dist, times) rtol = 0.01
        @test std(prices) ≈ std.(dist, times) rtol = 0.01
    end

    @safetestset "increment" begin
        @safetestset "1" begin
            using Random
            using RetirementPlanners
            using Test

            Random.seed!(63)

            Δt = 1
            μ = 0.10
            σ = 0.01
            μᵣ = -0.10
            σᵣ = 0.01
            dist = GBM(; μ, σ, μᵣ, σᵣ, x0 = 1)
            recessions = Transaction(; start_age = 1, end_age = 2, amount = 0)

            increment!(dist; t = 1, Δt, recessions)
            @test dist.x ≈ 0.90 atol = 1e-2
        end

        @safetestset "2" begin
            using Random
            using RetirementPlanners
            using Test

            Random.seed!(18)

            Δt = 1
            μ = 0.10
            σ = 0.01
            μᵣ = -0.10
            σᵣ = 0.01
            dist = GBM(; μ, σ, μᵣ, σᵣ, x0 = 1)
            recessions = Transaction(; start_age = 1, end_age = 2, amount = 0)

            increment!(dist; t = 0, Δt, recessions)
            @test dist.x ≈ 1.10 atol = 1e-2
        end

        @safetestset "3" begin
            using Random
            using RetirementPlanners
            using Test

            Random.seed!(620)

            Δt = 1
            μ = 0.10
            σ = 0.001
            μᵣ = -0.10
            σᵣ = 0.001
            dist = GBM(; μ, σ, μᵣ, σᵣ, x0 = 1)
            recessions = Transaction(; start_age = 1, end_age = 2, amount = 0)

            increment!(dist; t = 2 + Δt / 2 + 2eps(), Δt, recessions)
            @test dist.x ≈ 1.1 atol = 1e-2
        end
    end

    @safetestset "fit" begin
        using Random
        using RetirementPlanners
        using Test

        Random.seed!(874)

        Δt = 1 / 365
        n_years = 50
        n_steps = Int(n_years / Δt)
        times = range(0, n_years, length = n_steps + 1)

        μ = 0.10
        σ = 0.05
        dist = GBM(; μ, σ, x0 = 1)

        prices = rand(dist, n_steps; Δt)

        μ′, σ′ = fit(GBM, prices; Δt)

        @test μ ≈ μ′ rtol = 0.05
        @test σ ≈ σ′ rtol = 0.05
    end

    @safetestset "estimate_μ" begin
        using RetirementPlanners
        using RetirementPlanners: estimate_μ
        using Test

        series = [1, 1.2, 1.4, 1.5]
        Δt = 1 / 12
        @test estimate_μ(GBM, series; Δt) == 5.44
    end

    @safetestset "estimate_σ" begin
        using RetirementPlanners
        using RetirementPlanners: estimate_σ
        using Test

        series = [1, 1.2, 1.4, 1.5]
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
        times = range(0, n_years, length = n_steps + 1)

        μ = [0.10, 0.05]
        ratios = [0.25, 0.75]

        dist = MvGBM(; μ, σ = fill(0.05, 2), ρ = [1.0 0.4; 0.4 1], ratios)

        prices = rand(dist, n_steps, n_reps; Δt)

        for i ∈ 1:(n_steps + 1)
            @test mean(map(p -> p[i, :], prices)) ≈ mean.(dist, times[i]) atol = 0.01
            @test var(map(p -> p[i, :], prices)) ≈ var.(dist, times[i]) atol = 0.01
            @test std(map(p -> p[i, :], prices)) ≈ std.(dist, times[i]) atol = 0.01
        end
    end

    @safetestset "increment!" begin
        using Test
        using RetirementPlanners

        μ = [0.10, 0.05]
        ratios = [0.25, 0.75]

        dist = MvGBM(; μ, σ = fill(eps(), 2), ρ = [1.0 0; 0.0 1], ratios)

        increment!(dist; Δt = 1)
        dist.x

        true_val = sum(@. ratios * (1 + μ))
        @test sum(dist.x) ≈ true_val
    end
end

@safetestset "Geometric Brownian Motion Poisson Spike and Regime Change" begin
    @safetestset "update_state 1!" begin
        using Test
        using Random
        using RetirementPlanners
        using RetirementPlanners: RCPSGBM
        using RetirementPlanners: update_state!
        Random.seed!(23)
        # p = 1 - exp(-λ * Δt)
        # -p + 1 = exp(-λ * Δt)
        # log(-p + 1) = -λ * Δt
        # - log(-p + 1) / Δt = λ

        Δt = 1
        p = 0.20
        λᵢₙ = - log(-p + 1) / Δt
        model = RCPSGBM(;
            μ = 0.11,
            σ = 0.15,
            μᵣ = -0.20,
            σᵣ = 0.10,
            μⱼ = -0.03,
            σⱼ = 0.02,
            λⱼ = 0.75,
            λᵢₙ,
            λₒᵤₜ = 0.66,
            x0 = 6614.0,
        )

        x = map(1:10000) do _
            model.in_recession = false
            update_state!(model; Δt)
            model.in_recession
        end

        @test mean(x) ≈ p atol = 0.005
    end

    @safetestset "update_state 2!" begin
        using Test
        using Random
        using RetirementPlanners
        using RetirementPlanners: RCPSGBM
        using RetirementPlanners: update_state!
        Random.seed!(56)
        # p = 1 - exp(-λ * Δt)
        # -p + 1 = exp(-λ * Δt)
        # log(-p + 1) = -λ * Δt
        # - log(-p + 1) / Δt = λ

        Δt = 1
        # probability of transitioning from recession to normal
        p = 0.05
        λₒᵤₜ = - log(-p + 1) / Δt
        model = RCPSGBM(;
            μ = 0.11,
            σ = 0.15,
            μᵣ = -0.20,
            σᵣ = 0.10,
            μⱼ = -0.03,
            σⱼ = 0.02,
            λⱼ = 0.75,
            λᵢₙ = 0.1,
            λₒᵤₜ,
            x0 = 6614.0,
        )

        x = map(1:10000) do _
            model.in_recession = true
            update_state!(model; Δt)
            model.in_recession
        end

        @test mean(.!x) ≈ p atol = 0.005
    end

    @safetestset "jump" begin
        using Test
        using Distributions
        using Random
        using RetirementPlanners
        using RetirementPlanners: RCPSGBM
        using RetirementPlanners: jump
        Random.seed!(7454)

        Δt = 1
        μⱼ = -0.03
        σⱼ = 0.02
        λⱼ = 0.75
        model = RCPSGBM(;
            μ = 0.11,
            σ = 0.15,
            μᵣ = -0.20,
            σᵣ = 0.10,
            μⱼ,
            σⱼ,
            λⱼ,
            λᵢₙ = 0.10,
            λₒᵤₜ = 0.66,
            x0 = 6614.0,
        )

        dist = Poisson(λⱼ)
        x = map(_ -> jump(model; Δt), 1:100_000)

        @test mean(x .== 0) ≈ pdf(dist, 0) atol = 0.01
        @test mean(dist) * μⱼ ≈ mean(x) atol = 0.01
        @test mean(dist) * σⱼ^2 ≈ var(x) atol = 0.01
    end
end
