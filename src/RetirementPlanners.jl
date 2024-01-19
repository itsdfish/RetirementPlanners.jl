module RetirementPlanners

    using ConcreteStructs
    using PrettyTables 
    
    export AbstractModel
    export AbstractLogger
    export AbstractState 

    export Model
    export Logger
    export State 

    export get_times
    export simulate! 
    export update!

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
end
