(define-module (frastanato system input)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:export (%frastanato-kl
            %frastanato-touchpad
            %hid-apple-config))

(define %frastanato-kl
  (keyboard-layout "it" "nodeadkeys"))

;; See https://wiki.archlinux.org/index.php/Libinput#Via_Xorg_configuration_file
(define %frastanato-touchpad
  "Section \"InputClass\"
  Identifier \"touchpad catchall\"
  Driver \"libinput\"
  MatchIsTouchpad \"on\"
  Option \"Tapping\" \"on\"
  Option \"Natural Scrolling\" \"true\"
  EndSection")

(define %hid-apple-config
  (plain-file "hid_apple.conf"
              "options hid_apple fnmode=2 swap_opt_cmd=1"))
