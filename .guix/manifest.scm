(use-modules (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
      (list "snakemake"
            "wget")))
