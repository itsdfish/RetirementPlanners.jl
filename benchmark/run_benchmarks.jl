####################################################################################################
#                                       set up
####################################################################################################
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
#                                           run simulation
###############################################################################################################
times = get_times(model)
n_reps = 1000
n_steps = length(times)
logger = Logger(; n_steps, n_reps)
suite["simulate!"] = @benchmarkable simulate!(model, logger, n_reps)
