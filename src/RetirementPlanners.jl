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
using ProgressMeter: ncalls_map
using StatsBase: cor2cov
using StatsBase: sample
using StatsBase: Weights
using ThreadsX

import Distributions: fit
import Distributions: mean
import Distributions: rand
import Distributions: std
import Distributions: var
import ProgressMeter: ncalls

export AbstractGBM
export AbstractVarGBM
export AbstractTransaction
export AbstractModel
export AbstractLogger
export AbstractState

export AdaptiveInvestment
export AdaptiveWithdraw
export GBM
export Transaction
export MGBM
export Model
export Logger
export MvGBM
export NominalAmount
export State
export VarGBM

export can_transact
export fit
export get_all_times
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
export transact
export update!
export var
export withdraw!

export default_log!
export dynamic_inflation
export dynamic_market
export fixed_inflation
export fixed_market
export invest!
export update_income!
export update_investments!
export variable_inflation
export variable_market

include("structs.jl")
include("core.jl")
include("distributions.jl")
include("utilities.jl")
include("grid_search.jl")
include("update_functions/income.jl")
include("update_functions/inflation.jl")
include("update_functions/market.jl")
include("update_functions/invest.jl")
include("update_functions/logging.jl")
include("update_functions/investments.jl")
include("update_functions/withdraw.jl")
end
