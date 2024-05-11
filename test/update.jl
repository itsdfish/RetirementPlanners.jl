@safetestset "update functions" begin
    @safetestset "update_income!" begin
        using Distributions
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        update_income!(
            model,
            1.0;
            income_sources = Transaction(; start_age = 2, end_age = 3, amount = 100)
        )
        @test model.state.income_amount == 0

        update_income!(
            model,
            2.0;
            income_sources = Transaction(; start_age = 2, end_age = 3, amount = 100)
        )
        @test model.state.income_amount == 100

        update_income!(
            model,
            3.0;
            income_sources = Transaction(; start_age = 2, end_age = 3, amount = 100)
        )
        @test model.state.income_amount == 100

        update_income!(
            model,
            3.08;
            income_sources = Transaction(; start_age = 2, end_age = 3, amount = 100)
        )
        @test model.state.income_amount == 0

        update_income!(
            model,
            2.08;
            income_sources = Transaction(;
                start_age = 2,
                end_age = 3,
                amount = Normal(100, 0)
            )
        )
        @test model.state.income_amount == 100
    end

    @safetestset "fixed_inflation" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        inflation_rate = 0.05

        fixed_inflation(model, 1.0; inflation_rate)
        @test model.state.inflation_rate == inflation_rate
    end

    @safetestset "fixed_market" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        interest_rate = 0.05

        fixed_market(model, 1.0; interest_rate)
        @test model.state.interest_rate == interest_rate
    end

    @safetestset "withdraw!" begin
        @safetestset "1" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                1.0;
                withdraws = Transaction(;
                    start_age = 67,
                    amount = AdaptiveWithdraw(;
                        min_withdraw = 1000,
                        percent_of_real_growth = 1,
                        income_adjustment = 0.0,
                        volitility = 0.5)
                )
            )
            @test model.state.withdraw_amount == 0
        end

        @safetestset "2" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                68.0;
                withdraws = Transaction(;
                    start_age = 67,
                    amount = AdaptiveWithdraw(;
                        min_withdraw = 1000,
                        percent_of_real_growth = 1,
                        income_adjustment = 0.0,
                        volitility = eps())
                )
            )
            @test model.state.withdraw_amount ≈ 5494.0 atol = 0.5
        end

        @safetestset "3" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                68.0;
                withdraws = Transaction(;
                    start_age = 67,
                    amount = AdaptiveWithdraw(;
                        min_withdraw = 1000,
                        percent_of_real_growth = 0.50,
                        income_adjustment = 0.0,
                        volitility = eps())
                )
            )
            @test model.state.withdraw_amount ≈ 5494.0 / 2 atol = 0.5
        end

        @safetestset "4" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 100_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                68.0;
                withdraws = Transaction(;
                    start_age = 67,
                    amount = AdaptiveWithdraw(;
                        min_withdraw = 1000,
                        percent_of_real_growth = 1.0,
                        income_adjustment = 0.0,
                        volitility = eps())
                )
            )
            @test model.state.withdraw_amount ≈ 1000
        end

        @safetestset "4" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 500
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                68.0;
                withdraws = Transaction(;
                    start_age = 67,
                    amount = AdaptiveWithdraw(;
                        min_withdraw = 1000,
                        percent_of_real_growth = 1.0,
                        income_adjustment = 0.0,
                        volitility = 0.0)
                )
            )
            @test model.state.withdraw_amount == 500
        end

        @safetestset "5" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                25.0;
                withdraws = (
                    Transaction(;
                        start_age = 67,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 1000,
                            percent_of_real_growth = 1.0,
                            income_adjustment = 0.0,
                            volitility = 0.0)),
                    Transaction(;
                        start_age = 25 - 1 / 12,
                        end_age = start_age = 25 - 1 / 12,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 200,
                            percent_of_real_growth = 0.0,
                            income_adjustment = 0.0,
                            volitility = 0.0)),
                    Transaction(;
                        start_age = 25 + 1 / 12,
                        end_age = start_age = 25 + 1 / 12,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 100,
                            percent_of_real_growth = 0.0,
                            income_adjustment = 0.0,
                            volitility = 0.0))
                )
            )
            @test model.state.withdraw_amount == 0
        end

        @safetestset "6" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                25.0 + 1 / 12;
                withdraws = [
                    Transaction(;
                        start_age = 67,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 1000,
                            percent_of_real_growth = 1.0,
                            income_adjustment = 0.0,
                            volitility = 0.0)),
                    Transaction(;
                        start_age = 25 - 1 / 12,
                        end_age = start_age = 25 - 1 / 12,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 200,
                            percent_of_real_growth = 0.0,
                            income_adjustment = 0.0,
                            volitility = 0.0)),
                    Transaction(;
                        start_age = 25 + 1 / 12,
                        end_age = start_age = 25 + 1 / 12,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 100,
                            percent_of_real_growth = 0.0,
                            income_adjustment = 0.0,
                            volitility = 0.0))
                ]
            )
            @test model.state.withdraw_amount == 100
        end

        @safetestset "7" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            start_age = 67
            min_withdraw = 1000
            percent_of_real_growth = 1
            income_adjustment = 0.0
            volitility = 0.5
            lump_sum_withdraws = Dict(25 + 1 / 12 => 100.0, 25 - 1 / 12 => 200.0)

            reset!(model)
            model.state.net_worth = 50
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            withdraw!(
                model,
                25.0 + 1 / 12;
                withdraws = [
                    Transaction(;
                        start_age = 67,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 1000,
                            percent_of_real_growth = 1.0,
                            income_adjustment = 0.0,
                            volitility = 0.0)),
                    Transaction(;
                        start_age = 25 - 1 / 12,
                        end_age = start_age = 25 - 1 / 12,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 200,
                            percent_of_real_growth = 0.0,
                            income_adjustment = 0.0,
                            volitility = 0.0)),
                    Transaction(;
                        start_age = 25 + 1 / 12,
                        end_age = start_age = 25 + 1 / 12,
                        amount = AdaptiveWithdraw(;
                            min_withdraw = 100,
                            percent_of_real_growth = 0.0,
                            income_adjustment = 0.0,
                            volitility = 0.0))
                ]
            )
            @test model.state.withdraw_amount == 50
        end
    end

    @safetestset "update_investments!" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        model.state.net_worth = model.start_amount
        model.state.interest_rate = 0.10
        model.state.inflation_rate = 0.03
        update_investments!(model, 1.0)

        true_value = 10_000 * (1.1 / 1.03)^(1 / 12)

        @test true_value ≈ model.state.net_worth
    end

    @safetestset "invest!" begin
        @safetestset "1" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            mean_investment = 1000
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                66;
                investments = Transaction(;
                    start_age = 25,
                    end_age = 67,
                    amount = Normal(mean_investment, 0)
                )
            )
            @test model.state.invest_amount ≈ mean_investment atol = 1e-10
        end

        @safetestset "2" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            mean_investment = 1000
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                68;
                investments = Transaction(;
                    start_age = 25,
                    end_age = 67,
                    amount = Normal(mean_investment, 0)
                )
            )

            @test model.state.invest_amount ≈ 0 atol = 1e-10
        end

        @safetestset "3" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            mean_investment = 1000
            lump_sum = 500
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                45;
                investments = [
                    Transaction(;
                        start_age = 25,
                        end_age = 67,
                        amount = Normal(mean_investment, 0)),
                    Transaction(;
                        start_age = 45,
                        end_age = 45,
                        amount = Normal(lump_sum, 0))
                ]
            )

            @test model.state.invest_amount ≈ lump_sum + mean_investment atol = 1e-10
        end

        @safetestset "5" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            mean_investment = 1000
            lump_sum = 500
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                46;
                investments = [
                    Transaction(;
                        start_age = 25,
                        end_age = 67,
                        amount = Normal(mean_investment, 0)),
                    Transaction(;
                        start_age = 45,
                        end_age = 45,
                        amount = Normal(lump_sum, 0))
                ]
            )
            @test model.state.invest_amount ≈ mean_investment atol = 1e-10
        end

        @safetestset "6" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            mean_investment = 1000
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                25;
                investments = Transaction(;
                    start_age = 25,
                    end_age = 67,
                    amount = AdaptiveInvestment(;
                        mean = 1000,
                        std = 0,
                        start_age = 25,
                        peak_age = 45,
                        real_growth_rate = 0.02
                    )
                )
            )
            @test model.state.invest_amount ≈ mean_investment * 1.02^0 atol = 1e-10
        end

        @safetestset "7" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                30;
                investments = Transaction(;
                    start_age = 25,
                    end_age = 67,
                    amount = AdaptiveInvestment(;
                        mean = 1000,
                        std = 0,
                        start_age = 25,
                        peak_age = 45,
                        real_growth_rate = 0.02
                    )
                )
            )

            @test model.state.invest_amount ≈ 1000 * 1.02^5 atol = 1e-10
        end

        @safetestset "8" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Distributions
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            invest!(
                model,
                50;
                investments = Transaction(;
                    start_age = 25,
                    end_age = 67,
                    amount = AdaptiveInvestment(;
                        mean = 1000,
                        std = 0,
                        start_age = 25,
                        peak_age = 45,
                        real_growth_rate = 0.02
                    )
                )
            )

            @test model.state.invest_amount ≈ 1000 * 1.02^20 atol = 1e-10
        end
    end
end
