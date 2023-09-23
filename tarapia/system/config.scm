(define-module (tarapia system config))

(use-modules (gnu) (nongnu packages linux) (nongnu packages firmware) (gnu bootloader u-boot)  (gnu system images pinebook-pro) (srfi srfi-1))

(use-service-modules avahi desktop networking ssh)
(use-package-modules admin bootloaders certs firmware linux ssh)

(define %root-fs-label
  "guix-root")

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
         "console=ttyAMA0,115200n8")))

(define-public tarapia-system
  (operating-system
    (host-name "tarapia")
    (timezone "Europe/Rome")
    (locale "en_US.utf8")

    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (bootloader
     (bootloader-configuration
      (bootloader grub-efi-removable-bootloader)
      (targets '("/boot/efi"))
      (keyboard-layout keyboard-layout)))

    (file-systems (cons* (file-system (device (file-system-label %root-fs-label))
                                      (mount-point "/")
                                      (type "ext4"))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (file-system-label %esp-fs-label))
                           (type "vfat"))
                         %base-file-systems))

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
  (operating-system
    (inherit tarapia-system)
    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (bootloader (bootloader-configuration
                 (bootloader u-boot-pinebook-pro-rk3399-bootloader)
                 (targets '("/dev/vda"))))
    (file-systems (cons* (file-system (device (file-system-label %root-fs-label))
                                      (mount-point "/")
                                      (type "ext4"))
                         %base-file-systems))))

(define-public tarapia-pinebook-pro-libre
  (operating-system
    (inherit pinebook-pro-barebones-os)
    (host-name "tarapia")
    (timezone "Europe/Rome")
    (locale "en_US.utf8")
    (kernel-arguments %verbose-boot-kernel-arguments)
    (file-systems (cons (file-system
                          (device (file-system-label %root-fs-label))
                          (mount-point "/")
                          (type "ext4"))
                        %base-file-systems))))

(define-public tarapia-pinebook-pro-corrupted
  (operating-system
    (inherit tarapia-pinebook-pro-libre)
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
    (firmware (list ath9k-htc-firmware ap6256-firmware linux-firmware))))

tarapia-system
