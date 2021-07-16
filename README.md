This is an package of Julia SNN implementations.

## How to use this package in another Julia project for SNN experiments

We may want to simultaneously develop this package and also the project of SNN experiments. You can follow the steps:
 1. clone this repo.
 2. make a new julia project (exp_proj here) for the experiments.
 3. In exp_proj package management: `add Revise` and `dev path_to_local_sinkingjl`
 4. Write codes with `Using SinKing` in exp_proj.
 4. In exp_proj: `using Revise` then `using exp_proj`

Then modifications in SinKing.jl and also exp_proj should automatically apply.


## License

Licensed under the Apache License, Version 2.0
