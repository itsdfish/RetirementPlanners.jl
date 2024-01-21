using SafeTestsets

@safetestset "simulate!" begin
    using RetirementPlanners
    using Test

    model = Model(;
        Δt = 1 / 12,
        start_age = 25,
        duration = 35,
        start_amount = 10_000,
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
    using DataFrames
    using Test

    ext = Base.get_extension(RetirementPlanners, :DataFramesExt)

    np = (
        a = [6,5],
        b = [1,2],
        c = [77]
    )

    x = ext.permute(np)
    
    ground_truth = [(;a,b,c) for a ∈ np.a for b ∈ np.b for c ∈ np.c]

    for g ∈ ground_truth
        @test g ∈ x 
    end

    @test length(x) == 4
end

@safetestset "Geometric Brownian Motion" begin
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

    @test mean(prices) ≈ exp.(μ * times) rtol = .01
    @test var(prices) ≈ exp.(2 * μ * times) .* (exp.(σ^2 * times) .- 1) rtol = .01


end