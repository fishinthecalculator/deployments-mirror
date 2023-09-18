(define-module (config))

(use-modules (gnu) (nongnu packages linux) (nongnu packages firmware) (gnu bootloader u-boot) (srfi srfi-1))
(use-service-modules avahi networking ssh)
(use-package-modules admin bootloaders certs firmware linux ssh)

(define-public efraim-config
  (operating-system
    (host-name "armzalig")
    (timezone "Europe/Amsterdam")
    (locale "en_US.utf8")

    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (bootloader
     (bootloader-configuration
      (bootloader grub-efi-removable-bootloader)
      (targets '("/boot/efi"))
      (keyboard-layout keyboard-layout)))

    (file-systems (cons* (file-system (device (file-system-label "Guix_image"))
                                      (mount-point "/")
                                      (type "ext4"))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (file-system-label "GNU-ESP"))
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
    (kernel-arguments (append (remove (lambda (el) (string=? el "quiet")) %default-kernel-arguments)
                              (list "debug"
                                    "nosplash"
                                    "console=tty0"
                                    "cma=32M"
                                    "console=ttyS0,115200n8"
                                    "console=ttyAMA0,115200n8")))
    (firmware (list ath9k-htc-firmware linux-firmware))

    (users (cons* (user-account (name "paul")
                                (group "users")
                                (password (crypt "testino" "$6$abc"))
                                (supplementary-groups '("wheel" "audio" "video" "netdev" "plugdev")))
                  %base-user-accounts))
    (name-service-switch %mdns-host-lookup-nss)
    (packages (cons* nss-certs openssh wpa-supplicant-minimal %base-packages))
    (services (cons* (service dhcp-client-service-type)
		             (service agetty-service-type
                              (agetty-configuration
                               (extra-options '("-L")) ; no carrier detect
                               (baud-rate "1500000")
                               (term "vt100")
                               (tty "ttyS2")))
                     (service openssh-service-type
                              (openssh-configuration
                               (port-number 2222)))
                     %base-services))))

efraim-config
