!!! warning "Disclaimer"
    Monte Carlo simulations are useful tools for stress testing financial/retirement plans under a wide range of uncertain conditions. As with any model, Monte Carlo simulations are only as good as the assumptions one makes. This package is not intended to be financial advice, but rather an open source tool for planning and research. When in doubt, seek the counsel of a professional financial planner. 

## Overview

`RetirementPlanners.jl` is a framework for performing Monte Carlo simulations of retirement investment performance under various assumptions specifed by the user. The primary goal of the framework is to provide a high degree of flexibility and customization while offering a set of user-friendly options from which users can choose. These goals are achieved as follows:

1. The package allows the user to tweak the investment simulations by selecting from a set of pre-defined update functions which have adjustable parameters.
2. The package allows the user to define custom update functions which integrate seamlessly with the API. 
3. The package allows the user to perform a grid search over simulation parameters to systematically explore their effects on outcome variables, such as net worth.

## How does it work?

`RetirementPlanners.jl` performs a discrete time simulation, meaning the state of the system is updated at fixed time steps—typically, representing years or months. On each time step, the `update!` is called, and updates the system in a manner defined by the user. By default, `update!` calls seven subordinate functions:

1. `withdraw!`: withdraw money
2. `invest!`: invest money
3. `update_income!`: update sources of income, such as social security, pension etc. 
4. `update_inflation!`: compute inflation
5. `update_interest!`: compute interest 
6. `update_net_worth!`: compute net worth 
7. `log!`: log desired variables

Each function above is treated as a variable with default value that can be overwritten to suit your needs. There are two ways to overwrite the default functions: First, you can select a pre-defined function from those listed in the [API](api.md). Second, you may define your own update functions as needed. 

### Customization 

There are three ways to customize your retirement investment simulation. From simplest to most complex, they are as follows:

1. You can select any combination of pre-defined update functions and modify their default parameter values.
2. You can define custom update functions to add new capabilities and have more fine-grained control over the behavior of the simulation.
3. You can create a new subtype of `AbstractModel`, which will allow you to extend the `update!` function. This will allow you to call a different set of functions than the seven update functions described above. 

Of course, these are not mutually exclusive approaches. You may use any combination of the three approaches to create your desired retirement investment simulation. 

## Installation

There are two methods for installing the package. Option 1 is to install without version control. In the REPL, use `]` to switch to the package mode and enter the following:

```julia
add https://github.com/itsdfish/RetirementPlanners.jl
```
Option 2 is to install via a custom registry. The advantage of this approach is greater version control through Julia's package management system. This entails two simple steps. 

1. Install the registry using the directions found [here](https://github.com/itsdfish/Registry.jl).
2. Add the package by typing `]` into the REPL and then typing (or pasting):

```julia
add RetirementPlanners
```
I recommend adding the package to a [project-specific environment](https://pkgdocs.julialang.org/v1/environments/) and specifying version constraints in the Project.toml to ensure reproducibility. For an example, see the [Project.toml](Project.toml) file associated with this package.  
