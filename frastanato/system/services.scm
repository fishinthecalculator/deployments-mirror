(define-module (frastanato system services)
  #:use-module (gnu)
  #:use-module (gnu packages base)        ;for glibc, coreutils
  #:use-module (gnu packages compression) ;for zlib
  #:use-module (gnu services networking)  ;for tor
  #:use-module (gnu services sddm)
  #:use-module (frastanato system input)
  #:use-module (small-guix services desktop)
  #:export (%frastanato-desktop-services
            %frastanato-xorg-configuration))

(use-service-modules pm
                     sound
                     ssh
                     virtualization
                     xorg)

(define %frastanato-xorg-configuration
  (xorg-configuration
   (keyboard-layout %frastanato-kl)
   (extra-config
    (list %frastanato-touchpad))))

(define %frastanato-desktop-services
  (append
   (list (service openssh-service-type
                  (openssh-configuration
                   (password-authentication? #t)))

         (service tor-service-type)
         ;; Power management
         (service tlp-service-type
             (tlp-configuration
                  (cpu-scaling-governor-on-ac (list "performance"))
                  (sched-powersave-on-bat? #t)))

             ;; Slight FHS compatibility
         (extra-special-file "/lib64/ld-linux-x86-64.so.2"
                             (file-append glibc "/lib/ld-linux-x86-64.so.2"))
         (extra-special-file "/usr/lib/libz.so.1"
                             (file-append zlib "/lib/libz.so.1")))
   (modify-services %small-guix-desktop-services
            (sddm-service-type config =>
                                   (sddm-configuration
                                    (inherit config)
                                    (xorg-configuration
                                     %frastanato-xorg-configuration))))))
