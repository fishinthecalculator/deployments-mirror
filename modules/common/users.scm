(define-module (common users)
  #:use-module (gnu))

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
