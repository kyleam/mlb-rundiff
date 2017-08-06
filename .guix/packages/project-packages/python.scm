
(define-module (project-packages python)
  #:use-module (gnu packages python)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system python))

(define-public project-snakemake
  (package
    (inherit snakemake)
    (name "snakemake")
    (version "4.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "snakemake" version))
       (sha256
        (base32 "0jcq9njmzsxj40b1n163hjwlh9mf51cn6ysbh8pqh4bvq5pyj9z0"))))))
