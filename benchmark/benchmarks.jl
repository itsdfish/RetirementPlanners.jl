##############################################################################################################
#                                       set up
##############################################################################################################
using BenchmarkTools
using RetirementPlanners
using Distributions
###############################################################################################################
#                                           setup simulation
###############################################################################################################
suite = BenchmarkGroup()
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
        amount = Normal(625.0, 100)
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
        # recession: age => duration
        recessions = Dict(0 => 0)
    ),
    # inflation parameters
    kw_inflation = (gbm = VarGBM(; αμ = 0.035, ημ = 0.005, ασ = 0.005, ησ = 0.0025),),
    # income parameters 
    kw_income = (income_sources = Transaction(; start_age = 67, amount = 2000),)
)
# setup retirement model
model = Model(; config...)
###############################################################################################################
#                                           run benchmarks
###############################################################################################################
times = get_times(model)
n_steps = length(times)
suite["simulate!"] = BenchmarkGroup()
for n_reps ∈ [10, 100, 1000, 10_000]
    suite["simulate!"][n_reps] = @benchmarkable(
        simulate!($model, logger, n_reps),
        setup = (logger = Logger(; n_steps, n_reps = $n_reps); n_reps = $n_reps)
    )
end

Δt = 1 / 100
n_years = 10
n_steps = Int(n_years / Δt)
dist = GBM(; μ = 0.10, σ = 0.10, x0 = 1)
suite["GBM"] = BenchmarkGroup()
for n_reps ∈ [10, 100, 1000, 10_000]
    suite["GBM"][n_reps] = @benchmarkable rand($dist, $n_steps, $n_reps; Δt = $Δt)
end

Δt = 1 / 100
n_years = 10
n_steps = Int(n_years / Δt)
dist = MvGBM(; μ  = [0.10, 0.05], σ = fill(0.05, 2), ρ = [1.0 0.4; 0.4 1], ratios = [0.25, 0.75])
suite["MvGBM"] = BenchmarkGroup()
for n_reps ∈ [10, 100, 1000, 10_000]
    suite["MvGBM"][n_reps] = @benchmarkable rand($dist, $n_steps, $n_reps; Δt = $Δt)
end

suite["update_income!"] = @benchmarkable(
    update_income!($model, 2.5; income_sources),
    setup = (income_sources = Transaction(; start_age = 2, end_age = 3, amount = 100))
)

suite["withdraw!"] = @benchmarkable(
    withdraw!($model, 68; withdraws),
    setup = (withdraws = Transaction(;
        start_age = 67,
        amount = AdaptiveWithdraw(;
            min_withdraw = 1000,
            percent_of_real_growth = 1,
            income_adjustment = 0.0,
            volitility = 0.5
        )
    ))
)

suite["invest!"] = @benchmarkable(
    invest!($model, 66; investments),
    setup = (investments =
        Transaction(; start_age = 25, end_age = 67, amount = Normal(50, 0)))
)
