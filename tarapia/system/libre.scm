(use-modules (gnu) (nongnu packages linux) (nongnu packages firmware) (gnu bootloader u-boot)  (gnu system images pinebook-pro) (srfi srfi-1))

(use-service-modules avahi desktop networking ssh)
(use-package-modules admin bootloaders certs firmware linux ssh)

(operating-system
  (inherit pinebook-pro-barebones-os)
  (file-systems
   (cons* (file-system (device "/dev/nvme0n1")
                       (mount-point "/")
                       (type "ext4"))
          %base-file-systems))
  (initrd-modules (list "nvme"))
  (bootloader
   (bootloader-configuration
    (bootloader u-boot-pinebook-pro-rk3399-bootloader)
    (targets '("/dev/nvme0n1")))))
