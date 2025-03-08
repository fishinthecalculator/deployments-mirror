;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone system config)
  #:use-module (gnu)
  #:use-module (gnu system accounts)
  #:use-module (gnu packages databases)      ;for postgresql-13
  #:use-module (gnu packages geo)            ;for postgis
  #:use-module (gnu services certbot)        ;for certbot-service-type
  #:use-module (gnu services containers)     ;for rootless-podman-service-type
  #:use-module (gnu services dbus)           ;for dbus-service-type
  #:use-module (gnu services desktop)        ;for elogind-service-type
  #:use-module (gnu services networking)     ;for iptables-service-type
  #:use-module (gnu services security)       ;for fail2ban-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services web)            ;for nginx-service-type
  #:use-module (oci services containers)
  #:use-module (oci services forgejo)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common users)
  #:export (virtual-nellone-system))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %forgejo-port "3000")
(define %forgejo-ssh-port "2202")
(define %forgejo-domain "forgejo.fishinthecalculator.me")

(define subgids
  (list (subid-range (name (user-account-name paul-user)))))
(define subuids
  (list (subid-range (name (user-account-name paul-user)))))

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
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list
               (service dhcp-client-service-type)
               (service ntp-service-type)
               (service openssh-service-type
                        (openssh-configuration
                         (authorized-keys authorized-ssh-keys)
                         (permit-root-login #f)
                         (password-authentication? #f)
                         (x11-forwarding? #f)))

               (service fail2ban-service-type
                        (fail2ban-configuration
                         (extra-jails
                          (list
                           (fail2ban-jail-configuration
                            (name "sshd")
                            (enabled? #t))))))

              ;; The D-Bus clique.
              (service elogind-service-type)
              (service dbus-root-service-type)

              ;; Firewall
              (service iptables-service-type
                       (iptables-configuration
                        (ipv4-rules (plain-file "iptables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp --dport 2202 -j ACCEPT
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
-A INPUT -p tcp --dport 2202 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -j REJECT --reject-with icmp6-port-unreachable
COMMIT
"))))

              ;; rootless Podman
              (service rootless-podman-service-type
                       (rootless-podman-configuration
                        (subgids subgids)
                        (subuids subuids)))

              ;; OCI provisioning
              (service oci-service-type
                       (oci-configuration
                        (runtime 'podman)
                        (verbose? #t)))

              ;; Forgejo
              (service oci-forgejo-service-type
                       (oci-forgejo-configuration
                        (runtime 'podman)
                        (port %forgejo-port)
                        (ssh-port %forgejo-ssh-port)
                        (datadir
                         (oci-volume-configuration
                          (name "forgejo")))))

              ;; Certbot
              (service certbot-service-type
                       (certbot-configuration
                        (email "goodoldpaul@autistici.org")
                        (certificates
                         (list
                          (certificate-configuration
                           (domains (list %forgejo-domain)))))))

              ;; NGINX
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
                                               "proxy_set_header        X-Forwarded-Host  $host;")))))))))))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services %base-services
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
