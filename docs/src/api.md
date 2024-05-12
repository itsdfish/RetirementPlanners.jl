# Types 

## Abstact Types

The abstract types below can be extended to add new functionality.

```@docs 
AbstractGBM
AbstractLogger
AbstractModel
AbstractState
AbstractTransaction
```

## Concrete Types

```@docs 
GBM
VarGBM
MvGBM
Model
State
Logger
Transaction
```

# Methods 

## General Methods

```@docs
get_times
grid_search
is_event_time
rand
simulate!
transact
update!
```

## Update Methods

### Update Income

```@docs
update_income!
```

### Update Inflation

```@docs
fixed_inflation
variable_inflation
dynamic_inflation
```

### Update Interest

```@docs
fixed_market
variable_market
dynamic_market
```

### Update Investments 

```@docs 
invest!
```

### Log

```@docs
default_log!
```

### Update Investments

```@docs
update_investments!
```
### Update Withdraw

```@docs 
withdraw!
```
