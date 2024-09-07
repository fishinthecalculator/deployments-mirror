(define-module (fishinthecalculator common home fishinthecalculator const)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public %home-scripts-dir
  (local-file (string-append (current-source-directory) "/bin") "scripts-dir"
              #:recursive? #t))
