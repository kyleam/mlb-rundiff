(use-modules (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
      (list "coreutils"
            "dos2unix"
            "python"
            "python-docopt"
            "python-pytest"
            "python-wrapper"
            "r"
            "r-devtools"
            "r-dplyr"
            "r-forcats"
            "r-ggplot2"
            "r-lubridate"
            "r-knitr"
            "r-readr"
            "r-rmarkdown"
            "r-tidyr"
            "sed"
            "snakemake"
            "unzip"
            "wget")))
