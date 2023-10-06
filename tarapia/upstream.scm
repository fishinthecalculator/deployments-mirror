(define-module (tarapia channels)
  #:use-module (guix channels))

(list (channel
       (name 'guix)
       (url "https://git.savannah.gnu.org/git/guix.git")
       (commit
        "d6a53849935f8584e1df57faa79c18c23fbb2aa1")
       (introduction
        (make-channel-introduction
         "afb9f2752315f131e4ddd44eba02eed403365085"
         (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
