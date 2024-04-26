@safetestset "update functions" begin
    @safetestset "fixed_income" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        fixed_income(
            model,
            1.0;
            social_security_income = 1000,
            social_security_start_age = 65
        )
        @test model.state.income_amount == 0

        fixed_income(
            model,
            65;
            social_security_income = 1000,
            social_security_start_age = 65
        )
        @test model.state.income_amount == 1000

        fixed_income(
            model,
            65;
            social_security_income = 1000,
            social_security_start_age = 65,
            pension_income = 1000,
            pension_start_age = 67
        )
        @test model.state.income_amount == 1000

        fixed_income(
            model,
            67;
            social_security_income = 1000,
            social_security_start_age = 65,
            pension_income = 1000,
            pension_start_age = 67
        )
        @test model.state.income_amount == 2000
    end

    @safetestset "fixed_inflation" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        inflation_rate = 0.05

        fixed_inflation(model, 1.0; inflation_rate)
        @test model.state.inflation_rate == inflation_rate
    end

    @safetestset "fixed_interest" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        interest_rate = 0.05

        fixed_interest(model, 1.0; interest_rate)
        @test model.state.interest_rate == interest_rate
    end

    @safetestset "fixed_withdraw" begin
        @safetestset "1" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

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

        @safetestset "2" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            withdraw_amount = 1000
            start_age = 65

            reset!(model)
            fixed_income(
                model,
                1.0;
                social_security_income = 1000,
                social_security_start_age = 65
            )
            fixed_withdraw(model, 1.0; withdraw_amount, start_age)
            @test model.state.withdraw_amount == 0

            reset!(model)
            fixed_income(
                model,
                start_age;
                social_security_income = 1000,
                social_security_start_age = 65
            )
            fixed_withdraw(
                model,
                start_age;
                withdraw_amount,
                start_age,
                income_adjustment = 0.5
            )
            @test model.state.withdraw_amount == withdraw_amount * 0.50

            model.start_amount = 400
            reset!(model)
            fixed_income(
                model,
                start_age;
                social_security_income = 1000,
                social_security_start_age = 65
            )
            fixed_withdraw(
                model,
                start_age;
                withdraw_amount,
                start_age,
                income_adjustment = 0.5
            )
            @test model.state.withdraw_amount == 400
        end
    end

    @safetestset "adaptive_withdraw" begin
        @safetestset "1" begin
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

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                1.0;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility
            )
            @test model.state.withdraw_amount == 0
        end

        @safetestset "2" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            start_age = 67
            min_withdraw = 1000
            percent_of_real_growth = 1
            income_adjustment = 0.0
            volitility = eps()

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                68;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility
            )
            @test model.state.withdraw_amount ≈ 5494.0 atol = 0.5
        end

        @safetestset "3" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            start_age = 67
            min_withdraw = 1000
            percent_of_real_growth = 0.5
            income_adjustment = 0.0
            volitility = eps()

            reset!(model)
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                68;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility
            )
            @test model.state.withdraw_amount ≈ 5494.0 / 2 atol = 0.5
        end

        @safetestset "4" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            start_age = 67
            min_withdraw = 1000
            percent_of_real_growth = 1
            income_adjustment = 0.0
            volitility = eps()

            reset!(model)
            model.state.net_worth = 100_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                68;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility
            )
            @test model.state.withdraw_amount ≈ min_withdraw
        end

        @safetestset "4" begin
            using RetirementPlanners
            using RetirementPlanners: reset!
            using Test

            model =
                Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

            start_age = 67
            min_withdraw = 1000
            percent_of_real_growth = 1
            income_adjustment = 0.0
            volitility = eps()

            reset!(model)
            model.state.net_worth = 500
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                68;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility
            )
            @test model.state.withdraw_amount == 500
        end

        @safetestset "5" begin
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
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                25;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility,
                lump_sum_withdraws
            )
            @test model.state.withdraw_amount == 0
        end

        @safetestset "6" begin
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
            model.state.net_worth = 1_000_000
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            adaptive_withdraw(
                model,
                25 + 1 / 12;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility,
                lump_sum_withdraws
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

            adaptive_withdraw(
                model,
                25 + 1 / 12;
                start_age,
                min_withdraw,
                percent_of_real_growth,
                income_adjustment,
                volitility,
                lump_sum_withdraws
            )
            @test model.state.withdraw_amount == 50
        end
    end

    @safetestset "update_net_worth!" begin
        using RetirementPlanners
        using Test

        model = Model(; Δt = 1 / 12, start_age = 25, duration = 35, start_amount = 10_000)

        model.state.net_worth = model.start_amount
        model.state.interest_rate = 0.10
        model.state.inflation_rate = 0.03
        default_net_worth(model, 1.0)

        true_value = 10_000 * (1.1 / 1.03)^(1 / 12)

        @test true_value ≈ model.state.net_worth
    end

    @safetestset "variable_invest" begin
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

            variable_invest(
                model,
                66;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                lump_sum_investments = Dict()
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

            variable_invest(
                model,
                68;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                lump_sum_investments = Dict()
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
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            variable_invest(
                model,
                68;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                lump_sum_investments = Dict(68 => mean_investment)
            )

            @test model.state.invest_amount ≈ mean_investment atol = 1e-10
        end

        @safetestset "4" begin
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

            variable_invest(
                model,
                45;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                lump_sum_investments = Dict(45 => lump_sum)
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

            variable_invest(
                model,
                46;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                lump_sum_investments = Dict(45 => lump_sum)
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

            variable_invest(
                model,
                25;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                peak_age = 45,
                real_growth = .02
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

            mean_investment = 1000
            reset!(model)
            model.state.net_worth = 0.0
            model.state.interest_rate = 0.10
            model.state.inflation_rate = 0.03

            variable_invest(
                model,
                30;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                peak_age = 45,
                real_growth = .02
            )

            @test model.state.invest_amount ≈ mean_investment * 1.02^5 atol = 1e-10
        end

        @safetestset "8" begin
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

            variable_invest(
                model,
                50;
                end_age = 67.0,
                distribution = Normal(mean_investment, 0),
                peak_age = 45,
                real_growth = .02
            )

            @test model.state.invest_amount ≈ mean_investment * 1.02^20 atol = 1e-10
        end
    end
end
