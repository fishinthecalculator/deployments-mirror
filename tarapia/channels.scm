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
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
       (name 'nonguix)
       (url "https://gitlab.com/nonguix/nonguix")
       (commit "bb184bd0a8f91beec3a00718759e96c7828853de")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
         (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))
