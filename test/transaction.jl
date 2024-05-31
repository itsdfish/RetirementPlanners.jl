@safetestset "transaction" begin
    @safetestset "1" begin
        using RetirementPlanners
        using RetirementPlanners: transact
        using Test

        model =
            Model(; Δt = 1 / 12, start_age = 1, duration = 35, start_amount = 10_000)

        model.state.net_worth = 0.0
        model.state.interest_rate = 0.10
        model.state.inflation_rate = 0.03

        transaction = Transaction(; amount = NominalAmount(100.0, true))

        amount = transact(model, transaction; t = 1)
        @test amount ≈ 100 / 1.03^(1 / 12) atol = 1e-10

        amount = transact(model, transaction; t = 2)
        @test amount ≈ 100 / 1.03^(2 / 12) atol = 1e-10

        # reset amount (recorded time starts at start_time + Δt)
        amount = transact(model, transaction; t = 1 + 1 / 12)
        @test amount ≈ 100 / 1.03^(1 / 12) atol = 1e-10
    end

    @safetestset "2" begin
        using RetirementPlanners
        using RetirementPlanners: transact
        using Test

        model =
            Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        model.state.net_worth = 0.0
        model.state.interest_rate = 0.10
        model.state.inflation_rate = 0.03

        transaction = Transaction(; amount = NominalAmount(100.0, false))

        amount = transact(model, transaction; t = 1)
        @test amount ≈ 100 atol = 1e-10
    end
end
