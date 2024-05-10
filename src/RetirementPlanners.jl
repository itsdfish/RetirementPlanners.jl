module RetirementPlanners

using ConcreteStructs
using Distributions: ContinuousUnivariateDistribution
using Distributions: Distribution
using Distributions: MvNormal
using Distributions: Normal
using Distributions: truncated
using NamedTupleTools
using PrettyTables
using ProgressMeter
using StatsBase: cor2cov
using StatsBase: sample
using StatsBase: Weights
using ThreadsX

import Distributions: fit
import Distributions: mean
import Distributions: rand
import Distributions: std
import Distributions: var

export AbstractGBM
export AbstractTransaction
export AbstractModel
export AbstractLogger
export AbstractState

export AdaptiveInvestment
export AdaptiveWithdraw
export AdjustedAmount
export GBM
export Transaction
export MGBM
export Model
export Logger
export MvGBM
export State
export VarGBM

export fit
export get_times
export grid_search
export increment!
export is_event_time
export mean
export plot_gradient
export plot_sensitivity
export rand
export simulate!
export std
export to_dataframe
export update!
export var
export withdraw!

export dynamic_inflation
export dynamic_interest

export default_log!
export default_net_worth
export fixed_inflation
export fixed_interest
export fixed_invest
export fixed_withdraw

export variable_income
export variable_inflation
export invest!
export variable_invest
export variable_withdraw
export update_income!

include("structs.jl")
include("core.jl")
include("distributions.jl")
include("utilities.jl")
include("grid_search.jl")
include("update_functions/income.jl")
include("update_functions/inflation.jl")
include("update_functions/interest.jl")
include("update_functions/invest.jl")
include("update_functions/logging.jl")
include("update_functions/net_worth.jl")
include("update_functions/withdraw.jl")
end
