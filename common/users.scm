(define-module (common users)
  #:use-module (gnu)
  #:use-module (gnu packages audio)          ;for bluez-alsa
  #:use-module (gnu packages linux)          ;for bluez
  #:use-module (gnu packages networking)     ;for blueman
  #:use-module (gnu services dbus)           ;for dbus-root-service-type
  #:use-module (gnu services desktop)        ;for gnome-service-type
  #:use-module (gnu services mcron)          ;for mcron-service-type
  #:use-module (gnu services networking)     ;for tor-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (gnu services xorg)           ;for set-xorg-configuration
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services mcron)
  #:use-module (small-guix services desktop)
  #:use-module (small-guix system desktop)
  #:use-module (small-guix system input)
  #:use-module (commons unattended-upgrades))

(define-public paul-user
  (user-account
    (name "paul")
    (uid 1000)
    (comment "Giacomo Leidi")
    (group "users")
    (home-directory "/home/paul")
    (supplementary-groups '("adbusers" ;for adb
                            "docker"
                            "lp" ;for accessing D-Bus for bluetooth
                            "libvirt"
                            "kvm"
                            "i2c"
                            "realtime"
                            "plugdev" ;for solaar
                            "wheel"
                            "netdev"
                            "audio"
                            "video"))))
;; Maybe one day
;;(shell #~(string-append #$oil "/bin/osh"))
