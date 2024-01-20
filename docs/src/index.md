## Overview

`RetirementPlanners.jl` is a framework for performing Monte Carlo simulations of retirement investment performance under various assumptions specifed by the user. The primary goal of the framework is to provide a high degree of flexibility and customization while offering a set of user-friendly options from which users can choose. This goal is achieved as follows:

1. The package allows the user to tweak the investment simulations by selecting from a set of pre-defined update functions which have modifiable parameters.
2. The package allows the user to define custom update functions which integrate seamlessly with the API. 

## How does it work?

`RetirementPlanners.jl` performs a discrete time simulation, meaning the state of the system is updated at fixed time steps—typically, representing years or months. On each time step, the `update!` is called, and updates the system in a manner defined by the user. By default, `update!` calls seven subordinate functions, which must be defined by the user:

1. `withdraw!`: withdraw money
2. `invest!`: invest money
3. `update_income!`: update sources of income, such as social security, pension etc. 
4. `update_inflation!`: compute inflation
5. `update_interest!`: compute interest 
6. `update_net_worth!`: compute net worth 
7. `log!`: log desired variables

The [API](api.md) describes pre-defined update functions from which you can choose. In addition, you may define your own update functions as needed. 

### Customization 

There are three ways to customize your retirement investment simulation. From simplest to most complex, they are as follows:

1. You can select any combination of pre-defined update functions and modify their default parameter values.
2. You can define custom update functions to add new capabilities and have more fine-grained control over
    the behavior of the simulation.
3. You can create a new subtype of `AbstractModel`, which will allow you to extend the `update!` function. This will allow you to call a different set of functions than the seven update functions described above. 

Of course, these are not mutually exclusive approaches. You may use any combination of the three approaches to create your desired retirement investment simulation. 

## Installation

There are two methods for installing the package. Option 1 is to install without version control. In the REPL, use `]` to switch to the package mode and enter the following:

```julia
add https://github.com/itsdfish/RetirementPlanners.jl
```
Option 2 is to install via a custom registry. The advantage of this approach is that you have more control over version control, expecially if you are using a project-specfic environment. 

1. Install the registry using the directions found [here](https://github.com/itsdfish/Registry.jl).
2. Add the package by typing `]` into the REPL and then typing (or pasting):

```julia
add RetirementPlanners
```