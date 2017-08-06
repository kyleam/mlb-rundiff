(use-modules (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
      (list "coreutils"
            "dos2unix"
            "snakemake"
            "unzip"
            "wget")))
