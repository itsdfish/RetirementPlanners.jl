@safetestset "simulate!" begin
    using RetirementPlanners
    using Test

    model = Model(;
        Δt = 1 / 12,
        start_age = 25,
        duration = 35,
        start_amount = 10_000,
        withdraw!,
        invest!,
        update_inflation! = fixed_inflation,
        update_market! = fixed_market
    )

    times = get_times(model)
    n_steps = length(times)
    n_reps = 2
    logger = Logger(; n_reps, n_steps)

    simulate!(model, logger, n_reps)

    @test all(x -> x == 0.07, logger.interest)
    @test all(x -> x == 0.03, logger.inflation)
    true_net_worth = 10_000 * (1.07 / 1.03)^35
    @test logger.net_worth[end, 1] ≈ true_net_worth rtol = 0.01
    @test logger.net_worth[end, 2] ≈ true_net_worth rtol = 0.01
end

@safetestset "permute" begin
    using RetirementPlanners
    using RetirementPlanners: permute
    using DataFrames
    using Test

    np = (a = [6, 5], b = [1, 2], c = [77])

    x = permute(np)

    ground_truth = [(; a, b, c) for a ∈ np.a for b ∈ np.b for c ∈ np.c]

    for g ∈ ground_truth
        @test g ∈ x
    end

    @test length(x) == 4
end

@safetestset "make_nps" begin
    @safetestset "1" begin
        using RetirementPlanners
        using RetirementPlanners: make_nps
        using DataFrames
        using Test

        np = (np1 = (a = [6, 5], b = [4, 3]), np2 = (c = [6, 5], d = 10))

        dependent_values = [Pair((:np1, :a), (:np2, :c))]
        test_vals = make_nps(np, dependent_values)

        ground_truth = [
            (np1 = (a = 6, b = 4), np2 = (d = 10, c = 6)),
            (np1 = (a = 6, b = 3), np2 = (d = 10, c = 6)),
            (np1 = (a = 5, b = 4), np2 = (d = 10, c = 5)),
            (np1 = (a = 5, b = 3), np2 = (d = 10, c = 5))
        ]

        for g ∈ ground_truth
            @test g ∈ test_vals
        end

        @test length(test_vals) == 4
    end

    @safetestset "2" begin
        using RetirementPlanners
        using RetirementPlanners: make_nps
        using DataFrames
        using Test

        np = (np1 = (a = [6, 5], b = [4, 3], d = [6, 5]), np2 = (c = [6, 5], d = 10))

        dependent_values = [Pair((:np1, :a), (:np2, :c)), Pair((:np1, :a), (:np1, :d))]
        test_vals = make_nps(np, dependent_values)

        ground_truth = [
            (np1 = (a = 6, b = 4, d = 6), np2 = (d = 10, c = 6)),
            (np1 = (a = 6, b = 3, d = 6), np2 = (d = 10, c = 6)),
            (np1 = (a = 5, b = 4, d = 5), np2 = (d = 10, c = 5)),
            (np1 = (a = 5, b = 3, d = 5), np2 = (d = 10, c = 5))
        ]

        for g ∈ ground_truth
            @test g ∈ test_vals
        end

        @test length(test_vals) == 4
    end
end

@safetestset "is_event_time" begin
    using RetirementPlanners
    using Test

    model = Model(; Δt = 1 / 12, start_age = 25.5, duration = 35, start_amount = 10_000)

    rate = 1
    @test is_event_time(model, 26.5, rate)
    @test !is_event_time(model, 26.4, rate)
    @test is_event_time(model, 26.5 + eps(), rate)

    rate = 2
    @test is_event_time(model, 27.5, rate)
    @test !is_event_time(model, 27.4, rate)
end

@safetestset "can_transact" begin
    @safetestset "1" begin
        using RetirementPlanners
        using RetirementPlanners: can_transact
        using Test

        transaction = Transaction(; start_age = 1, end_age = 2, amount = 10)

        @test can_transact(transaction, 1)
        @test !can_transact(transaction, 0.99)
        @test !can_transact(transaction, 2.01)
        @test can_transact(transaction, 1.1)
    end

    @safetestset "2" begin
        using RetirementPlanners
        using RetirementPlanners: can_transact
        using Test

        transaction = Transaction(; start_age = 1, end_age = 1, amount = 10)
        Δt = 1 / 12

        @test can_transact(transaction, 1; Δt)
        @test !can_transact(transaction, 0.5; Δt)
        @test !can_transact(transaction, 1.5; Δt)
        @test can_transact(transaction, 1.0 + Δt / 2; Δt)
        @test can_transact(transaction, 1.0 - Δt / 2; Δt)
        @test !can_transact(transaction, 1.0 + Δt / 2 + eps(); Δt)
        @test !can_transact(transaction, 1.0 - Δt / 2 - eps(); Δt)
    end
end
