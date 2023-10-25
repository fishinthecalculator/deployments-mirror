# Guix Deployments

This repository hosts a Guix Channel. It mostly contains and some (opinionated) `operative-system` definitions.

## Configure

To configure Guix for using this channel you need to create a `.config/guix/channels.scm` file with the following content:

``` scheme
(cons* (channel
        (name 'deployments)
        (url "https://gitlab.com/orang3/guix-deployments")
        (branch "main")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "1feaa92d3ff8ac1745c619454e38b6a7bfe605d4"
          (openpgp-fingerprint
           "D088 4467 87F7 CBB2 AE08  BE6D D075 F59A 4805 49C3"))))
       %default-channels)
```

Otherwise, if you already have a `.config/guix/channels.scm` you can simply prepend this channel to the preexisting ones:

``` scheme
(cons* (channel
        (name 'deployments)
        (url "https://gitlab.com/orang3/guix-deployments")
        (branch "main")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "1feaa92d3ff8ac1745c619454e38b6a7bfe605d4"
          (openpgp-fingerprint
           "D088 4467 87F7 CBB2 AE08  BE6D D075 F59A 4805 49C3"))))
       (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
          (openpgp-fingerprint
           "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
       %default-channels)
```

## License

Unless otherwise stated all the files in this repository are to be considered under the GPL 3.0 terms. You are more than welcome to open issues or send patches.
