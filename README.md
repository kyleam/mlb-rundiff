
This repository contains

  * Stan code for modeling baseball run differentials

    See the [models] subdirectory and the [description][site] of the
    main model.

  * Python and R code for calculating a team's "jet lag" from
    Retrosheet game logs

    These scripts (try to) use the definition of jet lag from [this
    study][ssa].  See the [gamelogs] and [lag] subdirectories, as well
    as [this page][lag-checks].

  * Source files for https://kyleam.github.io/mlb-rundiff

    See the [rmd] subdirectory.


## Building output files

All output files can be built with [Snakemake].  For example,

    $ snakemake lag/log-with-lags-cleaned.csv

will execute all the necessary steps, including the download of game
logs from retrosheet.org, to generate the lag data files.


## Dependencies

These analyses depend on the following software.  The version numbers
indicate the versions used.  In most cases, other versions should
work.

_            | _
:---         | :---
**Python**   | 3.5.3
docopt       | 0.6.2
pytest       | 3.0.7
**R**        | 3.4.1
bayesplot    | 1.3.0
devtools     | 1.13.3
directlabels | 2017.03.31
dplyr        | 0.7.3
forcats      | 0.2.0
ggplot2      | 2.2.1
hexbin       | 1.27.1-1
knitr        | 1.17
lubridate    | 1.6.0
readr        | 1.1.1
rmarkdown    | 1.6
rstan        | 2.16.2
testthat     | 1.0.2
tidyr        | 0.7.1
**Other**    |
coreutils    | 8.27
dos2unix     | 7.3.4
gawk         | 4.1.4
sed          | 4.4
snakemake    | 4.0.0
unzip        | 6.0
wget         | 1.19.1

### Guix

[Guix] is not a dependency.  You can safely ignore the ".guix"
subdirectory and the "guix-*" files.

If you do happen to use Guix, you can use the manifest file in the
".guix" subdirectory to install all the above dependencies.  The
repository contains various wrappers around Guix commands
(guix-update, guix-snakemake, ...) to make it easier to run these
analyses with an isolated profile.


[Guix]: https://www.gnu.org/software/guix/
[Snakemake]: http://snakemake.readthedocs.io/en/stable/
[gamelogs]: https://github.com/kyleam/mlb-rundiff/tree/master/lag
[lag-checks]: https://kyleam.github.io/mlb-rundiff/lag-calculation-checks
[lag]: https://github.com/kyleam/mlb-rundiff/tree/master/lag
[models]: https://github.com/kyleam/mlb-rundiff/tree/master/models
[rmd]: https://github.com/kyleam/mlb-rundiff/tree/master/rmd
[site]: https://kyleam.github.io/mlb-rundiff
[ssa]: http://dx.doi.org/10.1073/pnas.1608847114
