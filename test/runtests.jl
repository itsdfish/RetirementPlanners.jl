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
    n_reps = 1
    logger = Logger(;n_reps, n_steps)

    simulate!(model, logger, n_reps)

    @test all(x -> x == .07, logger.interest)
    @test all(x -> x == .03, logger.inflation)
    @test logger.net_worth[end] ≈ 919432 rtol = .01
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
        using Test

        model = Model(;
            Δt = 1 / 12,
            start_age = 25,
            duration = 35,
            start_amount = 10_000,
        )

        withdraw_amount = 1000
        start_age = 65

        fixed_withdraw(model, 1.0; withdraw_amount, start_age)
        @test model.state.withdraw_amount == 0

        fixed_withdraw(model, 65; withdraw_amount, start_age)
        @test model.state.withdraw_amount == withdraw_amount
    end
end