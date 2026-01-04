using Documenter
using RetirementPlanners
using Plots

makedocs(
    warnonly = true,
    sitename = "RetirementPlanners",
    format = Documenter.HTML(
        size_threshold = nothing,
        assets = [
            asset(
            "https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap",
            class = :css
        )
        ],
        collapselevel = 1
    ),
    modules = [
        RetirementPlanners
        # Base.get_extension(SequentialSamplingModels, :TuringExt),  
        Base.get_extension(RetirementPlanners, :PlotsExt)
    ],
    pages = [
        "Home" => "index.md",
        "Examples" => [
            "Basic Example" => "basic_example.md",
            "Advanced Example" => "advanced_example.md",
            "Custom Example" => "custom_example.md"
        ],
        "Plotting" => "plotting.md",
        "Notebook" => "notebook.md",
        "API" => "api.md"
    ]
)

deploydocs(repo = "github.com/itsdfish/RetirementPlanners.jl.git")
