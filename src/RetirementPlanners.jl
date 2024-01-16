module RetirementPlanners

    using ConcreteStructs 
    
    export AbstractModel
    export AbstractEvent
    export AbstractLogger
    export AbstractState 

    export Model
    export Event
    export Logger
    export State 

    export get_times
    export invest!
    export simulate! 
    export update!
    export update_inflation!
    export update_interest!
    export update_net_worth!
    export withdraw!

    include("structs.jl")
    include("functions.jl")

end
