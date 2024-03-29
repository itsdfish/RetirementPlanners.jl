# Types 

## Abstact Types

The abstract types below can be extended to add new functionality.

```@docs 
AbstractGBM
AbstractModel
AbstractState
AbstractLogger
```

## Concrete Types

```@docs 
GBM
VarGBM
MvGBM
Model
State
Logger
```

# Methods 

## General Methods

```@docs
get_times
grid_search
is_event_time
rand
simulate!
update!
```

## Update Methods

### Update Income

```@docs
fixed_income
```

### Update Inflation

```@docs
fixed_inflation
variable_inflation
dynamic_inflation
```

### Update Interest

```@docs
fixed_interest
variable_interest
dynamic_interest
```

### Update Investments 

```@docs 
fixed_investment
variable_investment
```

### Log

```@docs
default_log!
```

### Update Net Worth

```@docs
default_net_worth
```
### Update Withdraw

```@docs 
adaptive_withdraw
fixed_withdraw
variable_withdraw
```
