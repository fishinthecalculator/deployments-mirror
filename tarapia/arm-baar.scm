
(define-module (tarapia arm-baar))
(use-modules (gnu) (gnu bootloader u-boot))
(use-service-modules avahi networking ssh)
(use-package-modules admin bootloaders certs firmware linux ssh)

(operating-system
  (host-name "armzalig")
  (timezone "Europe/Amsterdam")
  (locale "en_US.utf8")

  ;; Assuming not using a typewriter that needs qwerty slowdown
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))

  ;; Assuming /dev/mmcblk0 is the microSD...
  (bootloader (bootloader-configuration
               (targets '("/dev/nvme0n1"))
	     ;;   (menu-entries
		 ;; (list (menu-entry
		 ;;     (device "Guix_image")
         ;;     (initrd "/boot/test")
         ;;     (linux (file-append linux-libre-arm64-generic "/bin/Image"))
		 ;;     (label "Guix Labeled"))))
	     ;;   (default-entry 1)
	       (keyboard-layout keyboard-layout)
               (bootloader u-boot-pinebook-pro-rk3399-bootloader)))
  ;; ...and after booting, /dev/mmcblk1p1 is the root file system
  (file-systems (cons* (file-system (device (file-system-label "Guix_image"))
                                    (mount-point "/")
                                    (type "ext4"))
		       (file-system
                         (mount-point "/boot/efi")
                         (device (file-system-label "GNU-ESP"))
                         (type "vfat"))
                       %base-file-systems))

  (initrd-modules (list "nvme"))
  (kernel linux-libre-arm64-generic)
  (firmware (list ath9k-htc-firmware))

  (users (cons* (user-account (name "paul")
                              (group "users")
                              (password (crypt "testino" "$6$abc"))
                              (supplementary-groups '("wheel" "audio" "video")))
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
                   %base-services)))
