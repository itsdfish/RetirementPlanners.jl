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

        fixed_income(
            model,
            1.0; 
            social_security_income = 1000, 
            social_security_start_age = 65,
        )
        @test model.state.income_amount == 0

        fixed_income(
            model,
            65; 
            social_security_income = 1000, 
            social_security_start_age = 65,
        )
        @test model.state.income_amount == 1000

        fixed_income(
            model,
            65; 
            social_security_income = 1000, 
            social_security_start_age = 65,
            pension_income = 1000, 
            pension_start_age = 67,
        )
        @test model.state.income_amount == 1000

        fixed_income(
            model,
            67; 
            social_security_income = 1000, 
            social_security_start_age = 65,
            pension_income = 1000, 
            pension_start_age = 67,
        )
        @test model.state.income_amount == 2000
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
        @safetestset "1" begin 
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
        @safetestset "2" begin 
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
            fixed_income(model, 1.0; social_security_income = 1000, social_security_start_age = 65)
            fixed_withdraw(model, 1.0; withdraw_amount, start_age)
            @test model.state.withdraw_amount == 0
            
            reset!(model)
            fixed_income(model, start_age; social_security_income = 1000, social_security_start_age = 65)
            fixed_withdraw(model, start_age; withdraw_amount, start_age, income_adjustment=.5)
            @test model.state.withdraw_amount == withdraw_amount * .50
    
            model.start_amount = 400
            reset!(model)
            fixed_income(model, start_age; social_security_income = 1000, social_security_start_age = 65)
            fixed_withdraw(model, start_age; withdraw_amount, start_age, income_adjustment=.5)
            @test model.state.withdraw_amount == 400
        end
    end

    @safetestset "update_net_worth!" begin 
        using RetirementPlanners
        using Test

        model = Model(;
            Δt = 1 / 12,
            start_age = 25,
            duration = 35,
            start_amount = 10_000,
        )

        model.state.net_worth = model.start_amount
        model.state.interest_rate = .10
        model.state.inflation_rate = .03
        default_net_worth(model, 1.0)

        true_value = 10_000 * (1.1 / 1.03)^(1 / 12)

        @test true_value ≈ model.state.net_worth
    end
end