## Overview

This package provides a flexible framework for performing Monte Carlo simulations of retirement investment performance under various assumptions specifed by the user. A major goal of the framework is to allow the user to customize the details of the simulation. 

## How does it work?

RetirementPlanners.jl performs a discrete time simulation in which a fuction `update!` is called on each time step. By default, `update!` calls seven subordinate functions, which must be defined by the user:

1. `withdraw!`: withdraw money
2. `invest!`: invest money
3. `update_income!`: update sources of income, such as social security, pension etc. 
4. `update_inflation!`: compute inflation
5. `update_interest!`: compute interest 
6. `update_net_worth!`: compute net worth 
7. `log!`: log desired variables

Two arguments are passed to each update function above: (1) a model object, and (2) an optional set of keyword arguments. By default, the model object contains a state object, which tracks quantities, such as the interest (growth) rate, the inflation rate, and net worth on the current time step. In addition, the model object contains a dictionary of user defined events, which define the onset of changes in the behavior of the simulation (such as when retirement begins). 

### Customization 

The package provides many opportunities to customize the simulation. First, each of the six update functions must be specified by the user. Because the functions are arguments in the simulation, you may iterate through numerous functions to stress test your investment plan under alternative assumptions. Second, you can create a new `Model` type and extent the `update!` function so that a different set of update functions are called. 

### Batteries Included

Future iterations of the package will include a variety of common update functions. These functions will be useful for performing simple simulations. 

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