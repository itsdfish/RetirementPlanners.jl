module RetirementPlanners

    using ConcreteStructs
    using PrettyTables 
    
    export AbstractModel
    export AbstractEvent
    export AbstractLogger
    export AbstractState 

    export Model
    export Event
    export Logger
    export State 

    export get_times
    export simulate! 
    export update!

    export fixed_inflation
    export fixed_interest 

    include("structs.jl")
    include("core.jl")
    include("update_functions.jl")
    include("utilities.jl")
end
