using SafeTestsets

@safetestset "simulate!" begin
    using RetirementPlanners
    using Test

    model = Model(;
        Δt = 1 / 12,
        start_age = 25,
        duration = 35,
        start_amount = 10_000,
        withdraw! = fixed_withdraw,
        invest! = fixed_investment,
        update_inflation! = fixed_inflation,
        update_interest! = fixed_interest,
    )

    times = get_times(model)
    n_steps = length(times)
    n_reps = 2
    logger = Logger(;n_reps, n_steps)

    simulate!(model, logger, n_reps)

    @test all(x -> x == .07, logger.interest)
    @test all(x -> x == .03, logger.inflation)
    @test logger.net_worth[end,1] ≈ 919432 rtol = .01
    @test logger.net_worth[end,1] ≈ 919432 rtol = .01
end

@safetestset "update functions" begin
    @safetestset "fixed_income" begin
        using RetirementPlanners
        using Test

        model = Model(;
            Δt = 1 / 12,
            start_age = 25,
            duration = 35,
            start_amount = 10_000,
        )

        income_amount = 1000
        start_age = 65

        fixed_income(model, 1.0; income_amount, start_age)
        @test model.state.income_amount == 0

        fixed_income(model, 65; income_amount, start_age)
        @test model.state.income_amount == income_amount
    end

    @safetestset "fixed_inflation" begin
        using RetirementPlanners
        using Test

        model = Model(;
            Δt = 1 / 12,
            start_age = 25,
            duration = 35,
            start_amount = 10_000,
        )

        inflation_rate = .05

        fixed_inflation(model, 1.0; inflation_rate)
        @test model.state.inflation_rate == inflation_rate
    end

    @safetestset "fixed_interest" begin
        using RetirementPlanners
        using Test

        model = Model(;
            Δt = 1 / 12,
            start_age = 25,
            duration = 35,
            start_amount = 10_000,
        )

        interest_rate = .05

        fixed_interest(model, 1.0; interest_rate)
        @test model.state.interest_rate == interest_rate
    end

    @safetestset "fixed_withdraw" begin
        using RetirementPlanners
        using RetirementPlanners: reset!
        using Test

        model = Model(;
            Δt = 1 / 12,
            start_age = 25,
            duration = 35,
            start_amount = 10_000,
        )

        withdraw_amount = 1000
        start_age = 65

        reset!(model)
        fixed_withdraw(model, 1.0; withdraw_amount, start_age)
        @test model.state.withdraw_amount == 0
        
        reset!(model)
        fixed_withdraw(model, start_age; withdraw_amount, start_age)
        @test model.state.withdraw_amount == withdraw_amount

        model.start_amount = 800
        reset!(model)
        fixed_withdraw(model, start_age; withdraw_amount, start_age)
        @test model.state.withdraw_amount == 800
    end
end

@safetestset "permute" begin
    using RetirementPlanners
    using RetirementPlanners: permute
    using DataFrames
    using Test

    np = (
        a = [6,5],
        b = [1,2],
        c = [77]
    )

    x = permute(np)
    
    ground_truth = [(;a,b,c) for a ∈ np.a for b ∈ np.b for c ∈ np.c]

    for g ∈ ground_truth
        @test g ∈ x 
    end

    @test length(x) == 4
end

@safetestset "make_nps" begin
    using RetirementPlanners
    using RetirementPlanners: make_nps
    using DataFrames
    using Test

    np = (
        np1 = (
            a = [6,5],
            b = [4,3],
        ),
        np2 = (
            c = [6,5],
            d = 10,
        ),
    )

    dependent_values = [Pair((:np1,:a), (:np2,:c))]
    test_vals = make_nps(np, dependent_values)
    
    ground_truth = [
        (np1 = (a = 6, b = 4), np2 = (d = 10, c = 6)),
        (np1 = (a = 6, b = 3), np2 = (d = 10, c = 6)),
        (np1 = (a = 5, b = 4), np2 = (d = 10, c = 5)),
        (np1 = (a = 5, b = 3), np2 = (d = 10, c = 5)),
    ]

    for g ∈ ground_truth
        @test g ∈ test_vals
    end

    @test length(test_vals) == 4
end

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

@safetestset "is_event_time" begin
    using RetirementPlanners
    using Test

    model = Model(;
        Δt = 1 / 12,
        start_age = 25.5,
        duration = 35,
        start_amount = 10_000,
    )

    rate = 1
    @test is_event_time(model, 26.5, rate)
    @test !is_event_time(model, 26.4, rate)
    @test is_event_time(model, 26.5 + eps(), rate)


    rate = 2
    @test is_event_time(model, 27.5, rate)
    @test !is_event_time(model, 27.4, rate)
end