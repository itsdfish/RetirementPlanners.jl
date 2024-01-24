module RetirementPlanners

    using ConcreteStructs
    using Distributions: ContinuousUnivariateDistribution
    using Distributions: Normal 
    using PrettyTables
    
    import Distributions: rand 

    export AbstractModel
    export AbstractLogger
    export AbstractState 

    export GBM
    export Model
    export Logger
    export State 

    export get_times
    export grid_search
    export increment!
    export plot_gradient
    export rand
    export simulate! 
    export update!

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

    include("structs.jl")
    include("core.jl")
    include("update_functions.jl")
    include("utilities.jl")
    include("distributions.jl")
end
