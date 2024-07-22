(define-module (gnu packages hyprland)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system qt)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages assembly)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages file)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages fribidi)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages profiling)
  #:use-module (gnu packages python)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages selinux)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages web)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))

(define-public hyprland
  (package
    (name "hyprland")
    (version "0.45.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/Hyprland")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0970kds3744szlqlbjq6m4a689dndb2yrcgyxpzrw9ig84sibnqh"))))
    (build-system meson-build-system)
    (arguments
     (list
      #:tests? #f ; No tests.
      #:configure-flags #~(list "-Dxwayland=enabled"
                                "-Dsystemd=disabled"
                                ;; "-Dtracy_enable=true"
                                "-Db_pch=false")
      #:phases
      #~(let ((binutils #$binutils)) ; Adding binutils to inputs would override
                                     ; ld-wrapper.
          (modify-phases %standard-phases
            (add-after 'unpack 'patch-paths
              (lambda* (#:key inputs #:allow-other-keys)
                (substitute* (find-files "src" "\\.cpp")
                  (("/usr/local(/bin/Hyprland)" _ path)
                   (string-append #$output path))
                  (("(execAndGet\\(\")lspci" _ pre)
                   (string-append pre (search-input-file inputs "bin/lspci")))
                  ;; TODO Not sure what this is about, copied it from rakino's
                  ;; hyprland package (also the gcc input). Might be defunct.
                  ;; (("\\<cc\\>") (search-input-file inputs "bin/gcc"))
                  )
                (substitute* '("src/signal-safe.hpp"
                               "src/xwayland/Server.cpp"
                               "src/managers/KeybindManager.cpp")
                  (("/bin/sh") (search-input-file inputs "bin/sh")))
                (substitute* "src/render/OpenGL.cpp"
                  (("/usr") #$output))
                (substitute* '("src/Compositor.cpp"
                               "src/config/ConfigManager.cpp")
                  (("dbus-update-activation-environment")
                   (search-input-file
                    inputs "bin/dbus-update-activation-environment")))
                (substitute* "src/xwayland/Server.cpp"
                  (("(std::format\\(\")Xwayland" _ pre)
                   (string-append pre (search-input-file
                                       inputs "/bin/Xwayland"))))
                (substitute* "src/debug/CrashReporter.cpp"
                  (("(writeCmdOutput\\(\")lspci" _ pre)
                   (string-append pre (search-input-file inputs "bin/lspci")))
                  (("\\<addr2line\\>")
                   (string-append binutils "/bin/addr2line")))
                (substitute* "src/plugins/PluginAPI.cpp"
                  (("(execAndGet\\(\\(\")nm" _ pre)
                   (string-append pre binutils "/bin/nm")))
                (substitute* "hyprpm/src/core/PluginManager.cpp"
                  (("/usr/local") #$output)
                  (("(execAndGet\\(\")hyprctl" _ pre)
                   (string-append pre #$output "/bin/hyprctl"))
                  (("\\<pkgconf\\>")
                   (search-input-file inputs "bin/pkgconf")))))))))
    (native-inputs
     (list gcc-14
           hyprwayland-scanner
           pkg-config))
    (inputs
     (list aquamarine
           bash-minimal ; For patching various '/bin/sh' references.
           cairo
           ;; gcc ; TODO see above. Also will need to be "gcc-14" if keeping.
           dbus ; For patching 'dbus-update-activation-environment'.
           git-minimal
           hyprcursor
           hyprland-protocols
           hyprlang
           hyprutils
           libdrm
           ;; ;; TODO Having libglvnd this causes a crash on launch (at least on version 0.43.0). Hyprland seems fine without it but it's inconsistent with the rest of the hypr ecosystem (perhaps most relevantly aquamarine). Also having all these libglvnds is inconsistent with Guix in general. I'm not sure what to do. Maybe report the issue upstream if I decide to keep the libglvnds.
           ;; ;; The error, for reference:
           ;; ;; [LOG] Creating the CHyprOpenGLImpl!
           ;; ;; [LOG] Supported EGL extensions: (0)
           ;; ;; [CRITICAL] [Tracy GPU Profiling] eglGetProcAddress(eglCreateImageKHR) failed
           ;; libglvnd
           libinput-minimal
           libxcursor
           libxkbcommon
           mesa
           pango
           pciutils
           pkgconf ; For patching 'pkgconf'.
           tomlplusplus
           ;; tracy
           udis86
           `(,util-linux "lib") ; For libuuid.
           wayland
           wayland-protocols
           ;; For Xwayland.
           libxcb
           libxdmcp
           xcb-util-errors
           xcb-util-renderutil
           xcb-util-wm
           xorg-server-xwayland))
    (home-page "https://hyprland.org")
    (synopsis "Dynamic tiling Wayland compositor that doesn't sacrifice on
its looks")
    (description
     "Hyprland is an independent, highly customizable, dynamic tiling Wayland
compositor that doesn't sacrifice on its looks. It provides the latest Wayland
features, is highly customizable, has all the eyecandy, the most powerful
plugins, easy IPC, much more QoL stuff than other compositors and more.")
    (license license:bsd-3)))

(define-public aquamarine
  (package
    (name "aquamarine")
    (version "0.5.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/aquamarine")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0rvf0vizm1x7w16nkinac7qh9lijxkyswsywksingfrw5k56ng6l"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; No tests (technically one but I think its just for dev purposes).
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-path
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "CMakeLists.txt"
                (("/bin/sh") (search-input-file inputs "bin/sh")))))
          ;; TODO See note in hyprland libglvnd.
          ;; (add-after 'unpack 'dont-use-glvnd
          ;;   (lambda _
          ;;     (substitute* "CMakeLists.txt"
          ;;       (("OpenGL::OpenGL") "OpenGL::GL"))))
          )))
    (native-inputs
     (list hyprwayland-scanner
           pkg-config))
    (inputs
     (list hwdata
           hyprutils
           libdisplay-info
           libdrm
           libffi
           libglvnd
           libinput-minimal
           libseat
           mesa
           pixman
           eudev
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/aquamarine")
    (synopsis "A very light linux rendering backend library")
    (description
     "Aquamarine is a very light linux rendering backend library. It provides
basic abstractions for an application to render on a Wayland session (in a
window) or a native DRM session.")
    (license license:bsd-3)))

(define-public xdg-desktop-portal-hyprland
  (package
    (name "xdg-desktop-portal-hyprland")
    (version "1.3.8")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/xdg-desktop-portal-hyprland")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0aixrjyky2mzclnwypybpg01ihfbmwzfv09zbjis49q1clrszq2p"))))
    (build-system qt-build-system)
    (arguments
     (list
      #:tests? #f ; No tests.
      #:qtbase qtbase
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-references
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* (find-files "." "\\.cp?*$")
                (("/bin/sh")
                 (search-input-file inputs "bin/sh"))
                (("\\<(sh|grim|hyprctl|hyprpicker|slurp)\\>" _ cmd)
                 (search-input-file inputs (string-append "bin/" cmd))))))
          (add-after 'unpack 'patch-share-picker-reference
            (lambda _
              (substitute* (find-files "." "\\.cp?*$")
                (("\\<(hyprland-share-picker)\\>" _ cmd)
                 (string-append #$output "/bin/" cmd))))))))
    (native-inputs
     (list pkg-config
           hyprwayland-scanner))
    (inputs
     (list hyprland-protocols
           hyprlang
           hyprutils
           libdrm
           mesa
           pipewire
           qtbase
           qttools
           qtwayland
           sdbus-c++-2
           wayland
           wayland-protocols
           ;; For referenced programs.
           bash-minimal
           hyprland
           hyprpicker
           grim
           slurp))
    (home-page "https://github.com/hyprwm/xdg-desktop-portal-hyprland")
    (synopsis "XDG Desktop Portal backend for Hyprland")
    (description
     "This package provides @code{xdg-desktop-portal-hyprland}, which extends
@code{xdg-desktop-portal-wlr} for Hyprland with support for
@code{xdg-desktop-portal} screenshot and casting interfaces, while adding a few
extra portals specific to Hyprland, mostly for window sharing.")
    (license license:bsd-3)))

;; XDPH includes its own fancy, QT-based share-picker (possibly other apps in
;; the future). This variant eschews that for a simpler, slurp-based option.
;; TODO: Replace the promptForScreencopySelection in
;; src/shared/ScreencopyShared.cpp with "slurp -f %o -or -c ff0000".
(define-public xdg-desktop-portal-hyprland/simple
  (let ((base xdg-desktop-portal-hyprland))
    (package
      (inherit base)
      (name "xdg-desktop-portal-hyprland-simple")
      (build-system cmake-build-system)
      (arguments
       (substitute-keyword-arguments (strip-keyword-arguments
                                      '(#:qtbase)
                                      (package-arguments base))
         ((#:phases phases #~%standard-phases)
          #~(modify-phases #$phases
              (add-after 'unpack 'dont-build-share-picker
                (lambda _
                  (substitute* "CMakeLists.txt"
                    (("add_subdirectory\\(hyprland-share-picker\\)") "")
                    (("install\\(TARGETS hyprland-share-picker\\)") ""))))
              (delete 'patch-share-picker-reference)))))
      (inputs
       (modify-inputs (package-inputs base)
         (delete "qtbase"
                 "qttools"
                 "qtwayland"))))))

(define-public hyprlock
  (package
    (name "hyprlock")
    (version "0.5.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprlock")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "07404h6w5934yimpwb0p9dxg1w3nv702bckm4m99jbjrda6jqhmi"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list pkg-config
           wayland)) ; For wayland-scanner.
    (inputs
     (list cairo
           file
           libdrm
           libglvnd
           libjpeg-turbo
           libwebp
           libxkbcommon
           mesa
           hyprlang
           hyprutils
           linux-pam
           pango
           sdbus-c++-2
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/hyprlock")
    (synopsis "Hyprland's GPU-accelerated screen locking utility")
    (description
     "Uses the secure ext-session-lock protocol, full support for
fractional-scale, fully GPU accelerated, with multi-threaded resource
acquisition for no hitches.")
    (license license:bsd-3)))

(define-public hypridle
  (package
    (name "hypridle")
    (version "0.1.5")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hypridle")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1622iz8bl8mi7gj2sc2jq6z7622l7l2izj1l9ajwj2mxpwpkdhbs"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list pkg-config
           wayland)) ; For wayland-scanner.
    (inputs
     (list hyprlang
           hyprutils
           sdbus-c++-2
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/hypridle")
    (synopsis "Hyprland's idle daemon")
    (description
     "Based on the ext-idle-notify-v1 wayland protocol. Support for dbus'
loginctl commands (lock / unlock / before-sleep) and for dbus' inhibit (used
by e.g. firefox / steam).")
    (license license:bsd-3)))

(define-public hyprpaper
  (package
    (name "hyprpaper")
    (version "0.7.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprpaper")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "10yb2853fd0ljxijwkqm146bnirzpghfc5kw080ws24hjmfbp0hw"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f ; No tests.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-commit-hash
            (lambda _
              (substitute* "src/main.cpp"
                (("GIT_COMMIT_HASH") (string-append "\"" #$version "\""))))))))
    (native-inputs
     (list pkg-config
           hyprwayland-scanner))
    (inputs
     ;; Some of these probably shouldn't be explicitly listed here as they're
     ;; required only as dependendencies of other items on this list that already
     ;; propagate them, but figuring out which is which is tedious and it's way
     ;; more convenient to just copy the upstream-provided list.
     (list cairo
           expat
           file
           fribidi
           hyprlang
           hyprutils
           libdatrie
           libglvnd
           libjpeg-turbo
           libselinux
           libsepol
           libthai
           libwebp
           libxdmcp
           pango
           pcre
           pcre2
           wayland
           wayland-protocols
           util-linux))
    (home-page "https://github.com/hyprwm/hyprpaper")
    (synopsis "A blazing fast wayland wallpaper utility with IPC controls")
    (description
     "A blazing fast wallpaper utility for Hyprland with the ability to
dynamically change wallpapers through sockets. It will work on all
wlroots-based compositors, though.")
    (license license:bsd-3)))

(define-public hyprpicker
  (package
    (name "hyprpicker")
    (version "0.4.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprpicker")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "11r06c62dqj81r27qhf36f3smnjyk3vz8naa655m8khv4qqvmvc2"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f ; No tests.
      #:configure-flags
      #~(list (string-append "-DCMAKE_INSTALL_MANDIR=" #$output "/share/man"))))
    (native-inputs
     (list hyprwayland-scanner
           pkg-config))
    ;; Some of these probably shouldn't be explicitly listed here as they're
    ;; required only as dependendencies of other items on this list that already
    ;; propagate them, but figuring out which is which is tedious and it's way
    ;; more convenient to just copy the upstream-provided list.
    (inputs
     (list cairo
           fribidi
           hyprutils
           libdatrie
           libglvnd
           libjpeg-turbo
           libselinux
           libsepol
           libthai
           libxdmcp
           libxkbcommon
           pango
           pcre
           pcre2
           util-linux
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/hyprpicker")
    (synopsis "A wlroots-compatible Wayland color picker that does not suck")
    (description "Launch it. Click. That's it.")
    (license license:bsd-3)))

(define-public hyprsunset
  (package
    (name "hyprsunset")
    (version "0.1.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprsunset")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "110cw7nd6a0krsg6764hx2i45lc8n4b1iln3b8jz1x6pziw1qna9"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list hyprwayland-scanner
           pkg-config))
    (inputs
     (list hyprland-protocols
           hyprutils
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/hyprsunset")
    (synopsis "An application to enable a blue-light filter on Hyprland")
    (description
     "An application to enable a blue-light filter on Hyprland.")
    (license license:bsd-3)))

(define-public hyprwayland-scanner
  (package
    (name "hyprwayland-scanner")
    (version "0.4.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprwayland-scanner")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0r7ay4zjkfyr0xd73wz99qhnqjq7nma98gm51wm9lmai4igw90qw"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list pkg-config))
    (inputs
     (list pugixml))
    (home-page "https://github.com/hyprwm/hyprwayland-scanner")
    (synopsis "A Hyprland version of wayland-scanner in and for C++")
    (description
     "This package provides a Hyprland implementation of wayland-scanner, in
and for C++.")
    (license license:bsd-3)))

(define-public hyprland-protocols
  (package
    (name "hyprland-protocols")
    (version "0.4.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprland-protocols")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0x86w7z3415qvixfhk9a8v5fnbnxdydzx366qz0mpmfg5h86qyha"))))
    (build-system meson-build-system)
    (home-page "https://github.com/hyprwm/hyprland-protocols")
    (synopsis "Wayland protocol extensions for Hyprland")
    (description
     "This package provides Wayland protocol extensions for Hyprland and it
exists in an effort to bridge the gap between Hyprland and KDE/Gnome's
functionality.  Since @code{wlr-protocols} is closed for new submissions, and
@code{wayland-protocols} is very slow with changes, this package will hold
protocols used by Hyprland to bridge the aforementioned gap.")
    (license license:bsd-3)))

(define-public hyprcursor
  (package
    (name "hyprcursor")
    (version "0.1.10")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprcursor")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1rdn03ln7pqcwp8h4nmi7nc489q8y25dd3v4paq8ykvwzhvs3a1n"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; No build tests, only installed ones. They also require a cursor theme
      ;; to be available.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-runtime-dependency-path
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "hyprcursor-util/src/main.cpp"
                (("xcur2png") (search-input-file inputs "bin/xcur2png"))))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list cairo
           hyprlang
           librsvg
           libzip
           tomlplusplus
           xcur2png))
    (home-page "https://github.com/hyprwm/hyprcursor")
    (synopsis "Hyprland cursor format, library and utilities")
    (description
     "An efficient cursor theme format that doesn't suck as much as XCursor.")
    (license license:bsd-3)))

(define-public hyprlang
  (package
    (name "hyprlang")
    (version "0.5.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprlang")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0yvfrz3hdyxzhngzhr0bgc5279ra5fv01hbfi6pdj84pz0lpaw02"))))
    (build-system cmake-build-system)
    (native-inputs
     (list pkg-config))
    (inputs
     (list hyprutils))
    (home-page "https://github.com/hyprwm/hyprlang")
    (synopsis "Official implementation the for hypr config language")
    (description
     "This package provides the official implementation for hypr configuration
language used in @code{hyprland}.")
    (license license:gpl3+)))

(define-public hyprutils
  (package
    (name "hyprutils")
    (version "0.2.6")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprutils")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0scrfky9hkzhbyj5aji6qvi4b6ydf4g7sk0cknkpd7dg0zv8x5zq"))))
    (build-system cmake-build-system)
    (native-inputs
     (list pkg-config))
    (inputs
     (list pixman))
    (home-page "https://github.com/hyprwm/hyprutils")
    (synopsis "Small C++ library for utilities used across the Hypr* ecosystem")
    (description
     "Hyprland utilities library used across the ecosystem.")
    (license license:bsd-3)))
