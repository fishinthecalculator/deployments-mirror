;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024-2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator frastanato system config)
  #:use-module (gnu)
  #:use-module (gnu system accounts)
  #:use-module (gnu packages admin) ;for shadow
  #:use-module (gnu packages databases)      ;for postgresql-13
  #:use-module ((gnu services backup)        ;for restic-backup-service-type
                #:prefix mainline:)
  #:use-module (gnu services cuirass)        ;for transmission-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services file-sharing)   ;for transmission-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for network-manager-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (gnu services vpn)            ;for wireguard-service-type
  #:use-module (sops secrets)
  #:use-module ((sops services databases) #:prefix sops:)
  #:use-module (sops services sops)
  #:use-module (oci services containers)
  #:use-module (oci services grafana)
  #:use-module (oci services prometheus)
  #:use-module (oci services tandoor)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages nvidia) ;for nvidia-module
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix packages scripts) ;for restic-bin
  #:use-module (small-guix packages rclone) ;for rclone-bin
  #:use-module (small-guix services backup-timers) ;for restic-backup-service-type
  #:use-module (fishinthecalculator common backup)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common secrets)
  #:use-module (fishinthecalculator common self)
  #:use-module (fishinthecalculator common services server)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator frastanato secrets)
  #:use-module (srfi srfi-1)
  #:export (frastanato-system))

(define-public backup-system-jobs
  (map (lambda (repo)
         (mainline:restic-backup-job
          (name (list-ref (string-split repo #\:) 1))
          (restic restic-bin)
          (repository repo)
          (password-file "/run/secrets/restic")
          ;; Every day at 6.
          (schedule "0 6 * * *")
          (files '("/root/.config/rclone"
                   "/root/.config/sops/age/keys.txt"
                   "/etc/ssh/ssh_host_rsa_key"
                   "/etc/ssh/ssh_host_rsa_key.pub"
                   "/etc/guix/signing-key.pub"
                   "/etc/guix/signing-key.sec"))
          (verbose? #t)))
       %restic-repositories))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %cuirass-period
  (* 24 (* 60 60)))

(define %cuirass-specs
  #~(list
     (specification
      (name "bonfire")
      (build '(channels bonfire-guix))
      (channels
       (cons (channel
              (name 'bonfire-guix)
              (url "https://github.com/fishinthecalculator/bonfire-guix.git")
              (branch "main")
              ;; Enable signature verification:
              (introduction
               (make-channel-introduction
                "2cc6f76adafb6333f0ec3e5fe4835fa0f0d9a0ff"
                (openpgp-fingerprint
                 "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
             %default-channels)))
     (specification
      (name "concierge")
      (build '(channels concierge))
      (channels
       (cons (channel
              (name 'concierge)
              (url "https://codeberg.org/fishinthecalculator/concierge.git")
              (branch "main")
              ;; Enable signature verification:
              (introduction
               (make-channel-introduction
                "b95d48ace0a9fe4098b2372952ecc7458655a6aa"
                (openpgp-fingerprint
                 "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
             %default-channels)))
     (specification
      (name "deployments")
      (period #$%cuirass-period)
      (build '(custom (fishinthecalculator ci)))
      (channels
       (append
        (list
         (channel
          (name 'deployments)
          (url "https://codeberg.org/fishinthecalculator/guix-deployments.git")
          (branch "main")
          ;; Enable signature verification:
          (introduction
           (make-channel-introduction
            "9d101a2b1f38571e75e7d256bbc8d754177d11f3"
            (openpgp-fingerprint
             "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2")))))
        %default-channels)))
     (specification
      (name "mobilizon-reshare")
      (period #$%cuirass-period)
      (build '(packages
               "mobilizon-reshare"
               "mobilizon-reshare@0.3.6"
               "mobilizon-reshare@0.3.5"
               "mobilizon-reshare@0.3.2"
               "mobilizon-reshare@0.3.1"
               "mobilizon-reshare@0.3.0"
               "mobilizon-reshare@0.1.0"))
      (channels
       (cons (channel
              (name 'mobilizon-reshare)
              (url "https://codeberg.org/fishinthecalculator/mobilizon-reshare-guix.git")
              (branch "main"))
             %default-channels)))
     (specification
      (name "ocui")
      (period #$%cuirass-period)
      (build '(packages "ocui.git"))
      (channels
       (cons (channel
              (name 'ocui)
              (url "https://github.com/fishinthecalculator/ocui.git")
              (branch "main")
              ;; Enable signature verification:
              (introduction
               (make-channel-introduction
                "10ed759852825149eb4b08c9b75777111a92048e"
                (openpgp-fingerprint
                 "97A2 CB8F B066 F894 9928  CF80 DE9B E0AC E824 6F08"))))
             %default-channels)))))

(define subgids
  (list (subid-range (name (user-account-name paul-user)))))
(define subuids
  (list (subid-range (name (user-account-name paul-user)))))
(define %common-server-services
  (common-server-services subuids subgids))
(define frastanato-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "frastanato")

    (kernel linux)
    (initrd (lambda (file-systems . rest)
              (apply microcode-initrd
                     file-systems
                     #:initrd base-initrd
                     #:microcode-packages (list intel-microcode)
                     #:keyboard-layout keyboard-layout
                     #:linux-modules %base-initrd-modules
                     rest)))
    (firmware (cons* realtek-firmware atheros-firmware %base-firmware))

    ;; The list of user accounts ('root' is implicit).
    (users (cons* (user-account
                   (inherit paul-user)
                   (comment "Tino il Cotechino")
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "cgroup" "transmission")))
                  (user-account
                   (name "deploy")
                   (comment "Guix deploy user")
                   (group "users")
                   (supplementary-groups '("tty"))
                   (system? #t))
                  %base-user-accounts))

    (sudoers-file
     (plain-file "sudoers"
                 (string-append
                  (plain-file-content %sudoers-specification)
                  "\n deploy ALL=(ALL) NOPASSWD: ALL\n")))

    ;; Packages installed system-wide.  Users can also install packages
    ;; under their own account: use 'guix search KEYWORD' to search
    ;; for packages and 'guix install PACKAGE' to install a package.
    (packages (append (map specification->package+output
                           '("btrfs-progs"
                             "compsize"))
                      (list rclone-bin)
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list
              ;; Cuirass
              (service cuirass-service-type
                       (cuirass-configuration
                        (host "0.0.0.0")
                        (port 8081)
                        (specifications %cuirass-specs)))

              ;; Serve Guix substitutes over LAN.
              (service guix-publish-service-type
                       (guix-publish-configuration
                        (port 65535)
                        (host "0.0.0.0")
                        (advertise? #t)))

              ;; Backups
              (service restic-backup-service-type
                       (restic-backup-configuration
                        (jobs backup-system-jobs)))

              ;; File sharing
              (service transmission-daemon-service-type
                       (transmission-daemon-configuration
                        ;; mkdir -pv /torrents-watchdir
                        ;; chown -Rv paul:users /torrents-watchdir
                        ;; chmod -v o+r /torrents-watchdir
                        (watch-dir-enabled? #t)
                        (watch-dir "/torrents-watchdir")
                        (peer-port 16383)

                        ;; Accept requests from this and other hosts on the
                        ;; local network
                        (rpc-whitelist-enabled? #t)
                        (rpc-whitelist '("::1" "127.0.0.1" "192.168.1.*"))

                        ;; Limit bandwidth use during work hours
                        (alt-speed-down (* 1024 2)) ;   2 MB/s
                        (alt-speed-up 512)          ; 512 kB/s

                        (alt-speed-time-enabled? #t)
                        (alt-speed-time-day 'weekdays)
                        (alt-speed-time-begin
                         (+ (* 60 8) 00)) ; 8:00 am
                        (alt-speed-time-end
                         (+ (* 60 (+ 12 5)) 00)))) ; 5:00 pm

              ;; Monitoring
              (service prometheus-node-exporter-service-type)

              (service oci-prometheus-service-type
                       (oci-prometheus-configuration
                        (image "prom/prometheus:v2.45.0")
                        (network "host")
                        (datadir
                         (oci-volume-configuration
                          (name "prometheus")))
                        (record
                         (prometheus-configuration
                          (global
                           (prometheus-global-configuration
                            (scrape-interval "30s")
                            (scrape-timeout "12s")))
                          (scrape-configs
                           (list
                            (prometheus-scrape-configuration
                             (job-name "prometheus")
                             (static-configs
                              (list (prometheus-static-configuration
                                     (targets '("localhost:9090"))))))
                            (prometheus-scrape-configuration
                             (job-name "node")
                             (static-configs
                              (list (prometheus-static-configuration
                                     (targets '("localhost:9100"))))))))))))

              (service oci-tandoor-service-type
                       (oci-tandoor-configuration
                        (runtime 'podman)
                        (port "8081")
                        (postgres-password
                         tandoor-postgres-password-secret)
                        (secret-key
                         tandoor-secret-key-secret)))

              (service oci-grafana-service-type
                       (oci-grafana-configuration
                        (runtime 'podman)
                        (image "docker.io/bitnami/grafana:11.5.3")
                        (network "host")
                        (port "3000")
                        (datadir
                         (oci-volume-configuration
                          (name "grafana")))))

              (service postgresql-service-type
                       (postgresql-configuration
                        (postgresql postgresql-13)))

              (service oci-service-type
                       (oci-configuration
                        (runtime 'podman)
                        (verbose? #t)))

              ;; Misc
              (service common-unload-service-type
                       '("containerd"
                         "cuirass"
                         "dockerd"
                         "postgres"
                         "podman-grafana"))

              (service network-manager-service-type)
              (service wpa-supplicant-service-type)

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)
                        (secrets
                         (list restic-secret
                               wireguard-secret))))

              (deployments-unattended-upgrades host-name
                                               #:hours 4
                                               #:minutes 27
                                               #:expiration-days 30)

              (service qemu-binfmt-service-type
                       (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                              "arm"
                                                              "aarch64")))))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services %common-server-services
               (delete dhcp-client-service-type)
               (iptables-service-type iptables-config =>
                                      (iptables-configuration
                                       (ipv4-rules (plain-file "iptables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp --dport 16383 -j ACCEPT
-A INPUT -p tcp -s 192.168.0.0/16 -j ACCEPT
-A INPUT -p udp -s 192.168.0.0/16 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
"))
                                       (ipv6-rules (plain-file "ip6tables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -s fc00::/7 -j ACCEPT
-A INPUT -p udp -s fc00::/7 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -j REJECT --reject-with icmp6-port-unreachable
COMMIT
"))))
               (openssh-service-type ssh-config =>
                                     (openssh-configuration (inherit ssh-config)
                                                            (authorized-keys (append
                                                                              (openssh-configuration-authorized-keys ssh-config)
                                                                              authorized-ssh-keys))))
               (guix-service-type guix-config =>
                                  (guix-configuration (inherit guix-config)
                                                      (discover? #t)
                                                      (authorized-keys (append
                                                                        (guix-configuration-authorized-keys guix-config)
                                                                        authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout keyboard-layout)))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "4d3ff686-809a-454d-8744-17f4ecd2adab"
                                    'btrfs))
                           (type "btrfs"))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "EB17-1A0F"
                                         'fat32))
                           (type "vfat")) %base-file-systems))

    (swap-devices
     (list
      (swap-space
       ;; See https://wiki.archlinux.org/title/Btrfs#Swap_file
       ;; for swapfile on Btrfs
       (target "/swap/swapfile")
       (dependencies (filter (file-system-mount-point-predicate "/")
                             file-systems)))))))
