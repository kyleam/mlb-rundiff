[![Build Status](https://travis-ci.org/kyleam/mlb-rundiff.svg?branch=master)](https://travis-ci.org/kyleam/mlb-rundiff)

This repository contains

  * Stan code for modeling baseball run differentials

    See the [code/models] subdirectory and the [description][site] of
    the main model.

  * Python and R code for calculating a team's "jet lag" from
    Retrosheet game logs

    These scripts (try to) use the definition of jet lag from [this
    study][ssa].  See the [input/gamelogs] submodule and [code/lag]
    subdirectory, as well as [this page][lag-checks].

  * Source files for https://kyleam.github.io/mlb-rundiff

    See the [docs] subdirectory.


## Running the analyses

These analyses are intended to be run in a GNU/Linux environment.
This repository includes a [Dockerfile] that can be used to generate a
Docker container that builds on [jrnold/rstan] and includes all the
dependencies.

To build the container, run

```bash
$ docker build --tag mlb-rundiff .
```

Then, you can build any output file with [Snakemake].  For example,

```bash
$ docker run -it --rm -v $PWD/output:/opt/mlb-rundiff/output mlb-rundiff \
      output/lag/log-with-lags-cleaned.csv
```

will execute all the necessary steps to generate the lag dataset.

If you run the above command without a target, you will see a help
message that lists some possible targets of interest.

```bash
$ docker run -it --rm -v $PWD/output:/opt/mlb-rundiff/output mlb-rundiff
```

[Dockerfile]: https://github.com/kyleam/mlb-rundiff/tree/master/Dockerfile
[Snakemake]: http://snakemake.readthedocs.io/en/stable/
[code/models]: https://github.com/kyleam/mlb-rundiff/tree/master/code/models
[docs]: https://github.com/kyleam/mlb-rundiff/tree/master/docs
[input/gamelogs]: https://github.com/kyleam/retrosheet-gamelogs
[jrnold/rstan]: https://hub.docker.com/r/jrnold/rstan
[lag-checks]: https://kyleam.github.io/mlb-rundiff/lag-calculation-checks
[code/lag]: https://github.com/kyleam/mlb-rundiff/tree/master/code/lag
[site]: https://kyleam.github.io/mlb-rundiff
[ssa]: http://dx.doi.org/10.1073/pnas.1608847114
