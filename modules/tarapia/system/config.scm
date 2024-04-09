(define-module (tarapia system config))

(use-modules (gnu) (nongnu packages linux) (nongnu packages firmware) (gnu bootloader u-boot)  (gnu system images pinebook-pro) (srfi srfi-1))

(use-service-modules avahi desktop networking ssh)
(use-package-modules admin bootloaders certs firmware linux ssh)

(define %root-fs-label
  "Guix_image")

(define %esp-fs-label
  "GNU-ESP")

(define %verbose-boot-kernel-arguments
  (append
   (remove (lambda (el) (string=? el "quiet")) %default-kernel-arguments)
   (list "debug"
         "nosplash"
         "console=tty0"
         "loglevel=7"
         "console=ttyS0,115200n8"
         "console=ttyAMA0,115200n8"
         "video=eDP-1:1920x1080@60"
         "video=HDMI-A-1:1920x1080@60")))

(define (make-boot-variant config bootloader file-systems)
  (operating-system
    (inherit config)
    (bootloader bootloader)
    (kernel-arguments %verbose-boot-kernel-arguments)
    (file-systems file-systems)))

(define %efi-file-systems
  (cons* (file-system
           (mount-point "/")
           (device (file-system-label %root-fs-label))
           (type "ext4"))
         (file-system
           (mount-point "/boot/efi")
           (device (file-system-label %esp-fs-label))
           (type "vfat"))
         %base-file-systems))

(define %efi-bootloader
  (bootloader-configuration
   (bootloader grub-efi-removable-bootloader)
   (targets '("/boot/efi"))
   (keyboard-layout (keyboard-layout "us" "altgr-intl"))))

(define (make-efi-system config)
  (make-boot-variant config %efi-bootloader %efi-file-systems))

(define %uboot-file-systems
  (cons* (file-system (device (file-system-label %root-fs-label))
                      (mount-point "/")
                      (type "ext4"))
         %base-file-systems))

(define %uboot-bootloader
  (bootloader-configuration
   (bootloader u-boot-pinebook-pro-rk3399-bootloader)
   (targets '("/dev/vda"))))

(define (make-uboot-system config)
  (make-boot-variant config %uboot-bootloader %uboot-file-systems))

(define-public tarapia-system
  (operating-system
    (host-name "tarapia")
    (timezone "Europe/Rome")
    (locale "en_US.utf8")

    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (bootloader %efi-bootloader)

    (file-systems %efi-file-systems)

    (initrd-modules (list "nvme"
                          "pcie_rockchip_host"
                          "phy_rockchip_pcie"

                          ;; Rockchip modules
                          "rockchip_rga"
                          ;;"rockchip_saradc"
                          "rockchip_thermal"
                          "rockchipdrm"

                          ;; GPU/Display modules
                          "analogix_dp"
                          "cec"
                          "drm"
                          "drm_kms_helper"
                          "dw_hdmi"
                          "dw_mipi_dsi"
                          "gpu_sched"
                          "panel_edp"
                          "panel_simple"
                          "panfrost"
                          "pwm_bl"

                          ;; USB / Type-C related modules
                          "fusb302"
                          "tcpm"
                          "typec"

                          ;; Misc. modules
                          "cw2015_battery"
                          "gpio_charger"
                          "rtc_rk808"))
    (kernel linux-arm64-generic)
    (kernel-arguments %verbose-boot-kernel-arguments)
    (firmware (list ath9k-htc-firmware ap6256-firmware linux-firmware))

    (users (cons* (user-account (name "paul")
                                (group "users")
                                (password (crypt "testino" "$6$abc"))
                                (supplementary-groups '("wheel" "audio" "video" "netdev"))) ;; "plugdev"

                  %base-user-accounts))
    (name-service-switch %mdns-host-lookup-nss)
    (packages (cons* nss-certs openssh wpa-supplicant-minimal %base-packages))
    (services (cons* (service openssh-service-type
                              (openssh-configuration
                               (port-number 2222)))
                     %desktop-services))))

(define-public tarapia-one-partition-system
  (make-uboot-system tarapia-system))

(define-public tarapia-pinebook-pro-libre-efi
  (make-efi-system pinebook-pro-barebones-os))

(define-public tarapia-pinebook-pro-corrupted
  (let ((ancestor (make-uboot-system pinebook-pro-barebones-os)))
    (operating-system
      (inherit ancestor)
      (initrd-modules (list "nvme"
                            "pcie_rockchip_host"
                            "phy_rockchip_pcie"

                            ;; Rockchip modules
                            "rockchip_rga"
                            ;;"rockchip_saradc"
                            "rockchip_thermal"
                            "rockchipdrm"

                            ;; GPU/Display modules
                            "analogix_dp"
                            "cec"
                            "drm"
                            "drm_kms_helper"
                            "dw_hdmi"
                            "dw_mipi_dsi"
                            "gpu_sched"
                            "panel_edp"
                            "panel_simple"
                            "panfrost"
                            "pwm_bl"

                            ;; USB / Type-C related modules
                            "fusb302"
                            "tcpm"
                            "typec"

                            ;; Misc. modules
                            "cw2015_battery"
                            "gpio_charger"
                            "rtc_rk808"))
      (kernel linux-arm64-generic)
      (firmware (list ath9k-htc-firmware ap6256-firmware linux-firmware)))))

(define-public tarapia-pinebook-pro-corrupted-efi
  (make-efi-system tarapia-pinebook-pro-corrupted))

tarapia-system
