(define-module (tarapia system libre))
(use-modules (gnu)
             (gnu packages bootloaders)
             (gnu system images pinebook-pro))

(operating-system
  (inherit pinebook-pro-barebones-os)
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))
  (file-systems
   (cons* (file-system
            (device (file-system-label "Guix_image"))
            (mount-point "/")
            (type "ext4"))
          (file-system
            (mount-point "/boot/efi")
            (device (file-system-label "GNU-ESP"))
            (type "vfat"))
          %base-file-systems))
  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-removable-bootloader)
    (targets '("/boot/efi"))
    (keyboard-layout keyboard-layout))))
