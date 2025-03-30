;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common home fishinthecalculator services sway)
  #:use-module (gnu)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages wm)
  #:use-module (gnu home services)
  #:use-module (gnu home services sway)
  #:use-module (guix gexp)
  #:use-module (fishinthecalculator common home fishinthecalculator packages)
  #:export (fishinthecalculator-sway-configuration))

(define fishinthecalculator-sway-configuration
  (sway-configuration
   (variables `((mod . "Mod4")         ; string
                (left . "h")         ; string
                (down . "j")         ; string
                (up . "k")         ; string
                (right . "l")         ; string
                (term                     ; file-append
                 . ,(file-append foot "/bin/foot"))
                (Term                     ; G-expression
                 . ,#~(string-append #$foot "/bin/foot"))))
   (keybindings
    `(;; Kill focused window
      ($mod+Shift+q . "kill")
      ;; Reload the configuration file
      ($mod+Shift+c . "reload")
      ;; Exit Sway
      ($mod+Shift+e . "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'")
      ;; Start your launcher
      ($mod+d . "exec $menu")
      ;; Start a terminal
      ($mod+Return . "exec $term")))
   (inputs
    (list
     ;; All keyboards use US layout by default
     (sway-input (identifier "type:keyboard")
                 (layout
                  (keyboard-layout "us")))
     (sway-input (identifier "1452:591:Keychron_K4_Keychron_K4")
                 (layout
                  (keyboard-layout "us"))
                 (extra-content '("xkb_rules evdev" "xkb_model pc105")))))
   (outputs
    (list
     (sway-output
      (identifier 'eDP-1)
      (resolution "1920x1080"))
     (sway-output
      (background
       #~(string-append "`" #$fishinthecalculator-scripts "/bin/wallpaper`")))))
   (bar
    (sway-bar
     (position 'top)
     (colors
      (sway-color
       (statusline "#ffffff")
       (background "#323232")
       (inactive-workspace
        (sway-border-color
         (border "#32323200")
         (background "#32323200")
         (text "#5c5c5c")))))

     (status-command
      #~(string-append "while "
                       #$coreutils "/bin/date"
                       " +'%Y-%m-%d %X'; do sleep 1; done"))))

   (extra-content
    '("    # Drag floating windows by holding down $mod and left mouse button.
    # Resize them with right mouse button + $mod.
    # Despite the name, also works for non-floating windows.
    # Change normal to inverse to use left mouse button for resizing and right
    # mouse button for dragging.
    floating_modifier $mod normal

# Moving around:
#
    # Move your focus around
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    # Or use $mod+[up|down|left|right]
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # Move the focused window with the same, but add Shift
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    # Ditto, with arrow keys
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right
#
# Workspaces:
#
    # Switch to workspace
    bindsym $mod+1 workspace 1
    bindsym $mod+2 workspace 2
    bindsym $mod+3 workspace 3
    bindsym $mod+4 workspace 4
    bindsym $mod+5 workspace 5
    bindsym $mod+6 workspace 6
    bindsym $mod+7 workspace 7
    bindsym $mod+8 workspace 8
    bindsym $mod+9 workspace 9
    bindsym $mod+0 workspace 10
    # Move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace 1
    bindsym $mod+Shift+2 move container to workspace 2
    bindsym $mod+Shift+3 move container to workspace 3
    bindsym $mod+Shift+4 move container to workspace 4
    bindsym $mod+Shift+5 move container to workspace 5
    bindsym $mod+Shift+6 move container to workspace 6
    bindsym $mod+Shift+7 move container to workspace 7
    bindsym $mod+Shift+8 move container to workspace 8
    bindsym $mod+Shift+9 move container to workspace 9
    bindsym $mod+Shift+0 move container to workspace 10
    # Note: workspaces can have any name you want, not just numbers.
    # We just use 1-10 as the default.
#
# Layout stuff:
#
    # You can \"split\" the current object of your focus with
    # $mod+b or $mod+v, for horizontal and vertical splits
    # respectively.
    bindsym $mod+b splith
    bindsym $mod+v splitv

    # Switch the current container between different layout styles
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    # Make the current focus fullscreen
    bindsym $mod+f fullscreen

    # Toggle the current focus between tiling and floating mode
    bindsym $mod+Shift+space floating toggle

    # Swap focus between the tiling area and the floating area
    bindsym $mod+space focus mode_toggle

    # Move focus to the parent container
    bindsym $mod+a focus parent
#
# Scratchpad:
#
    # Sway has a \"scratchpad\", which is a bag of holding for windows.
    # You can send windows there and get them back later.

    # Move the currently focused window to the scratchpad
    bindsym $mod+Shift+minus move scratchpad

    # Show the next scratchpad window or hide the focused scratchpad window.
    # If there are multiple scratchpad windows, this command cycles through them.
    bindsym $mod+minus scratchpad show

#
# Custom keybindings
#
    bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
    bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%

    bindsym XF86MonBrightnessDown exec light -U 5
    bindsym XF86MonBrightnessUp exec light -A 5
    bindsym --release Print exec grim -g \"$(slurp)\" $(xdg-user-dir PICTURES)/$(date +'%Y-%m-%d_%H:%M:%S_grim.png')

# Mako
exec mako --max-visible 6 --default-timeout 5000

# Intellij workaround
exec wmname LG3D

# App themes
exec_always sway-gtk-settings

# Root dialogs
exec /run/current-system/profile/libexec/polkit-gnome-authentication-agent-1

# Start Guix home
exec bash -l echo ciao

exec dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
"))))
