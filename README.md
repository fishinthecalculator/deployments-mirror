# Guix Deployments

This repository hosts a Guix Channel. It contains some (opinionated) `operative-system` definitions for my systems.

## Configure

To configure Guix for using this channel you need to create a `.config/guix/channels.scm` file with the following content:

``` scheme
(cons* (channel
        (name 'deployments)
        (url "https://codeberg.org/fishinthecalculator/guix-deployments.git")
        (branch "main")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "9d101a2b1f38571e75e7d256bbc8d754177d11f3"
          (openpgp-fingerprint
           "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
       %default-channels)
```

Otherwise, if you already have a `.config/guix/channels.scm` you can simply prepend this channel to the preexisting ones:

``` scheme
(cons* (channel
        (name 'deployments)
        (url "https://codeberg.org/fishinthecalculator/guix-deployments.git")
        (branch "main")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "9d101a2b1f38571e75e7d256bbc8d754177d11f3"
          (openpgp-fingerprint
           "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
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

## Installation image

To build an installation image preconfigured with this channel you can use:

``` shell
guix system image -L `pwd`/modules --image-type=iso9660 modules/common/system/install.scm
```

Please note that this command must be run from the root of the repository.

## Git authentication hooks

```shell
guix git authenticate --cache-key=channels/deployments 9d101a2b1f38571e75e7d256bbc8d754177d11f3 '8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2'
```

## License

Unless otherwise stated all the files in this repository are to be considered under the GPL 3.0 terms. You are more than welcome to open issues or send patches.
