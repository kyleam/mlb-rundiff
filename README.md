[![Build Status](https://travis-ci.org/kyleam/mlb-rundiff.svg?branch=master)](https://travis-ci.org/kyleam/mlb-rundiff)

This repository contains

  * Stan code for modeling baseball run differentials

    See the [code/models] subdirectory and the [description][site] of
    the main model.

  * Python and R code for calculating a team's "jet lag" from
    Retrosheet game logs

    These scripts (try to) use the definition of jet lag from [this
    study][ssa].  See the [inputs/gamelogs] submodule and [code/lag]
    subdirectory, as well as [this page][lag-checks].

  * Source files for https://kyleam.github.io/mlb-rundiff

    See the [docs] subdirectory.


## Running the analyses

### Input data

The lag values are calculated using Retrosheet's game logs.  These are
available in the [inputs/gamelogs] submodule, which you can download
with

```bash
git submodule update --init inputs/gamelogs
```

### Singularity container

All the dependencies for running these analyses are available in the
[Singularity] container defined [here][garps].  If you have
Singularity installed on your system, you can pull the image with the
following command:

```bash
$ singularity pull --name snakemake.simg shub://kyleam/garps
```

The name "snakemake.simg" was chosen because the Singularity
container's runscript is set to `snakemake`, but you can of course use
whatever naming scheme you'd like.

### Building output files with Snakemake

All output files can be built with [Snakemake], and, as mentioned
above, the container runs `snakemake` by default.  To generate an
output file, pass it as an argument to the image.

As an example,

```bash
$ ./snakemake.simg outputs/lag/log-with-lags-cleaned.csv
```

will execute all the necessary steps to generate the lag dataset.

If you want to execute this in a more isolated environment, you can
instead use something like

```bash
$ singularity run -c -e -B $PWD:/mnt/scratch --pwd /mnt/scratch \
  snakemake.simg outputs/lag/log-with-lags-cleaned.csv
```

If you run the container without a target, you will see a help message
that lists some possible targets of interest.

```bash
$ ./snakemake.simg
```

[Singularity]: http://singularity.lbl.gov/
[Snakemake]: http://snakemake.readthedocs.io/en/stable/
[code/models]: https://github.com/kyleam/mlb-rundiff/tree/master/code/models
[docs]: https://github.com/kyleam/mlb-rundiff/tree/master/docs
[garps]: https://github.com/kyleam/garps/tree/master/Singularity
[inputs/gamelogs]: https://github.com/kyleam/retrosheet-gamelogs
[lag-checks]: https://kyleam.github.io/mlb-rundiff/lag-calculation-checks
[code/lag]: https://github.com/kyleam/mlb-rundiff/tree/master/code/lag
[site]: https://kyleam.github.io/mlb-rundiff
[ssa]: http://dx.doi.org/10.1073/pnas.1608847114
