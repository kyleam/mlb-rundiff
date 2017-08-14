
(define-module (project-packages r)
  #:use-module (gnu packages statistics)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system r)
  #:use-module ((guix licenses) #:prefix license:))

(define-public r-forcats
  (package
    (name "r-forcats")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (cran-uri "forcats" version))
       (sha256
        (base32
         "1mvwkynvvgz2vi8dyz11x7xrp53kadjawjcja34hwk1d89qf7g5m"))))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-magrittr" ,r-magrittr)
       ("r-tibble" ,r-tibble)))
    (home-page "http://forcats.tidyverse.org")
    (synopsis
     "Tools for working with factors")
    (description
     "Helpers for reordering factor levels (including moving specified
levels to front, ordering by first appearance, reversing, and randomly
shuffling), and tools for modifying factor levels (including
collapsing rare levels into other, 'anonymising', and manually
'recoding').")
    (license license:gpl3)))
