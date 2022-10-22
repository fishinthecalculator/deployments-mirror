(define-module (frastanato system fs)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:export (%frastanato-mapped-devices
            %frastanato-file-systems
            %frastanato-swap-devices))

(define %frastanato-mapped-devices
  (list (mapped-device
         (source
          (uuid "08639dcb-12e1-4e44-a9eb-00d2efce6120"))
         (target "cryptlabel")
         (type luks-device-mapping))))

(define %frastanato-file-systems
  (cons* (file-system
           (mount-point "/")
           (device "/dev/mapper/cryptlabel")
           (type "btrfs")
           (dependencies %frastanato-mapped-devices))
         (file-system
           (device "/dev/mapper/cryptlabel")
           (mount-point "/home")
           (type "btrfs")
           (options "subvol=@home")
           (dependencies %frastanato-mapped-devices))
         (file-system
           (mount-point "/boot/efi")
           (device (uuid "B394-841F" 'fat32))
           (type "vfat"))
         %base-file-systems))

(define %frastanato-swap-devices
  (list
   (swap-space
    (target "/dev/sda2"))))
