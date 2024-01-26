module RetirementPlanners

    using ConcreteStructs
    using Distributions: ContinuousUnivariateDistribution
    using Distributions: Normal 
    using PrettyTables
    
    import Distributions: fit
    import Distributions: mean
    import Distributions: rand 
    import Distributions: std
    import Distributions: var 
    
    export AbstractModel
    export AbstractLogger
    export AbstractState 

    export GBM
    export Model
    export Logger
    export State 

    export fit
    export get_times
    export grid_search
    export increment!
    export mean
    export plot_gradient
    export rand
    export simulate!
    export std 
    export update!
    export var

    export dynamic_inflation
    export dynamic_interest

    export default_log!
    export default_net_worth
    export fixed_income
    export fixed_inflation
    export fixed_interest 
    export fixed_investment
    export fixed_withdraw
    
    export variable_income
    export variable_inflation
    export variable_interest
    export variable_investment
    export variable_withdraw
println(pwd())
    include("structs.jl")
    include("core.jl")
    include("utilities.jl")
    include("distributions.jl")
    include("update_functions/income.jl")
    include("update_functions/inflation.jl")
    include("update_functions/interest.jl")
    include("update_functions/invest.jl")
    include("update_functions/logging.jl")
    include("update_functions/net_worth.jl")
    include("update_functions/withdraw.jl")
end
