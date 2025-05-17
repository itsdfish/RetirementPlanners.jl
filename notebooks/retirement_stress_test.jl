### A Pluto.jl notebook ###
# v0.20.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 8486baa8-1572-11ef-3bf6-115dd34a73b1
begin
    using CommonMark
    using Distributions
    using DataFrames
    using HypertextLiteral
    using LaTeXStrings
    using Plots
    using Plots.PlotMeasures
    using PlutoExtras
    using PlutoUI
    using Random
    using RetirementPlanners
    using StatsPlots

    html"""
    <style>
    	@media screen {
    		main {
    			margin: 0 auto;
    			max-width: 2000px;
        		padding-left: max(283px, 10%);
        		padding-right: max(383px, 10%); 
                #383px to accomodate TableOfContents(aside=true)
    		}
    	}
    </style>
    """
end

# ╔═╡ cd96a4a8-faf8-4a4c-a6bd-2a84ca684597
md"""
# Configuration
"""

# ╔═╡ 3f24d444-8eff-4957-9260-af2d4f2c5583
md"
## Global Parameters

"

# ╔═╡ 8a873dad-7c41-4cba-b430-506e57ed0eb2
@bind global_parms PlutoExtras.@NTBond "Global Parameters" begin
    start_amount = ("Portfolio Value", NumberField(0:1e7, default = 10_000))
    start_age = ("Start Age", NumberField(0.0:120, default = 27))
    end_age = ("End age", NumberField(0.0:120, default = 85))
    n_reps = ("Repetitions", NumberField(50:10_000, default = 200))
    seed = ("Seed", NumberField(0:100000000, default = rand(1:1000000)))
end

# ╔═╡ 142a098f-aa0c-4b20-be35-59024367b16e
md"""
## Time Points
"""

# ╔═╡ 6ac4883c-974b-4cee-a0d0-d064ac4d1cc8
@bind time_points PlutoExtras.@NTBond "Time Points" begin
    min = (@htl("Min"), NumberField(1:1:100.0, default = 70.0))
    max = (@htl("Max"), NumberField(1:1:100.0, default = 85.0))
    step = (@htl("Step"), NumberField(1:1:100.0, default = 5.0))
end

# ╔═╡ 989a8734-b0c4-4d84-bd52-b44cd1287642
md"""

## Investment Schedule

"""

# ╔═╡ c4398cff-af01-4ad5-a8a4-9af6c5076ab3
@bind primary_investment PlutoExtras.@NTBond "Primary Contribution" begin
    mean = (@htl("Mean"), NumberField(0:5:10_000.0, default = 625.0))
    std = (@htl("Standard Deviation"), NumberField(0:10:10_000.0, default = 150.0))
end

# ╔═╡ 0a671048-d73a-498b-a530-56e01026ad73
@bind supplemental_investment1 PlutoExtras.@NTBond "Supplemental Contribution" begin
    mean = (@htl("Mean"), NumberField(0:50:10_000.0, default = 0.0))
    std = (@htl("Standard Deviation"), NumberField(0:10:10_000.0, default = 0.0))
    start_age = (@htl("Start Age"), NumberField(0:120.0, default = 0))
    end_age = (@htl("End Age"), NumberField(0:120.0, default = 0))
end

# ╔═╡ 6ab60779-eadd-4624-a8e5-206d153d0b43
@bind supplemental_investment2 PlutoExtras.@NTBond "Supplemental Contribution" begin
    mean = (@htl("Mean"), NumberField(0:50:10_000.0, default = 0.0))
    std = (@htl("Standard Deviation"), NumberField(0:10:10_000.0, default = 0.0))
    start_age = (@htl("Start Age"), NumberField(0:120.0, default = 0))
    end_age = (@htl("End Age"), NumberField(0:120.0, default = 0))
end

# ╔═╡ 2bf35243-4a89-45a1-b562-f4854c350455
md"""
## Retirement Age
"""

# ╔═╡ 4e6823e4-6542-4099-9834-f00b06953258
@bind retirement_age PlutoExtras.@NTBond "Retirement Age" begin
    min = (@htl("Min"), NumberField(20:1:90.0, default = 55.0))
    max = (@htl("Max"), NumberField(20:1:90.0, default = 65.0))
    step = (@htl("Step"), NumberField(1:01:10.0, default = 2.0))
end

# ╔═╡ 32dbc935-ee1c-453d-b5f9-81cb9264b62e
md"

## Income Sources

"

# ╔═╡ 7e7d025a-0f66-4259-b039-2935eb942638
@bind social_security PlutoExtras.@NTBond "Social Security" begin
    start =
        (@htl("<p align='left'>Start Age</p>"), NumberField(62:1:70.0, default = 67.00))
    amount =
        (@htl("<p align='left'>Amount</p>"), NumberField(0:100:4000.0, default = 2000.0))
    adjust = (@htl("Cost of Living Adjustment"), CheckBox(default = true))
end

# ╔═╡ 5452bfb7-1809-4cf5-a1c4-8fb19db0fdda
@bind pension PlutoExtras.@NTBond "Pension" begin
    start = (@htl("Start Age"), NumberField(0:1:90, default = 0.0))
    end_age = (@htl("End Age"), NumberField(0:1:90, default = 0.0))
    amount = (@htl("Amount"), NumberField(0:100:10_000.0, default = 0.0))
    adjust = (@htl("Cost of Living Adjustment"), CheckBox(default = false))
end

# ╔═╡ 52e1ef00-71de-4a97-886d-1276bce74d29
@bind supplemental PlutoExtras.@NTBond "Supplemental Income" begin
    start = (@htl("Start Age"), NumberField(0:1:90.0, default = 0.0))
    end_age = (@htl("End Age"), NumberField(0:1:90.0, default = 0.0))
    amount = (@htl("Amount"), NumberField(0:100:10_000.0, default = 0.0))
    adjust = (@htl("Cost of Living Adjustment"), CheckBox(default = true))
end

# ╔═╡ 2b9e3b46-18f1-4d00-8a40-cb99e8bd1691
md"
## Withdrawing from Investments
"

# ╔═╡ 50d919c6-4f86-4e4d-a08d-7f23486ff9ec
@bind withdraw_amount PlutoExtras.@NTBond "Minimum Withdraw Amount" begin
    min = (@htl("Min"), NumberField(0:0.01:10_000, default = 2000.0))
    max = (@htl("Max"), NumberField(0:0.01:10_000, default = 3000.0))
    step = (@htl("Step"), NumberField(1:0.01:10_000, default = 200.0))
end

# ╔═╡ 40faa877-5477-47f2-a92a-8ddf00528311
@bind withdraw_parms PlutoExtras.@NTBond "Withdraw Parameters" begin
    income_adjustment = (@htl("Income Adjustment"), NumberField(0:1e-3:1, default = 0.0))
    percent_of_real_growth =
        (@htl("Percent of Real Growth"), NumberField(0:1e-3:1, default = 0.15))
    volitility = (@htl(" Volility"), NumberField(0:1e-3:1, default = 0.05))
end

# ╔═╡ 31803b5b-3205-4d1f-b49e-98ebf7cb3eb9
md"
## Economic Dynamics


"
# The dynamics of the stock market and inflation are modeled with a stochastic differential equation called Geometric Brownian Motion (GBM). The GBM has two parameters which govern its behavior. 

# -  $\mu$: average growth rate of investments
# -  $\sigma$: volitity of the investments

# Move the slider to the right to show 5 example trajectories of the GBM over a 30 year period.

# ╔═╡ ca02fd88-b208-4492-ae31-85d5c8707af9
md"""
### Investment Growth 
"""

# ╔═╡ bda54ee1-c009-461c-b7d4-d105e340da56
@bind investment_growth PlutoExtras.@NTBond "Mean Growth Rate" begin
    min = (@htl("Min"), NumberField(-2:1e-5:2, default = 0.05))
    max = (@htl("Max"), NumberField(-2:1e-5:2, default = 0.100))
    step = (@htl("Step"), NumberField(0:1e-6:2, default = 0.025))
end

# ╔═╡ 7e4cbe2a-dd08-4298-b9a4-32f0f659efa8
@bind investment_parms PlutoExtras.@NTBond "Growth Parameters" begin
    std_rate = (@htl("Standard Deviation Rate"), NumberField(0:1e-5:2, default = 0.010))
    mean_volitility = (@htl("Mean Volitility"), NumberField(0:1e-5:2, default = 0.040))
    std_volitility =
        (@htl("Standard Deviation Volitility"), NumberField(0:1e-5:2, default = 0.010))
end

# ╔═╡ 989bd0e5-33d5-4974-a044-bd2af180b5e4
md"""
### Inflation
"""

# ╔═╡ cb5e4707-5cc8-4a0d-a1f8-ac20875d94e9
@bind inflation PlutoExtras.@NTBond "Inflation" begin
    mean_rate = (@htl("Mean Rate"), NumberField(-2:1e-5:2, default = 0.035))
    std_rate = (@htl("Standard Deviation Rate"), NumberField(0:1e-5:2, default = 0.005))
    mean_volitility = (@htl("Mean Volitility"), NumberField(0:1e-5:2, default = 0.005))
    std_volitility =
        (@htl("Standard Deviation Volitility"), NumberField(0:1e-5:2, default = 0.0025))
end

# ╔═╡ 42ac4169-ec26-4882-aa64-aeed3e609ce0
md"""
### Recession
"""

# ╔═╡ e437c0c7-f405-4e1f-94fc-79605774a824
@bind recession_parms PlutoExtras.@NTBond "Recession Parameters" begin
    mean_rate = (@htl("Mean Rate"), NumberField(-2:1e-5:0, default = -0.05))
    std_rate = (@htl("Standard Deviation Rate"), NumberField(0:1e-5:2, default = 0.010))
    mean_volitility = (@htl("Mean Volitility"), NumberField(0:1e-5:2, default = 0.040))
    std_volitility =
        (@htl("Standard Deviation Volitility"), NumberField(0:1e-5:2, default = 0.010))
    duration = (@htl("Duration"), NumberField(0:1e-3:30, default = 3))
end

# ╔═╡ 29008274-3a15-4283-98fb-7a9a10bd4a2a
md"""
## Run Simulation


"""

# ╔═╡ 05f0763a-e78f-4aa6-9f3f-31015490cacb
@bind run_simulation PlutoExtras.@NTBond "" begin
    run = (@htl("Check the Box to Run the Simulation"), CheckBox(default = false))
end

# ╔═╡ 75523d40-71e9-44d9-abd4-fc963fc42fc2
md"
## Plot Settings
"

# ╔═╡ 2075ba63-a576-4df5-a1d6-8be2f27c2d41
@bind plot_menu PlutoExtras.@NTBond "Plot Settings" begin
    plot1 = (
        @htl("Plot 1"),
        Select(
            [
                "survival probability",
                "mean income",
                "standard deviation income",
                "10th quantile income",
                "90th quantile income"
            ],
            default = "survival probability"
        )
    )
    plot2 = (
        @htl("Plot 2"),
        Select(
            [
                "survival probability",
                "mean income",
                "standard deviation income",
                "10th quantile income",
                "90th quantile income"
            ],
            default = "mean income"
        )
    )
end

# ╔═╡ bc85326b-60c3-4cd4-bc3a-70ce83800110
@bind switch_view PlutoExtras.@NTBond "" begin
    switch = (@htl("Switch View"), CheckBox(default = false))
end

# ╔═╡ 2c0b96a4-19fb-4d80-b68e-89af92722db7
md"
# Results
"

# ╔═╡ cf860556-a4c7-441d-94b2-13c4d9f608a4
md"
## Robustness Analysis
"

# ╔═╡ 63d97245-a135-4cb8-9221-524b436dc0c5
md"
## Single Scenario
"

# ╔═╡ fb097e5d-71dc-4530-a250-6a721ca10b8f
let
    retirement_age_range = (retirement_age.min):(retirement_age.step):(retirement_age.max)
    withdraw_rate_range = (withdraw_amount.min):(withdraw_amount.step):(withdraw_amount.max)
    mean_growth_rate_range =
        (investment_growth.min):(investment_growth.step):(investment_growth.max)
    @bind single_plot_menu PlutoExtras.@NTBond "Single Scenario Plot Settings" begin
        retirement_age = (@htl("Retirement Age"), NumberField(retirement_age_range))
        min_withdraw_rate = (@htl("Min Withdraw Rate"), NumberField(withdraw_rate_range))
        mean_growth_rate =
            (@htl("Mean Growth Rate"), NumberField(mean_growth_rate_range))
    end

    # @bind single_plot_menu PlutoExtras.@NTBond "Single Scenario Plot Settings" begin
    #     retirement_age = (@htl("Retirement Age"), NumberField(global_parms.start_age:100))
    #     min_withdraw_rate = (@htl("Min Withdraw Rate"), NumberField(500:500:5000))
    #     mean_growth_rate =
    #         (@htl("Mean Growth Rate"), NumberField(0:.01:.12))
    # end
end

# ╔═╡ 1d89b285-07b2-400b-804f-88f52b0b96dd
begin
    function simulate_nonrecession()
        retirement_age_range =
            (retirement_age.min):(retirement_age.step):(retirement_age.max)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        withdraws = [
            Transaction(;
                start_age = a,
                amount = AdaptiveWithdraw(;
                    min_withdraw = v,
                    percent_of_real_growth = withdraw_parms.percent_of_real_growth,
                    income_adjustment = withdraw_parms.income_adjustment,
                    volitility = withdraw_parms.volitility
                )
            )
            for a ∈ retirement_age_range for
            v ∈ (withdraw_amount.min):(withdraw_amount.step):(withdraw_amount.max)
        ]

        investments = [
            (
                Transaction(;
                    start_age = global_parms.start_age,
                    end_age = a,
                    amount = Normal(primary_investment.mean, primary_investment.std)
                ),
                Transaction(;
                    start_age = supplemental_investment1.start_age,
                    end_age = supplemental_investment1.end_age,
                    amount = Normal(
                        supplemental_investment1.mean,
                        supplemental_investment1.std
                    )
                ),
                Transaction(;
                    start_age = supplemental_investment2.start_age,
                    end_age = supplemental_investment2.end_age,
                    amount = Normal(
                        supplemental_investment2.mean,
                        supplemental_investment2.std
                    )
                )
            ) for a ∈ retirement_age_range
        ]

        gbm = map(
            αμ -> VarGBM(;
                αμ,
                ημ = investment_parms.std_rate,
                ασ = investment_parms.mean_volitility,
                ησ = investment_parms.std_volitility,
                αμᵣ = -0.05,
                ημᵣ = 0.010,
                ασᵣ = 0.040,
                ησᵣ = 0.010
            ),
            (investment_growth.min):(investment_growth.step):(investment_growth.max)
        )

        # configuration options
        config = (;
            log_times = age_range,
            # time step in years 
            Δt = 1 / 12,
            # start age of simulation 
            start_age = global_parms.start_age,
            # duration of simulation in years
            duration = global_parms.end_age - global_parms.start_age,
            # initial investment amount 
            start_amount = global_parms.start_amount,
            # withdraw parameters 
            kw_withdraw = (; withdraws),
            # invest parameters
            kw_invest = (; investments),
            # interest parameters
            kw_market = (; gbm,),
            # inflation parameters
            kw_inflation = (gbm = VarGBM(;
                αμ = inflation.mean_rate,
                ημ = inflation.std_rate,
                ασ = inflation.mean_volitility,
                ησ = inflation.std_volitility
            ),),
            # income parameters 
            kw_income = (income_sources = (
                Transaction(;
                    start_age = social_security.start,
                    amount = NominalAmount(;
                        amount = social_security.amount,
                        adjust = !social_security.adjust
                    )
                ),
                Transaction(;
                    start_age = pension.start,
                    end_age = pension.end_age,
                    amount = NominalAmount(;
                        amount = pension.amount,
                        adjust = !pension.adjust
                    )
                ),
                Transaction(;
                    start_age = supplemental.start,
                    end_age = supplemental.end_age,
                    amount = NominalAmount(;
                        amount = supplemental.amount,
                        adjust = !supplemental.adjust
                    )
                )
            ),)
        )

        yoked_values =
            [Pair(
                (:kw_withdraw, :withdraws, :start_age),
                (:kw_invest, :investments, 1, :end_age)
            )]
        results = grid_search(
            Model,
            Logger,
            global_parms.n_reps,
            config;
            threaded = true,
            yoked_values
        )
        df1 = to_dataframe(Model(; config...), results)
        df1.survived = df1.net_worth .> 0
        df1.retirement_age = map(x -> x[1].end_age, df1.invest_investments)
        df1.min_withdraw_amount = map(x -> x.amount.min_withdraw, df1.withdraw_withdraws)
        df1.mean_growth_rate = map(x -> x.αμ, df1.market_gbm)
        return df1
    end

    function simulate_recession()
        retirement_age_range =
            (retirement_age.min):(retirement_age.step):(retirement_age.max)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        withdraws = [
            Transaction(;
                start_age = a,
                amount = AdaptiveWithdraw(;
                    min_withdraw = v,
                    percent_of_real_growth = withdraw_parms.percent_of_real_growth,
                    income_adjustment = withdraw_parms.income_adjustment,
                    volitility = withdraw_parms.volitility
                )
            )
            for a ∈ retirement_age_range for
            v ∈ (withdraw_amount.min):(withdraw_amount.step):(withdraw_amount.max)
        ]

        investments = [
            (
                Transaction(;
                    start_age = global_parms.start_age,
                    end_age = a,
                    amount = Normal(primary_investment.mean, primary_investment.std)
                ),
                Transaction(;
                    start_age = supplemental_investment1.start_age,
                    end_age = supplemental_investment1.end_age,
                    amount = Normal(
                        supplemental_investment1.mean,
                        supplemental_investment1.std
                    )
                ),
                Transaction(;
                    start_age = supplemental_investment2.start_age,
                    end_age = supplemental_investment2.end_age,
                    amount = Normal(
                        supplemental_investment2.mean,
                        supplemental_investment2.std
                    )
                )
            ) for a ∈ retirement_age_range
        ]

        gbm = map(
            αμ -> VarGBM(;
                αμ,
                ημ = investment_parms.std_rate,
                ασ = investment_parms.mean_volitility,
                ησ = investment_parms.std_volitility,
                αμᵣ = recession_parms.mean_rate,
                ημᵣ = recession_parms.std_rate,
                ασᵣ = recession_parms.mean_volitility,
                ησᵣ = recession_parms.std_volitility
            ),
            (investment_growth.min):(investment_growth.step):(investment_growth.max)
        )

        recessions = [
            Transaction(; start_age = a, end_age = a + recession_parms.duration) for
            a ∈ retirement_age_range
        ]

        # configuration options
        config = (;
            log_times = age_range,
            # time step in years 
            Δt = 1 / 12,
            # start age of simulation 
            start_age = global_parms.start_age,
            # duration of simulation in years
            duration = global_parms.end_age - global_parms.start_age,
            # initial investment amount 
            start_amount =  start_amount = global_parms.start_amount ,
            # withdraw parameters 
            kw_withdraw = (; withdraws),
            # invest parameters
            kw_invest = (; investments),
            # interest parameters
            kw_market = (; gbm, recessions),
            # inflation parameters
            kw_inflation = (gbm = VarGBM(;
                αμ = inflation.mean_rate,
                ημ = inflation.std_rate,
                ασ = inflation.mean_volitility,
                ησ = inflation.std_volitility
            ),),
            # income parameters 
            kw_income = (income_sources = (
                Transaction(;
                    start_age = social_security.start,
                    amount = NominalAmount(;
                        amount = social_security.amount,
                        adjust = !social_security.adjust
                    )
                ),
                Transaction(;
                    start_age = pension.start,
                    end_age = pension.end_age,
                    amount = NominalAmount(;
                        amount = pension.amount,
                        adjust = !pension.adjust
                    )
                ),
                Transaction(;
                    start_age = supplemental.start,
                    end_age = supplemental.end_age,
                    amount = NominalAmount(;
                        amount = supplemental.amount,
                        adjust = !supplemental.adjust
                    )
                )
            ),)
        )

        yoked_values =
            [
                Pair(
                    (:kw_withdraw, :withdraws, :start_age),
                    (:kw_invest, :investments, 1, :end_age)
                ),
                Pair(
                    (:kw_withdraw, :withdraws, :start_age),
                    (:kw_market, :recessions, :start_age)
                )]
        results = grid_search(
            Model,
            Logger,
            global_parms.n_reps,
            config;
            threaded = true,
            yoked_values
        )
        df2 = to_dataframe(Model(; config...), results)
        df2.survived = df2.net_worth .> 0
        df2.retirement_age = map(x -> x[1].end_age, df2.invest_investments)
        df2.min_withdraw_amount = map(x -> x.amount.min_withdraw, df2.withdraw_withdraws)
        df2.mean_growth_rate = map(x -> x.αμ, df2.market_gbm)
        return df2
    end

    function simulate_single()
        investments = (
            Transaction(;
                start_age = global_parms.start_age,
                end_age = single_plot_menu.retirement_age,
                amount = Normal(primary_investment.mean, primary_investment.std)
            ),
            Transaction(;
                start_age = supplemental_investment1.start_age,
                end_age = supplemental_investment1.end_age,
                amount = Normal(
                    supplemental_investment1.mean,
                    supplemental_investment1.std
                )
            ),
            Transaction(;
                start_age = supplemental_investment2.start_age,
                end_age = supplemental_investment2.end_age,
                amount = Normal(
                    supplemental_investment2.mean,
                    supplemental_investment2.std
                )
            )
        )

        # configuration options
        config = (
            # time step in years
            Δt = 1 / 12,
            # start age of simulation
            start_age = global_parms.start_age,
            # duration of simulation in years
            duration = global_parms.end_age - global_parms.start_age,
            # initial investment amount
            start_amount = global_parms.start_amount,
            # withdraw parameters
            kw_withdraw = (withdraws = Transaction(;
                start_age = single_plot_menu.retirement_age,
                amount = AdaptiveWithdraw(;
                    min_withdraw = single_plot_menu.min_withdraw_rate,
                    percent_of_real_growth = withdraw_parms.percent_of_real_growth,
                    income_adjustment = withdraw_parms.income_adjustment,
                    volitility = withdraw_parms.volitility
                )),
            ),
            # invest parameters
            kw_invest = (; investments),
            # interest parameters
            kw_market = (
                # dynamic model of the stock market
                gbm = VarGBM(;
                    αμ = single_plot_menu.mean_growth_rate,
                    ημ = investment_parms.std_rate,
                    ασ = investment_parms.mean_volitility,
                    ησ = investment_parms.std_volitility,
                    αμᵣ = -0.05,
                    ημᵣ = 0.010,
                    ασᵣ = 0.040,
                    ησᵣ = 0.010
                ),
                recessions = Transaction(; start_age = 0, end_age = 0)
            ),
            # inflation parameters
            kw_inflation = (gbm = VarGBM(;
                αμ = 0.035,
                ημ = 0.005,
                ασ = 0.005,
                ησ = 0.0025
            ),),
            # income parameters
            kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
        )
        model = Model(; config...)
        times = get_times(model)
        n_reps = global_parms.n_reps
        n_steps = length(times)
        logger = Logger(; n_steps, n_reps)
        simulate!(model, logger, n_reps)
        return logger, model
    end
    nothing
end

# ╔═╡ c853496d-babe-4267-a2c1-62b8472426b8
let
    if run_simulation.run
        logger, model = simulate_single()
        times = get_times(model)
        survival_probs = mean(logger.net_worth .> 0, dims = 2)
        survival_plot = plot(
            times,
            survival_probs,
            leg = false,
            xlabel = "Age",
            grid = false,
            ylabel = "Survival Probability",
            xlims = (model.config.kw_withdraw.withdraws.start_age, times[end]),
            ylims = (0.5, 1.05),
            color = :black
        )

        # networth as a function of time. Darker shading indicates more likely values
        net_worth_plot = plot_gradient(
            times,
            logger.net_worth;
            xlabel = "Age",
            ylabel = "Investment Value",
            n_lines = 0
        )

        # growth rate distribution across repetitions of the simulation
        growth = logger.interest[:]
        interest_plot = histogram(
            growth,
            norm = true,
            xlabel = "Market Growth",
            ylabel = "Density",
            color = RGB(148 / 255, 173 / 255, 144 / 255),
            bins = 100,
            label = false,
            grid = false,
            xlims = (-0.7, 0.7)
        )
        vline!(
            interest_plot,
            [0.0],
            color = :black,
            linewidth = 1.5,
            linestyle = :dash,
            label = false
        )

        # income as a function of time.
        income_plot = plot_gradient(
            times,
            logger.total_income;
            xlabel = "Age",
            ylabel = "Total Income",
            xlims = (model.config.kw_withdraw.withdraws.start_age, times[end]),
            n_lines = 0,
            color = :blue
        )
        plot(
            survival_plot,
            net_worth_plot,
            interest_plot,
            income_plot,
            layout = (2, 2),
            size = (1200, 600),
            left_margin = 8mm,
            bottom_margin = 8mm
        )
    end
end

# ╔═╡ 441f980e-3d6b-445a-ad04-ec0db72a5bfe
begin
    function plot_std_income(df, clims)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        mean_income_plots1 = plot_sensitivity(
            df,
            [:retirement_age, :min_withdraw_amount],
            :total_income,
            :mean_growth_rate;
            row_label = "growth:",
            xlabel = "Retirement Age",
            ylabel = "Min Withdraw",
            colorbar_title = "STD Total Income",
            z_func = std,
            clims,
            age = age_range,
            grid_label_size = 12,
            margin = 0.35Plots.cm,
            xaxis = font(9),
            yaxis = font(9),
            size = (1200, 450)
        )
    end

    function get_std_income_extrema(df)
        return extrema(
            combine(
            groupby(df, [:retirement_age, :min_withdraw_amount, :mean_growth_rate, :time]),
            :total_income => std => :std
        ).std
        )
    end

    function plot_90_quantile_income(df, clims)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        mean_income_plots1 = plot_sensitivity(
            df,
            [:retirement_age, :min_withdraw_amount],
            :total_income,
            :mean_growth_rate;
            row_label = "growth:",
            xlabel = "Retirement Age",
            ylabel = "Min Withdraw",
            colorbar_title = "90th Quantile Total Income",
            z_func = x -> quantile(x, 0.90),
            clims,
            age = age_range,
            grid_label_size = 12,
            margin = 0.35Plots.cm,
            xaxis = font(9),
            yaxis = font(9),
            size = (1200, 450)
        )
    end

    function get_90_quantile_income_extrema(df)
        return extrema(
            combine(
            groupby(df, [:retirement_age, :min_withdraw_amount, :mean_growth_rate, :time]),
            :total_income => (x -> quantile(x, 0.90)) => :x
        ).x
        )
    end

    function plot_10_quantile_income(df, clims)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        mean_income_plots1 = plot_sensitivity(
            df,
            [:retirement_age, :min_withdraw_amount],
            :total_income,
            :mean_growth_rate;
            row_label = "growth:",
            xlabel = "Retirement Age",
            ylabel = "Min Withdraw",
            colorbar_title = "10th Quantile Total Income",
            z_func = x -> quantile(x, 0.10),
            clims,
            age = age_range,
            grid_label_size = 12,
            margin = 0.35Plots.cm,
            xaxis = font(9),
            yaxis = font(9),
            size = (1200, 450)
        )
    end

    function get_10_quantile_income_extrema(df)
        return extrema(
            combine(
            groupby(df, [:retirement_age, :min_withdraw_amount, :mean_growth_rate, :time]),
            :total_income => (x -> quantile(x, 0.10)) => :x
        ).x
        )
    end

    function plot_mean_income(df, clims)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        mean_income_plots1 = plot_sensitivity(
            df,
            [:retirement_age, :min_withdraw_amount],
            :total_income,
            :mean_growth_rate;
            row_label = "growth:",
            xlabel = "Retirement Age",
            ylabel = "Min Withdraw",
            colorbar_title = "Mean Total Income",
            clims,
            age = age_range,
            grid_label_size = 12,
            margin = 0.35Plots.cm,
            xaxis = font(9),
            yaxis = font(9),
            size = (1200, 450)
        )
    end

    function get_mean_income_extrema(df)
        return extrema(
            combine(
            groupby(df, [:retirement_age, :min_withdraw_amount, :mean_growth_rate, :time]),
            :total_income => mean => :mean
        ).mean
        )
    end

    function plot_survival_probability(df)
        age_range = (time_points.min):(time_points.step):(time_points.max)
        return plot_sensitivity(
            df,
            [:retirement_age, :min_withdraw_amount],
            :survived,
            :mean_growth_rate;
            row_label = "growth:",
            xlabel = "Retirement Age",
            ylabel = "Min Withdraw",
            clims = (0, 1),
            colorbar_title = "Survival Probability",
            age = age_range,
            grid_label_size = 12,
            margin = 0.35Plots.cm,
            xaxis = font(9),
            yaxis = font(9),
            size = (1200, 450)
        )
    end

    function get_survival_prob_extrema(df)
        return extrema(
            combine(
            groupby(df, [:retirement_age, :min_withdraw_amount, :mean_growth_rate, :time]),
            :total_income => mean => :mean
        ).mean
        )
    end
    nothing
end

# ╔═╡ f1276ea5-1a18-4309-8eca-e47da653f924
# ╠═╡ show_logs = false
begin
    Random.seed!(global_parms.seed)
    if run_simulation.run
        # run the simulations
        df_nonrecession = simulate_nonrecession()
        df_recession = simulate_recession()

        # compute clims for contour plot
        local vals = Float64[]
        if plot_menu.plot1 == "mean income"
            push!(vals, get_mean_income_extrema(df_nonrecession)...)
            push!(vals, get_mean_income_extrema(df_recession)...)
        elseif plot_menu.plot1 == "standard deviation income"
            push!(vals, get_std_income_extrema(df_nonrecession)...)
            push!(vals, get_std_income_extrema(df_recession)...)
        elseif plot_menu.plot1 == "90th quantile income"
            push!(vals, get_90_quantile_income_extrema(df_nonrecession)...)
            push!(vals, get_90_quantile_income_extrema(df_recession)...)
        elseif plot_menu.plot1 == "10th quantile income"
            push!(vals, get_10_quantile_income_extrema(df_nonrecession)...)
            push!(vals, get_10_quantile_income_extrema(df_recession)...)
        end

        if plot_menu.plot2 == "mean income"
            push!(vals, get_mean_income_extrema(df_nonrecession)...)
            push!(vals, get_mean_income_extrema(df_recession)...)
        elseif plot_menu.plot2 == "standard deviation income"
            push!(vals, get_std_income_extrema(df_nonrecession)...)
            push!(vals, get_std_income_extrema(df_recession)...)
        elseif plot_menu.plot2 == "90th quantile income"
            push!(vals, get_90_quantile_income_extrema(df_nonrecession)...)
            push!(vals, get_90_quantile_income_extrema(df_recession)...)
        elseif plot_menu.plot2 == "10th quantile income"
            push!(vals, get_10_quantile_income_extrema(df_nonrecession)...)
            push!(vals, get_10_quantile_income_extrema(df_recession)...)
        end
        local clims = extrema(vals)
        # make plots
        if plot_menu.plot1 == "survival probability"
            plot_non_recession1 = plot_survival_probability(df_nonrecession)
            plot_recession1 = plot_survival_probability(df_recession)
            header_non_recession1 =
                md"""#### Portfolio Survival: No Recession at Retirement"""
            header_recession1 = md"""#### Portfolio Survival: Recession at Retirement"""
        elseif plot_menu.plot1 == "mean income"
            plot_non_recession1 = plot_mean_income(df_nonrecession, clims)
            plot_recession1 = plot_mean_income(df_recession, clims)
            header_non_recession1 =
                md"""#### Mean Total Income: No Recession at Retirement"""
            header_recession1 = md"""#### Mean Total Income: Recession at Retirement"""
        elseif plot_menu.plot1 == "standard deviation income"
            plot_non_recession1 = plot_std_income(df_nonrecession, clims)
            plot_recession1 = plot_std_income(df_recession, clims)
            header_non_recession1 =
                md"""#### Standard Deviation Total Income: No Recession at Retirement"""
            header_recession1 =
                md"""#### Standard Deviation Total Income: Recession at Retirement"""
        elseif plot_menu.plot1 == "90th quantile income"
            plot_non_recession1 = plot_90_quantile_income(df_nonrecession, clims)
            plot_recession1 = plot_90_quantile_income(df_recession, clims)
            header_non_recession1 =
                md"""#### 90th Quantile Total Income: No Recession at Retirement"""
            header_recession1 =
                md"""#### 90th Quantile Total Income: Recession at Retirement"""
        elseif plot_menu.plot1 == "10th quantile income"
            plot_non_recession1 = plot_10_quantile_income(df_nonrecession, clims)
            plot_recession1 = plot_10_quantile_income(df_recession, clims)
            header_non_recession1 =
                md"""#### 10th Quantile Total Income: No Recession at Retirement"""
            header_recession1 =
                md"""#### 10th Quantile Total Income: Recession at Retirement"""
        end

        if plot_menu.plot2 == "survival probability"
            plot_non_recession2 = plot_survival_probability(df_nonrecession)
            plot_recession2 = plot_survival_probability(df_recession)
            header_non_recession2 =
                md"""#### Portfolio Survival: No Recession at Retirement"""
            header_recession2 = md"""#### Portfolio Survival: Recession at Retirement"""
        elseif plot_menu.plot2 == "mean income"
            plot_non_recession2 = plot_mean_income(df_nonrecession, clims)
            plot_recession2 = plot_mean_income(df_recession, clims)
            header_non_recession2 =
                md"""#### Mean Total Income: No Recession at Retirement"""
            header_recession2 = md"""#### Mean Total Income: Recession at Retirement"""
        elseif plot_menu.plot2 == "standard deviation income"
            plot_non_recession2 = plot_std_income(df_nonrecession, clims)
            plot_recession2 = plot_std_income(df_recession, clims)
            header_non_recession2 =
                md"""#### Standard Deviation Total Income: No Recession at Retirement"""
            header_recession2 =
                md"""#### Standard Deviation Total Income: Recession at Retirement"""
        elseif plot_menu.plot2 == "90th quantile income"
            plot_non_recession2 = plot_90_quantile_income(df_nonrecession, clims)
            plot_recession2 = plot_90_quantile_income(df_recession, clims)
            header_non_recession2 =
                md"""#### 90th Quantile Total Income: No Recession at Retirement"""
            header_recession2 =
                md"""#### 90th Quantile Total Income: Recession at Retirement"""
        elseif plot_menu.plot2 == "10th quantile income"
            plot_non_recession2 = plot_10_quantile_income(df_nonrecession, clims)
            plot_recession2 = plot_10_quantile_income(df_recession, clims)
            header_non_recession2 =
                md"""#### 10th Quantile Total Income: No Recession at Retirement"""
            header_recession2 =
                md"""#### 10th Quantile Total Income: Recession at Retirement"""
        end
    end
    nothing
end

# ╔═╡ b881055c-09ee-4869-8e36-5bf069d6bc23
run_simulation.run ? header_non_recession1 : nothing

# ╔═╡ 44c12623-53b5-4e4a-bd57-786fe6906191
# ╠═╡ show_logs = false
run_simulation.run ? plot_non_recession1 : nothing

# ╔═╡ 86349e14-31b8-439b-bde1-8659d02eefac
let
    label = nothing
    if run_simulation.run
        label = header_non_recession2
        if switch_view.switch
            label = header_recession1
        end
    end
    label
end

# ╔═╡ e32a80ee-5c0a-4d57-8d94-a38c43a5a24b
# ╠═╡ show_logs = false
let
    plot = run_simulation.run ? plot_non_recession2 : nothing
    if switch_view.switch
        plot = run_simulation.run ? plot_recession1 : nothing
    end
    plot
end

# ╔═╡ 1c5e5260-4972-4bfb-aa85-0ecae2fcb6fd
let
    label = nothing
    if run_simulation.run
        label = header_recession1
        if switch_view.switch
            label = header_non_recession2
        end
    end
    label
end

# ╔═╡ 967d7765-ecdf-4ae2-8197-12e69f274104
# ╠═╡ show_logs = false
let
    plot = run_simulation.run ? plot_recession1 : nothing
    if switch_view.switch
        plot = run_simulation.run ? plot_non_recession2 : nothing
    end
    plot
end

# ╔═╡ 9e5b896b-16ad-495c-8d62-ccdaf318993a
run_simulation.run ? header_recession2 : nothing

# ╔═╡ 6637f8ea-a336-46d4-8a2e-4bc0e88de392
# ╠═╡ show_logs = false
run_simulation.run ? plot_recession2 : nothing

# ╔═╡ a71ae122-24d4-45d8-9880-4730307aa4b6
TableOfContents()

# ╔═╡ a44775f9-c5b3-4eb6-beaf-ac5dac7c73e7
begin
    # allows details to be hidden/revealed
    details(x; summary = "Show more") = @htl("""
      	<details>
      		<summary>$(summary)</summary>
      		$(x)
      	</details>
      """)

    Summary(text) = @htl("<summary>$text</summary>")
    nothing
end

# ╔═╡ aaab4ae6-9775-48c3-b3b9-9b4566d3ef91
let
    text = md"""
    ###### Overview

    The purpose of this notebook is to stress test your retirement plan under a wide range of conditions, allowing you to identify potential points of failure. Based on your goals and risk tolerance, the results of the stress test can help you decide when to retire and whether you should make adjustments to your plan. 

    The stress test evaluates your retirement plan in terms of survival probability and mean total income while varying your retirement plan along three important dimensions---(1) retirement age, (2) monthly withdraw amount, and (3) investment growth rate. In addition, the stress test examines the robustness of your retirement plan to sequence-of-return risk by evaluating your plan under two conditions: (1) no rececssion upon retirement, and (2) a recession upon retirement. The results are conviniently displayed as a matrix of contour plots, allowing you to analyze the effect of these important variables across time. 

    ###### Instructions

    1. Complete each section by entering your information into the fields. Additional details can be found by clicking on the $\blacktriangleright$ icon below each panel. 
    2. Go to the section titled *Run* and check the box to run the stress test. Depending on the number of conditions you specify, the results may take a few moments to generate. 
    3. After the stress test completes, the results will populate a matrix of contour plots in the *results* section.

    ##### Miscellaneous  Information
    You can use the hyperlinks in the table of contents to the right to quickly navigate between sections. Also keep in mind that generating the plots may require a long time if the number of repetitions and conditions is large. The default number of reps (200) is useful for quick exploration, but 1,000 generates plots with higher fidelity. Although the stress test below  is sufficiently flexible to meet the needs of most people, it is possible to edit the code for further customization. The underlying code can be viewed by hovering the cursor over a given cell and clicking the icon located at the top left. For more details, see the package documentation at  [RetirementPlanners](https://itsdfish.github.io/RetirementPlanners.jl/dev/).

    """
    details(text; summary = "Overview and Instructions")
end

# ╔═╡ 6e8320a8-920b-4384-b3be-62682aec0e57
let
    text = md"""
    Global parameters control various aspects of the simulation, including timing and initial conditions. 

    * Start Age: your age at the beginng of the simulation, typically corresponding to your current age.

    * End Age: your age at the end of the simulation. 

    * Repetitions: the number of times each condition is repeated, each with a different set of random outcomes. Using a value of 200 is sufficient for initial exploration. Using a value of 1,000 results in a medium to high fidelity plot, but requires more computation time. 

    * Portfolio Value: the value of your investment portfolio at the beginning of the simulation (i.e., start age)  
    * Seed: initializes the random number generator in a specified state. Setting the seed to a specific value will result in a reproducible random set of on each run. By default, the seed is selected at random. You may input an integer.

    ##### Additional Information

    All units are expressed in constant, inflation-adjusted US dollars. The simulation uses time step parameter to controls the frequency with which the system is updated. The default time step is fixed to one month, which is an ideal value because it corresponds to a typical billing cycle, and strikes a good balance between speed and accuracy. Although not typically recommended, you can modify the time step parameter in the code cell before each stress test

    """
    details(text; summary = "Additional Information")
end

# ╔═╡ a083653f-e469-420c-aa16-267ac9449ea7
let
    text = md"""

     The *Time Points* parameters specify snapshots in time of your retirement plan's performance. The time points correspond to the column of the matrix of contour plots.  

     - Min: the minimum time point considered
     - Max: the naximum time point considered 
     - Step: the increment between successive time points

     !!! warning "Warning"
         Selecting a large number of time points will increase the simulation run time. Four to five time points is recommended.

     """
    details(text; summary = "Additional Information")
end

# ╔═╡ 1ffc8dfa-762d-46f2-9b83-46614b6f31bb
let
    text = md"""
    In the *Investment Schedule* panel, you can configure up to three investment schedules. Note that the contributions are made on a monthly basis within the specified time range. The contribution amounts are sampled from a normal distribution to reflect uncertainty in the contribution amount. The parameters for the contributions are as follows:   

    * Mean: the arithmatic average contribution

    * Standard Deviation: controls the width of the distribution

    * Start Age: the age at which the contributions begin

    * End Age: the age at which the contributions end

    ##### Contributions

    At the top, the primary contribution represents a job or standard income source. Unlike the other contributions, the schedule for the primary contribution is yoked to retirement: it starts at *start age* defined in *Global Parameters* and ends at the specified retirement age. The two supplemental contributions represent income from rental properties, a side hustle, or an inheritence (configured by setting start age equal to end age). By default, the two supplemental contributions are inactive, and have no constraints on the start and end ages.  

    ##### Additional Information

    The rationale for sampling from a distribution is to incorporate into the simulation uncertainty about investment contributions, due to factors, such as variable expenses, and bonuses. Approximately 70% of outcomes fall within the mean $\pm$ standard deviation, and approximately 95% of outcomes fall withinthe mean $\pm$ 2 $\times$ the standard deviation. Note: you can set the standard deviation to zero to invest a fixed amount each month. 
    """
    details(text; summary = "Additional Information")
end

# ╔═╡ 5e027840-c886-409f-bda2-01a232212b88
let
    text = md"""
    Both stress tests vary retirement age to determine whether your retirement plan breaks down at any point. Retirement age is an important determinant of portfolio survival probability and monthly income because it delays withdraws while taking advantage of growth potential and investment contributions. 

    - Min: the minimum retirement age considered 
    - Max: the maximum retirement age considered
    - Step: the increment between successive retirement ages

    !!! warning "Warning"
        Selecting a large number of retirement ages will increase the simulation run time. Typically, A range of approximately 5 retirement ages strikes the right balance between speed and informativeness.


    """
    details(text; summary = "Additional Information")
end

# ╔═╡ 8f97756b-7830-4c11-9d7a-fa5f373235ba
let
    text = md"""
     You can specify up to three income sources with different amounts, start ages, and end ages. Leave the values at zero if the income source does not apply to you.

     * Start Age: your age in years at the beginng of the simulation, typically corresponding to your current age.

     * End Age: your age in years at the simulation ends. 

     * Amount: the amount you expect to receive on a monthly basis. 

     * Cost of Living Adjustment: if checked, the amount increases with inflation. Otherwise, the specified amount decreases in 		value with inflation.

     ##### Additional Information
     The start age for social security ranges from 62 to 70, and benefits increase with start age. Cost of living adjustment is unchecked for pensions because most do not have a cost of living adjustment.
     """
    details(text; summary = "Additional Information")
end

# ╔═╡ 9800fe86-71b2-4c64-8151-6e05bb0a83b2
let
    text = md"""
    The stress tests vary the monthly withdraw amount to determine whether your retirement plan breaks down at any point. Monthly withdraw amount is an important determinant of portfolio survival probability and monthly total income because it determines how quickly your investments grow or deplete during retirement. 

    The following parameters correspond to the range of minimum monthly withdraw amount:

    - Min: the smallest minimum withdraw amount considered 
    - Max: the largest minimum withdraw amount considered 
    - Step: the increment between successive minimum withdraw amounts

    The following parameters modulate the withdraw amount. 

    - Income Adjustment: a number ranging between 0 and 1, which determines how much of other income sources (e.g., social security, pension, etc.) are subtracted from your investment withdraw amount. For example, setting this parameter is set to zero means no adjustment is made: total income is investment withdraw + Social Security + Pension + Supplemental Income. 
    - Percent of Real Growth: a number between 0 and 1 representing real (i.e., inflation adjusted) growth, which is multipled by the investment return of the current month. If this number is greater than the minimum withdraw amount, it is selected. Otherwise the minimum withdraw amount is selected.
    - volitility: a number between 0 and 1 which controls the standard deviation of the withdraw amount. This allows you to withdraw more than minimum withdraw amount subject to the constraint that the amount withdrawn cannot be less than the target minimum withdraw amount. The standard deviation scales with withdraw amount: standard deviation = volitlity $\times$ mean withdraw amount. Typical values range between 0 and .10. 

    ##### Overview of Withdraw Strategy.

    The withdraw strategy assumes there is a bare minimum amount needed to sustain one's lifestyle. The minimum amount will be withdrawn unless there are insufficient funds, in which case the non-zero amount in the investment prortfolio will be withdrawn. However, there are two adaptive components to the withdraw strategy. First, the amount withdrawn can exceed the minimum if the growth of your investments exceeds a specified threshold determined by the parameter *percent of real growth*. As an example, suppose *percent of real growth* is set to .50, your minimum monthly withdraw is `$`2,500, and the real growth for that month is `$`6,000. In this case, you will with draw half of `$`6,000 or `$`3,000 because it exceeds the minimum of `$`2,500. The second adaptive component allows you to withdraw less when other sources of income, such as social security, are received. If *Income Adjustment* is set to zero, total income is the sum of all of your income sources. If *Income Adjustment*  is .50, then half of the other income sources (e.g., social security) are subtracted from the minimum withdraw amount (subject to the constraint that the amount withdrawn is non-negative). 

    !!! warning "Warning"
        Selecting a large number of minimum withdraw amounts increase the simulation run time. A range of five values often strikes an optimal balance between speed and informativeness.
    """
    details(text; summary = "Additional Information")
end

# ╔═╡ 49ae8441-8a70-4bdc-9cd3-a7d7d5437e82
let
    text = md"""

     ##### Geometric Brownian Motion

     The dynamics of investments and inflation are modeled with Geometric Brownian Motion (GBM). The GBM can be used to model unbounded growth, such as a population of bacteria, or model growth in the stock market. The concept behind GBM is quite simple: a quantity grows exponentially at an average rate $\mu$ with volitility $\sigma$. The parameter $\sigma$ is important because it captures random fluctuations commonly observed in the stock market and inflation rate. In some cases, downward fluctuations can extend over a long time frame, leading to an economic recession. 

     To make the GBM more intuitive, the plot below shows the groth trajectories of 5 simulations of GBM over a 30 year period with parameters $\mu = .10$ (i.e., $10\%$ average growth) and $\sigma=.07$. Each trajectory follows a differ path, with some growing more than others. Growth is volitile rather than smooth. The expected growith over a 30 year period is $e^{.10 \cdot 30} \approx 20$ or 20 times the initial investment amount, and the expected doubling rate is $\frac{\log(2)}{.10} \approx 7$ years. 


     ##### Mixture Model

     One challenge in using GBM is setting the values of parameters $\mu$ and $\sigma$. The values depend primarily on two factors: the composition of your portfolio, and economic factors outside of your control. Historically, the S&P 500 has grown at rate of approximately $10\%$ per year on average. However, historical performance is not a guartee of future performance. Setting $\mu$ to $.09$ might be reasonable. However, setting $\mu$ to $.11$ might be reasonable too. We can use a similar line of reasoning for our choice of the volitlity parameter $\sigma$. 

     The best way to manage uncertainty in the values of $\mu$ and $\sigma$ is to draw a random value from a distribution on each simulation. Below, I will use a normal (bell-shaped) distribution for $\mu$ and a truncated normal distribution (forced to be positive) for $\sigma$. The normal distribution has two parameters: mean and standard deviation. The mean is the arithmetic average, and the standard deviation is a measure of the width or variability of the distribution. Approximately 70% of values will be between the mean plus or minus the standard deviation, and approximately 95% of values will be between the mean plus or minus 2 times the standard deviation. 

     ###### Stock Market

     For the stock market, we have:

     $\mu \sim \mathrm{Normal}(\mu_\alpha, .01)$

     $\sigma \sim \mathrm{TNormal}(.04, .010)_{0}^{\infty}$

     The mean or average for $\mu$ is $\mu_{\alpha}$ will be varied in the simulations below because it is one of the most important determinants of financial performance, and plotted on the y-axis of the plots below. 

     ###### Inflation

     For inflation, the model assumes the following:

     $\mu \sim \mathrm{Normal}(.035, .005)$

     $\sigma \sim \mathrm{TNormal}(.005, .0025)_{0}^{\infty}$

     Compared to the stock market, inflation typically grows at a slower rate and with less volitility. This is reflected in the parameters I selected. The federal reserve targets a rate of about 2%, and during the past 30 years the rate has typically been between 2% and 4%. The value above of 3.5% is somewhat pessimistic. 
     """
    details(text; summary = "Additional Information")
end

# let
# 	@bind show_gbm Slider(false:true, default = false)
# 	if show_gbm
# 		Δt = 1 / 100
# 		n_years = 30
# 		n_steps = Int(n_years / Δt)
# 		n_reps = 5
# 		times = range(0, n_years, length = n_steps + 1)
# 		dist = GBM(; μ=.10, σ=.07, x0 = 1)
# 		prices = rand(dist, n_steps, n_reps; Δt)
# 		plot(times, prices, leg=false, xlabel = "Time (years)", ylabel = "Investment Value")
# 	end
# end

# ╔═╡ 642254f2-c9e0-4638-a8e3-c4c6984a7b9c
let
    text = md"""

     Stress testing your retirement plan under multiple growth rate parameters is important because it is one of the primary determinants of the financial outcomes plotted below. The following values correspond to the range of minimum monthly withdraw amount:

     - Min: the minimum growth rate considered
     - Max: the naximum growth rate considered 
     - Step: the increment between successive growth rates

    - Standard Deviation Growth Rate: the standard deviation of growth rates across simulations
    - Mean Volitility: the average volitility across simulations
    - Standard Deviation Volitility: the standard deviation of volitility across simulations

     ##### Additional Information

     ###### Selecting Values

     Low, moderate, and high sustained growth rates are defined below as a point of reference.

     -  $\mu \approx .05$: low sustained growth
     -  $\mu \approx .075$: moderate sustained growth
     -  $\mu \approx .10$: high sustained sustained growth close to the historical average of S&P 500.

     Note: the growth rate depends partially on economic forces outside your control and the composition of your investment portfolio. For example, in an economy with an average growth rate, you could have low sustained growth if a large portion of your portfolio is invested in bonds. 

     ###### Model Details

     The values for parameters $\mu$ (growth rate) and $\sigma$ (volitility) are sampled from distributions to reflect uncertainty in their actual values. Letting $\mu_{\alpha}$ represent the mean of the growth rate, $\sigma_{\alpha}$ represent the standard deviation of the growth rate, $\mu_{\eta}$ represent the mean of volitility, and $\sigma_{\eta}$ repreent the standard deviation of volitlity, we have:

    $\mu \sim \mathrm{Normal}(\mu_{\alpha}, \sigma_{\alpha})$

    $\sigma \sim \mathrm{TNormal}(\mu_{\eta}, \sigma_{\eta})_{0}^{\infty}$

     As an example, consider the case in which $\mu_{\alpha} = .075$ and $\sigma_{\alpha} = .01$, then approximately 95% of sampled values will be $\mu = .075 \pm 2 \cdot .01$. 

     
    !!! warning "Warning"
    	Selecting a large number of growth rates will increase the simulation run time.
     """
    details(text; summary = "Additional Information")
end

# ╔═╡ 86eef8d7-a07e-44e1-8a78-a4d65ed7f474
let
    text = md"""

    Inflation---the general increase in prices---is important to consider because it decreases purchasing power and therefore the *real* growth of your investments. 

    - Mean Rate: the average growth rate of inflation across simulations.
    - Standard Deviation Growth Rate: the standard deviation of growth rates across simulations
    - Mean Volitility: the average volitility across simulations
    - Standard Deviation Volitility: the standard deviation of volitility across simulations

    ##### Additional Information

    ###### Selecting a Value

    During the past 25 years, inflation has varied between 2% and 4%, with the current inflation rate at approximately 3.5%. The stress tests reported below use $\mu=.035$ (i.e., 3.5%) as the default growth rate of consumer prices.

    ###### Model Details

    The values for parameters $\mu$ (growth rate) and $\sigma$ (volitility) are sampled from distributions to reflect uncertainty in their actual values. Letting $\mu_{\alpha}$ represent the mean of the growth rate, $\sigma_{\alpha}$ represent the standard deviation of the growth rate, $\mu_{\eta}$ represent the mean of volitility, and $\sigma_{\eta}$ repreent the standard deviation of volitlity, we have:

    $\mu \sim \mathrm{Normal}(\mu_{\alpha}, \sigma_{\alpha})$

    $\sigma \sim \mathrm{TNormal}(\mu_{\eta}, \sigma_{\eta})_{0}^{\infty}$

    As an example, consider the case in which $\mu_{\alpha} = .035$ and $\sigma_{\alpha} = .005$, then approximately 95% of sampled values will be $\mu = .035 \pm 2 \cdot .005$. 

    """
    details(text; summary = "Additional Information")
end

# ╔═╡ f2e6ffca-782f-4c40-ad9b-32615f783f0c
let
    text = md"""

    The parameters in this panel control the magnitude and duration of the recession in the recession condition. To maximize its effect, the recession begins concurrently with retirement. The two parameters are:

    * Growth Rate: a negative number reflecting the rate of decrease of your investment porfolio

    * Duration: the duration of the recession in years

    - Standard Deviation Growth Rate: the standard deviation of growth rates across simulations
    - Mean Volitility: the average volitility across simulations
    - Standard Deviation Volitility: the standard deviation of volitility across simulations

    ##### Additional Information

    As with investment growth and inflation, the recession is modeled as Geometric Brownian Motion (GBM), with negative mean growth rate $\mu_\alpha$. Letting $\mu_{\alpha} < 0$ represent the mean of the growth rate, $\sigma_{\alpha}$ represent the standard deviation of the growth rate, $\mu_{\eta}$ represent the mean of volitility, and $\sigma_{\eta}$ repreent the standard deviation of volitlity, we have:

    $\mu \sim \mathrm{Normal}(\mu_{\alpha}, \sigma_{\alpha})$

    $\sigma \sim \mathrm{TNormal}(\mu_{\eta}, \sigma_{\eta})_{0}^{\infty}$

    $\mu \sim \mathrm{Normal}(\mu_\alpha, .01)$

    $\sigma \sim \mathrm{TNormal}(.04, .010)_{0}^{\infty}$

    In sequence-of-return risk, the worst placement of a recession is during the first years of retirement because relative to a person in his or her 20s, there are few years for recovery, but relative to a person in his or her 80s, there are still many years of retirement remaining. Therefore, your retirement plan is considered robust if performance remains satisfactory after an early recession. Also, note that recessions can emerge naturally from the dynamics of the GBM. Consquentially, the results reported below reflect a mixture of recessions occuring at different times. 

    """
    details(text; summary = "Additional Information")
end

# ╔═╡ 7616b2ee-8df3-4de8-9831-1b6ac0e791c3
let
    text = md"""

    Note: that the simulations may run for a few moments depending on the number of repetitions and conditions is large.

    !!! tip "Tip"
    	Uncheck the box for *run simulation* to prevent the simulation from repeatedly restarting while editing the parameters.		
    """
    details(text; summary = "Additional Information")
end

# ╔═╡ 65bcd946-ad12-4ea6-a94f-5d1c5d2f74e8
let
    text = md"""

    ##### Survival Probability


    Surival probability is the relative frequency of simulations in which the portfolio investment is greater than zero. Formally, it is defined as

    $\Pr(V > 0) = \frac{1}{n}\sum_{i=1}^n x_i,$

    where $n$ is the number of simulations, $V$ is a random value representing the value of the portfolio, $v_i$ is the value of portfolio on the $i$th simulation, and $x_i$ indcates whether the portfolio survived on the $i$th simulation:

    $x_i = \begin{cases}
    1 \text{ if } v_i > 0,\\
    0 \text{ otherwise}
    \end{cases}$

    Surivival probability is computed for each time point, each retirement age, each minimum withdraw amount, and each growth rate, but the indices for those conditions are supressed in $x_i$ for berivity. Mean total income is computed in a similar fashion.

    ##### Interpreting Contour Plots

    Each contour plot below illustrates how survival probability is affected by retirement age represented along the x-axis and minimum withdraw amount along the y-axis. The survival probability is color coded from 0 (red) to 1 (green) with intermediate values indicated by orange and yellow. The effect of growth rate and time can be included arranging mutiple contour plots in a matrix where rows correspond to growth rate and columns correspond to time. The dimensions are summarized as follows:

    - x-axis: age of retirement
    - y-axis: minimum monthly withdraw amount 
    - outcome variable: the outcome variable for each plot is color coded as green for *good* or *preferred* and red for *bad* or *less preferred*. 
    - grid rows: each row of the grid corresponds to a different average investment growth rate, e.g.,  .05, .075, and .10
    - grid column: the contour plots within each column correspond to results are different ages, e.g., 70, 75, 80, and 85


    One way to interpret the contour plots is to examine the slope of the contour lines: vertical lines indicate retirement age is the only factor affecting survival probability, horizontal lines indicate minimum withdraw is the only factor affecting survival probability, and slanted lines indicate both variables contribute to survival probability (or mean total income). 	
    """

    details(text; summary = "Additional Information")
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CommonMark = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoExtras = "ed5d0301-4775-4676-b788-cf71e66ff8ed"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
RetirementPlanners = "2683bf95-d0b8-4c71-a7d3-b42f78bf1cf0"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"

[compat]
CommonMark = "~0.8.12"
DataFrames = "~1.7.0"
Distributions = "~0.25.111"
HypertextLiteral = "~0.9.5"
LaTeXStrings = "~1.4.0"
Plots = "~1.40.7"
PlutoExtras = "~0.7.13"
PlutoUI = "~0.7.62"
RetirementPlanners = "~0.6.4"
StatsPlots = "~0.15.7"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "be8ef5a863a809b44732b13e4865215e685d1d83"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "3b86719127f50670efe356bc11073d84b4ed7a5d"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.42"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "f7817e2e585aa6d924fd714df1e2a84be7896c60"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.3.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgCheck]]
git-tree-sha1 = "f9e9a66c9b7be1ad7372bbd9b062d9230c30c5ce"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.5.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "9b9b347613394885fd1c8c7729bfc60528faa436"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.4"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.BangBang]]
deps = ["Accessors", "ConstructionBase", "InitialValues", "LinearAlgebra"]
git-tree-sha1 = "26f41e1df02c330c4fa1e98d4aa2168fdafc9b1f"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.4.4"

    [deps.BangBang.extensions]
    BangBangChainRulesCoreExt = "ChainRulesCore"
    BangBangDataFramesExt = "DataFrames"
    BangBangStaticArraysExt = "StaticArrays"
    BangBangStructArraysExt = "StructArrays"
    BangBangTablesExt = "Tables"
    BangBangTypedTablesExt = "TypedTables"

    [deps.BangBang.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
    TypedTables = "9d95f2ec-7b3d-5a63-8d20-e2491e220bb9"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "2ac646d71d0d24b44f3f8c84da8c9f4d70fb67df"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.4+0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "1713c74e00545bfe14605d2a2be1712de8fbcb58"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.1"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "3e22db924e2945282e70c33b75d4dde8bfa44c94"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.15.8"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "403f2d8e209681fcbd9468a8514efff3ea08452e"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.29.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.CommonMark]]
deps = ["Crayons", "PrecompileTools"]
git-tree-sha1 = "5fdf00d1979fd4883b44b754fc3423175c9504b4"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.16"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "d9d26935a0bcffc87d2613ce14c527c99fc543fd"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.0"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "fb61b4812c49343d7ef0b533ba982c46021938a6"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.7.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4e1fe97fdaed23e9dc21d4d664bea76b65fc50a0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.22"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "473e9afc9cf30814eb67ffa5f2db7df82c3ad9fd"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.16.2+0"

[[deps.DefineSingletons]]
git-tree-sha1 = "0fba8b706d0178b4dc7fd44a96a92382c9065c2c"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.2"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "c7e3a542b999843086e2f29dac96a618c105be1d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.12"
weakdeps = ["ChainRulesCore", "SparseArrays"]

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "3e6d038b77f22791b8e3472b7c633acea1ecac06"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.120"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
git-tree-sha1 = "e7b7e6f178525d17c720ab9c081e4ef04429f860"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.4"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a4be429317c42cfae6a7fc03c31bad1970c310d"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+1"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d55dffd9ae73ff72f1c0482454dcf2ec6c6c4a63"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.5+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "53ebe7511fa11d33bec688a9178fac4e49eeee00"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.2"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "7de7c78d681078f027389e067864a8d53bd7c3c9"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.8.1"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6d6219a004b8cf1e0b4dbe27a2860b8e04eba0be"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.11+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "301b5d5d731a0654825f1f2e906990f7141a106b"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.16.0+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "2c5512e11c791d1baed2049c5652441b28fc6a31"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "fcb0584ff34e25155876418979d4c8971243bb89"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+2"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Qt6Wayland_jll", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "7ffa4049937aeba2e5e1242274dc052b0362157a"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.14"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "98fc192b4e4b938775ecd276ce88f539bcec358e"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.14+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "b0036b392358c80d2d2124746c2bf3d48d457938"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.82.4+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a6dbda1fd736d60cc477d99f2e7a042acfa46e8"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.15+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "f93655dc73d7a0b4a368e3c0bce296ae035ad76e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.16"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "55c53be97790242c29031e5cd45e8ac296dadda3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.0+0"

[[deps.HypergeometricFunctions]]
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "68c173f4f449de5b438ee67ed0c9c748dc31a2ec"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.28"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InitialValues]]
git-tree-sha1 = "4da0f88e9a39111c2fa3add390ab15f3a44f3ca3"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.3.1"

[[deps.InlineStrings]]
git-tree-sha1 = "6a9fde685a7ac1eb3495f8e812c5a7c3711c2d5e"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.3"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "0f14a5456bdc6b9731a5682f439a672750a09e48"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2025.0.4+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["REPL", "Random", "fzf_jll"]
git-tree-sha1 = "82f7acdc599b65e0f8ccd270ffa1467c21cb647b"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.11"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eac1206917768cb54957c65a615460d87b455fc1"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.1+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "7d703202e65efa1369de1279c162b915e245eed1"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.9"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eb62a3deb62fc6d8822c0c4bef73e4412419c5d8"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.8+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c602b1127f4751facb671441ca72715cc95938a"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.3+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "cd10d2cc78d34c0e2a3a36420ab607b611debfbb"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.7"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "27ecae93dd25ee0909666e6835051dd684cc035e"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+2"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "d36c21b9e7c172a44a10484125024495e2625ac0"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.1+1"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a31572773ac1b745e0343fe5e2c8ddda7a37e997"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.41.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "4ab7581296671007fc33f07a721631b8855f4b1d"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.1+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "321ccef73a96ba828cd51f2ab5b9f917fa73945a"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.41.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "5de60bc6cb3899cd318d80d627560fae2e2d99ae"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2025.0.1+1"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.MicroCollections]]
deps = ["Accessors", "BangBang", "InitialValues"]
git-tree-sha1 = "44d32db644e84c75dab479f1bc15ee76a1a3618f"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.2.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.MultivariateStats]]
deps = ["Arpack", "Distributions", "LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI", "StatsBase"]
git-tree-sha1 = "816620e3aac93e5b5359e4fdaf23ca4525b00ddf"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.10.3"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.NamedTupleTools]]
git-tree-sha1 = "90914795fc59df44120fe3fff6742bb0d7adb1d0"
uuid = "d9ec5142-1e00-5aa0-9d6a-321866360f50"
version = "0.14.3"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "8a3271d8309285f4db73b4f662b1b290c715e85e"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.21"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
git-tree-sha1 = "117432e406b5c023f665fa73dc26e79ec3630151"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.17.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.5+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "9216a80ff3682833ac4b733caa8c00390620ba5d"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.0+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "f07c06228a1c670ae4c87d1276b92c7c597fdda0"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.35"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3b31172c032a1def20c98dae3f2cdc9d10e3b561"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.56.1+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "db76b1ecd5e9715f3d043cec13b2ec93ce015d53"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.44.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "41031ef3a1be6f5bbbf3e8073f210556daeae5ca"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.3.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "3ca9a356cd2e113c420f2c13bea19f8d3fb1cb18"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.3"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "809ba625a00c605f8d00cd2a9ae19ce34fc24d68"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.13"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoExtras]]
deps = ["AbstractPlutoDingetjes", "DocStringExtensions", "HypertextLiteral", "InteractiveUtils", "Markdown", "PlutoUI", "REPL", "Random"]
git-tree-sha1 = "91d3820f5910572fd9c6077f177ba375e06f7a0e"
uuid = "ed5d0301-4775-4676-b788-cf71e66ff8ed"
version = "0.7.15"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "d3de2694b52a01ce61a036f18ea9c0f61c4a9230"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.62"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "13c5103482a8ed1536a54c08d0e742ae3dca2d42"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.4"

[[deps.PtrArrays]]
git-tree-sha1 = "1d36ef11a9aaf1e8b74dacc6a731dd1de8fd493d"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.3.0"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "492601870742dcd38f233b23c3ec629628c1d724"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.7.1+1"

[[deps.Qt6Declarative_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6ShaderTools_jll"]
git-tree-sha1 = "e5dd466bf2569fe08c91a2cc29c1003f4797ac3b"
uuid = "629bc702-f1f5-5709-abd5-49b8460ea067"
version = "6.7.1+2"

[[deps.Qt6ShaderTools_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "1a180aeced866700d4bebc3120ea1451201f16bc"
uuid = "ce943373-25bb-56aa-8eca-768745ed7b5a"
version = "6.7.1+1"

[[deps.Qt6Wayland_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6Declarative_jll"]
git-tree-sha1 = "729927532d48cf79f49070341e1d918a65aba6b0"
uuid = "e99dba38-086e-5de3-a5b1-6e4c66e897c3"
version = "6.7.1+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9da16da70037ba9d701192e27befedefb91ec284"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.2"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Referenceables]]
deps = ["Adapt"]
git-tree-sha1 = "02d31ad62838181c1a3a5fd23a1ce5914a643601"
uuid = "42d2dcc6-99eb-4e98-b66c-637b7d73030e"
version = "0.1.3"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.RetirementPlanners]]
deps = ["ConcreteStructs", "DataFrames", "Distributions", "NamedTupleTools", "PrettyTables", "ProgressMeter", "Random", "SafeTestsets", "SmoothingSplines", "StatsBase", "ThreadsX"]
git-tree-sha1 = "f82ef0409c0052e19f6cd23ee2afe29fa58ff5fe"
uuid = "2683bf95-d0b8-4c71-a7d3-b42f78bf1cf0"
version = "0.6.4"
weakdeps = ["Plots"]

    [deps.RetirementPlanners.extensions]
    PlotsExt = "Plots"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "852bd0f55565a9e973fcfee83a84413270224dc4"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.8.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SafeTestsets]]
git-tree-sha1 = "81ec49d645af090901120a1542e67ecbbe044db3"
uuid = "1bc83da4-3b8d-516f-aca4-4fe02f6d838f"
version = "0.1.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "712fb0231ee6f9120e005ccd56297abbc053e7e0"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.8"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "c5391c6ace3bc430ca630251d02ea9687169ca68"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.2"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.SmoothingSplines]]
deps = ["LinearAlgebra", "Random", "Reexport", "StatsBase"]
git-tree-sha1 = "3a68e878003f7d6ea0be9e3bafcabfb79f5a70ee"
uuid = "102930c3-cf33-599f-b3b1-9a29a5acab30"
version = "0.3.2"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "41852b8679f78c8d8961eeadc8f62cef861a52e3"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.5.1"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "e08a62abc517eb79667d0a29dc08a3b589516bb5"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.15"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "95af145932c2ed859b63329952ce8d633719f091"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.3"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "0feb6b9031bd5c51f9072393eb5ab3efd31bf9e4"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.13"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "b81c5035922cc89c2d9523afc6c54be512411466"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.5"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "8e45cecc66f3b42633b8ce14d431e8e57a3e242e"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "NaNMath", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "3b1dcbf62e469a67f6733ae493401e53d92ff543"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.15.7"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "725421ae8e530ec29bcbdddbe91ff8053421d023"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.1"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.ThreadsX]]
deps = ["Accessors", "ArgCheck", "BangBang", "ConstructionBase", "InitialValues", "MicroCollections", "Referenceables", "SplittablesBase", "Transducers"]
git-tree-sha1 = "70bd8244f4834d46c3d68bd09e7792d8f571ef04"
uuid = "ac1d9e8a-700a-412c-b207-f0111f4b6c0d"
version = "0.1.12"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Transducers]]
deps = ["Accessors", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "ConstructionBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "SplittablesBase", "Tables"]
git-tree-sha1 = "7deeab4ff96b85c5f72c824cae53a1398da3d1cb"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.84"

    [deps.Transducers.extensions]
    TransducersAdaptExt = "Adapt"
    TransducersBlockArraysExt = "BlockArrays"
    TransducersDataFramesExt = "DataFrames"
    TransducersLazyArraysExt = "LazyArrays"
    TransducersOnlineStatsBaseExt = "OnlineStatsBase"
    TransducersReferenceablesExt = "Referenceables"

    [deps.Transducers.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    BlockArrays = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    LazyArrays = "5078a376-72f3-5289-bfd5-ec5146d43c02"
    OnlineStatsBase = "925886fa-5bf2-5e8e-b522-a9147a512338"
    Referenceables = "42d2dcc6-99eb-4e98-b66c-637b7d73030e"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "cbbebadbcc76c5ca1cc4b4f3b0614b3e603b5000"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d62610ec45e4efeabf7032d67de2ffdea8344bed"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.22.1"
weakdeps = ["ConstructionBase", "InverseFunctions"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "85c7811eddec9e7f22615371c3cc81a504c508ee"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+2"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "5db3e9d307d32baba7067b13fc7b5aa6edd4a19a"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.36.0+0"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "e9aeb174f95385de31e70bd15fa066a505ea82b9"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.7"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "b8b243e47228b4a3877f1dd6aee0c5d56db7fcf4"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.6+1"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fee71455b0aaa3440dfdd54a9a36ccef829be7d4"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.1+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a3ea76ee3f4facd7a64684f9af25310825ee3668"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.2+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "9c7ad99c629a44f81e7799eb05ec2746abb5d588"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.6+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "b5899b25d17bf1889d25906fb9deed5da0c15b3b"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.12+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "6c74ca84bbabc18c4547014765d194ff0b4dc9da"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.4+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "a4c0ee07ad36bf8bbce1c3bb52d21fb1e0b987fb"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.7+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "9caba99d38404b285db8801d5c45ef4f4f425a6d"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.1+0"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "a376af5c7ae60d29825164db40787f15c80c7c54"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.8.3+0"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll"]
git-tree-sha1 = "a5bc75478d323358a90dc36766f3c99ba7feb024"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.6+0"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "aff463c82a773cb86061bce8d53a0d976854923e"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.5+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "e3150c7400c41e207012b41659591f083f3ef795"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.3+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "801a858fc9fb90c11ffddee1801bb06a738bda9b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.7+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "00af7ebdc563c9217ecc67776d1bbf037dbcebf4"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.44.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6a34e0e0960190ac2a4363a1bd003504772d631"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.61.1+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3cad2cf2c8d80f1d17320652b3ea7778b30f473f"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.3.0+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522c1df09d05a71785765d19c9524661234738e9"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.11.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "002748401f7b520273e2b506f61cab95d4701ccf"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.48+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d5a767a3bb77135a99e433afe0eb14cd7f6914c3"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2022.0.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "c950ae0a3577aec97bfccf3381f66666bc416729"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.8.1+0"
"""

# ╔═╡ Cell order:
# ╟─cd96a4a8-faf8-4a4c-a6bd-2a84ca684597
# ╟─aaab4ae6-9775-48c3-b3b9-9b4566d3ef91
# ╟─3f24d444-8eff-4957-9260-af2d4f2c5583
# ╟─8a873dad-7c41-4cba-b430-506e57ed0eb2
# ╟─6e8320a8-920b-4384-b3be-62682aec0e57
# ╟─142a098f-aa0c-4b20-be35-59024367b16e
# ╟─6ac4883c-974b-4cee-a0d0-d064ac4d1cc8
# ╟─a083653f-e469-420c-aa16-267ac9449ea7
# ╟─989a8734-b0c4-4d84-bd52-b44cd1287642
# ╟─c4398cff-af01-4ad5-a8a4-9af6c5076ab3
# ╟─0a671048-d73a-498b-a530-56e01026ad73
# ╟─6ab60779-eadd-4624-a8e5-206d153d0b43
# ╟─1ffc8dfa-762d-46f2-9b83-46614b6f31bb
# ╟─2bf35243-4a89-45a1-b562-f4854c350455
# ╟─4e6823e4-6542-4099-9834-f00b06953258
# ╟─5e027840-c886-409f-bda2-01a232212b88
# ╟─32dbc935-ee1c-453d-b5f9-81cb9264b62e
# ╟─7e7d025a-0f66-4259-b039-2935eb942638
# ╟─5452bfb7-1809-4cf5-a1c4-8fb19db0fdda
# ╟─52e1ef00-71de-4a97-886d-1276bce74d29
# ╟─8f97756b-7830-4c11-9d7a-fa5f373235ba
# ╟─2b9e3b46-18f1-4d00-8a40-cb99e8bd1691
# ╟─50d919c6-4f86-4e4d-a08d-7f23486ff9ec
# ╟─40faa877-5477-47f2-a92a-8ddf00528311
# ╟─9800fe86-71b2-4c64-8151-6e05bb0a83b2
# ╟─31803b5b-3205-4d1f-b49e-98ebf7cb3eb9
# ╟─49ae8441-8a70-4bdc-9cd3-a7d7d5437e82
# ╟─ca02fd88-b208-4492-ae31-85d5c8707af9
# ╟─bda54ee1-c009-461c-b7d4-d105e340da56
# ╟─7e4cbe2a-dd08-4298-b9a4-32f0f659efa8
# ╟─642254f2-c9e0-4638-a8e3-c4c6984a7b9c
# ╟─989bd0e5-33d5-4974-a044-bd2af180b5e4
# ╟─cb5e4707-5cc8-4a0d-a1f8-ac20875d94e9
# ╟─86eef8d7-a07e-44e1-8a78-a4d65ed7f474
# ╟─42ac4169-ec26-4882-aa64-aeed3e609ce0
# ╟─e437c0c7-f405-4e1f-94fc-79605774a824
# ╟─f2e6ffca-782f-4c40-ad9b-32615f783f0c
# ╟─29008274-3a15-4283-98fb-7a9a10bd4a2a
# ╟─05f0763a-e78f-4aa6-9f3f-31015490cacb
# ╟─75523d40-71e9-44d9-abd4-fc963fc42fc2
# ╟─7616b2ee-8df3-4de8-9831-1b6ac0e791c3
# ╟─2075ba63-a576-4df5-a1d6-8be2f27c2d41
# ╟─bc85326b-60c3-4cd4-bc3a-70ce83800110
# ╟─2c0b96a4-19fb-4d80-b68e-89af92722db7
# ╟─65bcd946-ad12-4ea6-a94f-5d1c5d2f74e8
# ╟─cf860556-a4c7-441d-94b2-13c4d9f608a4
# ╟─b881055c-09ee-4869-8e36-5bf069d6bc23
# ╟─44c12623-53b5-4e4a-bd57-786fe6906191
# ╟─86349e14-31b8-439b-bde1-8659d02eefac
# ╟─e32a80ee-5c0a-4d57-8d94-a38c43a5a24b
# ╟─1c5e5260-4972-4bfb-aa85-0ecae2fcb6fd
# ╟─967d7765-ecdf-4ae2-8197-12e69f274104
# ╟─9e5b896b-16ad-495c-8d62-ccdaf318993a
# ╟─6637f8ea-a336-46d4-8a2e-4bc0e88de392
# ╟─63d97245-a135-4cb8-9221-524b436dc0c5
# ╟─fb097e5d-71dc-4530-a250-6a721ca10b8f
# ╟─c853496d-babe-4267-a2c1-62b8472426b8
# ╟─f1276ea5-1a18-4309-8eca-e47da653f924
# ╟─1d89b285-07b2-400b-804f-88f52b0b96dd
# ╟─441f980e-3d6b-445a-ad04-ec0db72a5bfe
# ╟─8486baa8-1572-11ef-3bf6-115dd34a73b1
# ╟─a71ae122-24d4-45d8-9880-4730307aa4b6
# ╟─a44775f9-c5b3-4eb6-beaf-ac5dac7c73e7
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
