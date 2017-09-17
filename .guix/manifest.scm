(use-modules (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
      (list "coreutils"
            "dos2unix"
            "gawk"
            "python"
            "python-docopt"
            "python-pytest"
            "python-wrapper"
            "r"
            "r-bayesplot"
            "r-devtools"
            "r-dplyr"
            "r-forcats"
            "r-ggplot2"
            "r-hexbin"
            "r-knitr"
            "r-lubridate"
            "r-readr"
            "r-rmarkdown"
            "r-rstan"
            "r-testthat"
            "r-tidyr"
            "sed"
            "snakemake"
            "unzip"
            "wget")))
