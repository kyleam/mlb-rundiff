
(define-module (project-packages r)
  #:use-module (gnu packages cran)
  #:use-module (gnu packages haskell)
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

(define-public r-inline
  (package
    (name "r-inline")
    (version "0.3.14")
    (source
     (origin
       (method url-fetch)
       (uri (cran-uri "inline" version))
       (sha256
        (base32
         "0cf9vya9h4znwgp6s1nayqqmh6mwyw7jl0isk1nx4j2ijszxcd7x"))))
    (build-system r-build-system)
    (home-page
     "http://cran.r-project.org/web/packages/inline")
    (synopsis
     "Functions to inline C, C++, Fortran function calls from R")
    (description
     "Functionality to dynamically define R functions and S4 methods
with inlined C, C++ or Fortran code supporting .C and .Call calling
conventions.")
    (license license:lgpl3)))

(define-public r-stanheaders
  (package
    (name "r-stanheaders")
    (version "2.16.0-1")
    (source
     (origin
       (method url-fetch)
       (uri (cran-uri "StanHeaders" version))
       (sha256
        (base32
         "0i1gq32ys7iwgbdrwc86ww8kj5aqc7jbl663dynackb7wmqwlb7r"))))
    (properties `((upstream-name . "StanHeaders")))
    (build-system r-build-system)
    (home-page "http://mc-stan.org/")
    (synopsis "C++ header files for Stan")
    (description
     "Prvoides the C++ header files of the Stan project used by
@code{r-rstan}.")
    (license license:bsd-3)))

(define-public r-rstan
  (package
    (name "r-rstan")
    (version "2.16.2")
    (source
     (origin
       (method url-fetch)
       (uri (cran-uri "rstan" version))
       (sha256
        (base32
         "0irqh4ggk23s3c0ipihwv8m0qmkxh5j7vdxgnsarhqca6254r2vb"))))
    (build-system r-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-dates
           (lambda _
             (substitute* "R/zzz.R"
               (("value = Sys.time\\(\\)")
                "value = as.POSIXct(\"1970-1-1 00:00:00\", tz = \"UTC\")")
               ;; Prevent build failure for "character string is not
               ;; in a standard unambiguous format".
               (("as.POSIXct\\(\"1970-01-01 00:00.00 UTC\"\\)")
                "as.POSIXct(\"1970-1-1 00:00:00\", tz = \"UTC\")")))))))
    (propagated-inputs
     `(("r-bh" ,r-bh)
       ("r-ggplot2" ,r-ggplot2)
       ("r-gridextra" ,r-gridextra)
       ("r-inline" ,r-inline)
       ("r-rcpp" ,r-rcpp)
       ("r-rcppeigen" ,r-rcppeigen)
       ("r-stanheaders" ,r-stanheaders)))
    (home-page "http://mc-stan.org/users/interfaces/rstan.html")
    (synopsis "R interface to Stan")
    (description
     "User-facing R functions are provided to parse, compile, test,
estimate, and analyze Stan models by accessing the header-only Stan
library provided by @code{r-stanheaders}.  The Stan project develops a
probabilistic programming language that implements full Bayesian
statistical inference via Markov Chain Monte Carlo, rough Bayesian
inference via 'variational' approximation, and (optionally penalized)
maximum likelihood estimation via optimization.  In all three cases,
automatic differentiation is used to quickly and accurately evaluate
gradients without burdening the user with the need to derive the
partial derivatives.")
    (license license:gpl3+)))

(define-public r-bayesplot
  (package
    (name "r-bayesplot")
    (version "1.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (cran-uri "bayesplot" version))
       (sha256
        (base32
         "0n07ii605dskf0x9bms7krx1akjghb4bmq76zm39sc1lshyxinrr"))))
    (build-system r-build-system)
    (native-inputs
     `(("ghc-pandoc" ,ghc-pandoc)))
    (propagated-inputs
     `(("r-dplyr" ,r-dplyr)
       ("r-ggplot2" ,r-ggplot2)
       ("r-reshape2" ,r-reshape2)))
    (home-page "http://mc-stan.org/users/interfaces/bayesplot.html")
    (synopsis "Plotting for Bayesian Models")
    (description
     "Plotting functions for posterior analysis, model checking, and
MCMC diagnostics.  The package is designed not only to provide
convenient functionality for users, but also a common set of functions
that can be easily used by developers working on a variety of R
packages for Bayesian modeling, particularly (but not exclusively)
packages interfacing with 'Stan'.")
    (license license:gpl3+)))
