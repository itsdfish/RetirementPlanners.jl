using Documenter
using RetirementPlanners

makedocs(
    warnonly = true,
    sitename="RetirementPlanners",
    format=Documenter.HTML(
        assets=[
            asset(
                "https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap",
                class=:css,
            ),
        ],
        collapselevel=1,
    ),
    modules=[
        RetirementPlanners, 
        # Base.get_extension(SequentialSamplingModels, :TuringExt),  
        # Base.get_extension(SequentialSamplingModels, :PlotsExt) 
    ],
    pages=[
        "Home" => "index.md",
        "Basic Usage" => "basic_usage.md",
        "API" => "api.md"
    ]
)

deploydocs(
    repo="github.com/itsdfish/RetirementPlanners.jl.git",
)