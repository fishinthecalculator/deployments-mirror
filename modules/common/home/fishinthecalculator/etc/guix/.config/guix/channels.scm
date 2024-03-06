(use-modules (guix channels)
             (guix ci))

(list (channel-with-substitutes-available
       %default-guix-channel
       "https://ci.guix.gnu.org")
      (channel
       (name 'guix-gaming-games)
       (url "https://gitlab.com/guix-gaming-channels/games.git")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "c23d64f1b8cc086659f8781b27ab6c7314c5cca5"
         (openpgp-fingerprint
          "50F3 3E2E 5B0C 3D90 0424  ABE8 9BDC F497 A4BB CC7F"))))
      ;; (channel
      ;;  (name 'guixrus)
      ;;  (url "https://git.sr.ht/~whereiseveryone/guixrus")
      ;;  (introduction
      ;;   (make-channel-introduction
      ;;    "7c67c3a9f299517bfc4ce8235628657898dd26b2"
      ;;    (openpgp-fingerprint
      ;;     "CD2D 5EAA A98C CB37 DA91  D6B0 5F58 1664 7F8B E551"))))
      (channel
       (name 'nonguix)
       (url "https://gitlab.com/nonguix/nonguix")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
         (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
        (name 'suse-utils)
        (url "https://github.com/gleidi-suse/suse-utils.git")
        (branch "main")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "d4a947eb5b4a73f2a467e67569f7aaf3aafc1aa2"
          (openpgp-fingerprint
           "97A2 CB8F B066 F894 9928  CF80 DE9B E0AC E824 6F08"))))
      (channel
       (name 'pot)
       (url "https://github.com/fishinthecalculator/pot.git")
       (branch "main")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "10ed759852825149eb4b08c9b75777111a92048e"
         (openpgp-fingerprint
          "97A2 CB8F B066 F894 9928  CF80 DE9B E0AC E824 6F08"))))
      (channel
       (name 'small-guix)
       (url "https://gitlab.com/orang3/small-guix")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "f260da13666cd41ae3202270784e61e062a3999c"
         (openpgp-fingerprint
          "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
      (channel
       (name 'sops-guix)
       (url "https://git.sr.ht/~fishinthecalculator/sops-guix")
       (branch "main")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "0bbaf1fdd25266c7df790f65640aaa01e6d2dbc9"
         (openpgp-fingerprint
          "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
      (channel
       (name 'deployments)
       (url "https://gitlab.com/orang3/guix-deployments.git")
       (branch "main")
       ;; Enable signature verification:
       (introduction
        (make-channel-introduction
         "9d101a2b1f38571e75e7d256bbc8d754177d11f3"
         (openpgp-fingerprint
          "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
      ;; tailscale
      (channel
       (name 'benwr)
       (url "https://github.com/benwr/benwr_guix.git")
       (branch "main"))
      ;; mobilizon reshare
      (channel
       (name 'mobilizon-reshare)
       (url "https://git.sr.ht/~fishinthecalculator/mobilizon-reshare-guix")
       (branch "main")))
