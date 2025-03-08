;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone system config)
  #:use-module (gnu)
  #:use-module (gnu system accounts)
  #:use-module (gnu packages databases)      ;for postgresql-13
  #:use-module (gnu packages geo)            ;for postgis
  #:use-module (gnu services certbot)        ;for certbot-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services linux)          ;for kernel-module-loader-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for iptables-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services web)            ;for nginx-service-type
  #:use-module (sops services sops)
  #:use-module (oci services containers)
  #:use-module (oci services forgejo)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common scripts)
  #:use-module (fishinthecalculator common secrets)
  #:use-module (fishinthecalculator common services server)
  #:use-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator virtual-nellone system secrets)
  #:export (virtual-nellone-system
            virtual-nellone-common-server-services))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %forgejo-port "3000")
(define %forgejo-domain "forgejo.fishinthecalculator.me")

(define subgids
  (list (subid-range (name (user-account-name paul-user)))))
(define subuids
  (list (subid-range (name (user-account-name paul-user)))))
(define virtual-nellone-common-server-services
  (common-server-services subuids subgids))
(define virtual-nellone-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "virtual-nellone")

    ;; The list of user accounts ('root' is implicit).
    (users (cons* (user-account
                   (inherit paul-user)
                   (comment "Tino il Cotechino")
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "cgroup")))
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
                           '("ncurses"
                             "gnupg"
                             "lsof"
                             "jq"
                             "ncdu"
                             "tree"
                             "curl"
                             "git"
                             "tmux"
                             "vim"
                             "tcpdump"
                             "net-tools"
                             "ripgrep"))
                      (list common-deploy-scripts)
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list
              (service certbot-service-type
                       (certbot-configuration
                        (email "goodoldpaul@autistici.org")
                        (certificates
                         (list
                          (certificate-configuration
                           (domains (list %forgejo-domain)))))))

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)))

              (service oci-forgejo-service-type
                       (oci-forgejo-configuration
                        (runtime 'podman)
                        (port %forgejo-port)
                        (datadir
                         (oci-volume-configuration
                          (name "forgejo")))))

              (service oci-service-type
                       (oci-configuration
                        (runtime 'podman)
                        (verbose? #t)))

              (service nginx-service-type
                       (nginx-configuration
                        ;; Wait for forgejo to start
                        (shepherd-requirement
                         '(podman-forgejo))
                        (server-blocks
                         (list (nginx-server-configuration
                                (server-name (list %forgejo-domain))
                                (listen '("443 ssl"))
                                (ssl-certificate (string-append "/etc/certs/" %forgejo-domain "/fullchain.pem"))
                                (ssl-certificate-key (string-append "/etc/certs/" %forgejo-domain "/privkey.pem"))
                                (locations
                                 (list
                                  (nginx-location-configuration
                                   (uri "/")
                                   (body (list (string-append "proxy_pass http://localhost:" %forgejo-port ";")
                                               ;; Taken from https://www.nginx.com/resources/wiki/start/topics/examples/full/
                                               ;; Those settings are used when proxies are involved
                                               "proxy_redirect          off;"
                                               "proxy_set_header        Host $host;"
                                               "proxy_set_header        X-Real-IP $remote_addr;"
                                               "proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;"
                                               "proxy_http_version      1.1;"
                                               "proxy_cache_bypass      $http_upgrade;"
                                               "proxy_set_header        Upgrade $http_upgrade;"
                                               "proxy_set_header        Connection \"upgrade\";"
                                               "proxy_set_header        X-Forwarded-Proto $scheme;"
                                               "proxy_set_header        X-Forwarded-Host  $host;"))))))))))

              ;; Misc
              (service common-unload-service-type
                       '("nginx" "podman-forgejo"))

              (deployments-unattended-upgrades host-name
                                               #:expiration-days 30))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services virtual-nellone-common-server-services
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
-A INPUT -i lo -j ACCEPT
-A INPUT -j REJECT --reject-with icmp6-port-unreachable
COMMIT
"))))

               (openssh-service-type ssh-config =>
                                     (openssh-configuration (inherit ssh-config)
                                                            (authorized-keys
                                                             (append
                                                              (openssh-configuration-authorized-keys ssh-config)
                                                              authorized-ssh-keys))))
               (guix-service-type guix-config =>
                                  (guix-configuration (inherit guix-config)
                                                      (authorized-keys
                                                       (append
                                                        (guix-configuration-authorized-keys guix-config)
                                                        authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                 (bootloader grub-bootloader)
                 (targets (list "/dev/vda"))
                 (keyboard-layout keyboard-layout)))

    (swap-devices (list (swap-space
                          (target (uuid
                                   "97f21590-e3ae-43c6-b637-648a5aa3bfde")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "373ba527-a118-4df9-8759-50918ace4703"
                                    'ext4))
                           (type "ext4")) %base-file-systems))))
