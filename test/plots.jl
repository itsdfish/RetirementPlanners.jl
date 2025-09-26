@safetestset "plot_gradient" begin
    using Distributions
    using Plots
    using RetirementPlanners
    using Test

    # montly contribution
    contribution = (50_000 / 12) * 0.15
    # configuration options
    config = (
        # time step in years
        Δt = 1 / 12,
        # start age of simulation
        start_age = 27,
        # duration of simulation in years
        duration = 58,
        # initial investment amount
        start_amount = 10_000,
        # withdraw parameters
        kw_withdraw = (withdraws = Transaction(;
            start_age = 60,
            amount = AdaptiveWithdraw(;
                min_withdraw = 2200,
                percent_of_real_growth = 0.15,
                income_adjustment = 0.0,
                volitility = 0.05
            )
        ),),
        # invest parameters
        kw_invest = (investments = Transaction(;
            start_age = 27,
            end_age = 60,
            amount = Normal(contribution, 100)
        ),),
        # interest parameters
        kw_market = (
            # dynamic model of the stock market
            gbm = VarGBM(;
                # non-recession parameters
                αμ = 0.070,
                ημ = 0.010,
                ασ = 0.035,
                ησ = 0.010,
                # recession parameters
                αμᵣ = -0.05,
                ημᵣ = 0.010,
                ασᵣ = 0.035,
                ησᵣ = 0.010
            ),
            recessions = Transaction(; start_age = 0, end_age = 0)
        ),
        # inflation parameters
        kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
        # income parameters
        kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
    )
    # setup retirement model
    model = Model(; config...)
    times = get_times(model)
    n_reps = 1000
    n_steps = length(times)
    logger = Logger(; n_steps, n_reps)
    simulate!(model, logger, n_reps)

    # plot of survival probability as a function of time
    survival_probs = mean(logger.net_worth .> 0, dims = 2)

    income_plot = plot_gradient(
        times,
        logger.total_income;
        xlabel = "Age",
        ylabel = "Total Income",
        xlims = (config.kw_withdraw.withdraws.start_age, times[end]),
        n_lines = 0,
        color = :blue
    )

    @test true
end

@safetestset "plot_sensitivity1" begin
    using DataFrames
    using Distributions
    using Random
    using RetirementPlanners
    using StatsPlots

    Random.seed!(6522)
    # montly contribution
    contribute(x, r) = (x / 12) * r
    salary = 50_000

    withdraws = map(
        a -> Transaction(;
            start_age = a,
            amount = AdaptiveWithdraw(;
                min_withdraw = 2200,
                percent_of_real_growth = 0.15,
                income_adjustment = 0.0,
                volitility = 0.05
            )
        ),
        55:65
    )

    investments = [
        Transaction(;
            start_age = 27,
            end_age = a,
            amount = Normal(contribute(5e4, p), 100)
        )
        for p ∈ 0.10:0.05:0.30 for a ∈ 55:65
    ]

    # configuration options
    config = (
        log_times = 70:5:85,
        # time step in years
        Δt = 1 / 12,
        # start age of simulation
        start_age = 27,
        # duration of simulation in years
        duration = 58,
        # initial investment amount
        start_amount = 10_000,
        # withdraw parameters
        kw_withdraw = (; withdraws),
        # invest parameters
        kw_invest = (; investments),
        # interest parameters
        kw_market = (gbm = VarGBM(; αμ = 0.070, ημ = 0.010, ασ = 0.035, ησ = 0.010),),
        # inflation parameters
        kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
        # income parameters
        kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
    )

    yoked_values =
        [Pair((:kw_withdraw, :withdraws, :start_age), (:kw_invest, :investments, :end_age))]
    results = grid_search(Model, Logger, 1000, config; yoked_values);
    df = to_dataframe(Model(; config...), results)
    df.survived = df.net_worth .> 0
    df.retirement_age = map(x -> x.end_age, df.invest_investments)
    df.mean_investment = map(x -> x.amount.μ, df.invest_investments)

    plot_sensitivity(
        df,
        [:retirement_age, :mean_investment],
        :survived,
        xlabel = "Age",
        ylabel = "Invest Amount",
        colorbar_title = "Surival Probability"
    )

    @test true
end

@safetestset "plot_sensitivity2" begin
    using Distributions
    using DataFrames
    using Plots
    using RetirementPlanners
    using StatsPlots
    using Test

    # montly contribution 
    contribute(x, r) = (x / 12) * r
    salary = 50_000

    withdraws = map(
        a -> Transaction(;
            start_age = a,
            amount = AdaptiveWithdraw(;
                min_withdraw = 2200,
                percent_of_real_growth = 0.15,
                income_adjustment = 0.0,
                volitility = 0.05
            )
        ),
        55:65
    )

    investments = [
        Transaction(;
            start_age = 27,
            end_age = a,
            amount = Normal(contribute(5e4, p), 100)
        )
        for p ∈ 0.10:0.05:0.30 for a ∈ 55:65
    ]

    # configuration options
    config = (
        # time step in years 
        Δt = 1 / 12,
        # start age of simulation 
        start_age = 27,
        # duration of simulation in years
        duration = 58,
        # initial investment amount 
        start_amount = 10_000,
        # withdraw parameters 
        kw_withdraw = (; withdraws),
        # invest parameters
        kw_invest = (; investments),
        # interest parameters
        kw_market = (
            gbm = VarGBM(;
            αμ = 0.070,
            ημ = 0.010,
            ασ = 0.035,
            ησ = 0.010,
            αμᵣ = -0.05,
            ημᵣ = 0.010,
            ασᵣ = 0.035,
            ησᵣ = 0.010
        ),
        ),
        # inflation parameters
        kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
        # income parameters 
        kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
    )

    yoked_values =
        [Pair((:kw_withdraw, :withdraws, :start_age), (:kw_invest, :investments, :end_age))]
    results = grid_search(Model, Logger, 1000, config; yoked_values);
    df = to_dataframe(Model(; config...), results)
    df.survived = df.net_worth .> 0
    df.retirement_age = map(x -> x.end_age, df.invest_investments)
    df.mean_investment = map(x -> x.amount.μ, df.invest_investments)
    df1 =
        combine(groupby(df, [:retirement_age, :mean_investment, :time]), :net_worth => mean)
    df2 =
        combine(groupby(df, [:retirement_age, :mean_investment, :time]), :survived => mean)

    plot_sensitivity(
        df,
        [:retirement_age, :mean_investment],
        :survived,
        xlabel = "Age",
        ylabel = "Invest Amount",
        colorbar_title = "Surival Probability"
    )

    @test true
end
