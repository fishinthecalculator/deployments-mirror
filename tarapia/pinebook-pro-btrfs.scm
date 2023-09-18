
(define-module (tarapia pinebook-pro-btrfs))
(use-modules (gnu system images pinebook-pro)
	     (gnu system file-systems))

(use-modules (gnu) (gnu bootloader u-boot))
(use-service-modules avahi networking ssh)
(use-package-modules admin bootloaders certs firmware linux ssh)

(operating-system
  (inherit pinebook-pro-barebones-os)
  (file-systems (cons (file-system
                          (device (file-system-label "guix-root"))
                          (mount-point "/")
                          (type "btrfs"))
                        %base-file-systems)))
