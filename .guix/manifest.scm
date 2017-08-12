(use-modules (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
      (list "coreutils"
            "dos2unix"
            "python"
            "python-docopt"
            "python-pytest"
            "python-wrapper"
            "snakemake"
            "unzip"
            "wget")))
