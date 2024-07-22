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

;; TODO Temporary, hopefully gcc 14 will be the default in my guix fork soon.
(define gcc-for-hypr-ecosystem gcc-14)

(define %hyprland-commit "0f594732b063a90d44df8c5d402d658f27471dfe")
(define-public hyprland
  (package
    (name "hyprland")
    ;; (version "0.43.0")
    (version (git-version "0.43.0" "0" %hyprland-commit))
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/Hyprland")
                    ;; (commit (string-append "v" version))
                    (commit %hyprland-commit)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                ;; "1m4994103sg8c919aj7q4k2rj4rjd635vg9f0qrzb19pmsfybzy5"
                "1m4994103sg8c919aj7q4k2rj4rjd635vg9f0qrzb19pmsfybzy5"))
              ;; Not sure this is necessary but it (probably) can't hurt.
              (patches
               (list
                (origin
                  (method url-fetch)
                  (uri (string-append
                        "https://raw.githubusercontent.com/hyprwm/Hyprland/"
                        ;; (string-append "v" version)
                        %hyprland-commit
                        "/nix/stdcxx.patch"))
                  (file-name (string-append name "-c++-26-fix.patch"))
                  (sha256
                   (base32
                    "1fmqws4k5qg1rk13frii05h78v7ni5a1c3x1kba2y39f4858ww0f")))))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f ; No tests.
      #:configure-flags #~(list "-DNO_SYSTEMD=ON")
      #:phases
      #~(let ;; Additional inputs.
             ;; We can't add put them in the inputs fields because:
             ;; - origins are difficult / not possible to reference without also
             ;;   using input labels
             ;; - adding binutils to inputs would override ld-wrapper
            ((hyprland-protocols-src #$(package-source hyprland-protocols))
             (tracy-src #$(package-source tracy))
             (udis86-src  #$(package-source udis86))
             (binutils #$binutils))
          (modify-phases %standard-phases
            (add-after 'unpack 'add-subprojects
              (lambda _
                (with-directory-excursion "subprojects"
                  (for-each
                   (lambda (src+dir)
                     (apply copy-recursively src+dir))
                   `((,hyprland-protocols-src "hyprland-protocols")
                     (,tracy-src "tracy")
                     (,udis86-src "udis86"))))))
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
     (list gcc-for-hypr-ecosystem
           hyprwayland-scanner
           jq
           ninja
           pkg-config
           python-minimal-wrapper ; For udis86.
           wayland)) ; For wayland-scanner.
    ;; TODO Update to reflect this change: https://github.com/hyprwm/Hyprland/commit/8f9887b0c9443d6c2559feeec411daecb9780a97
    (inputs
     (list aquamarine
           bash-minimal ; For patching various '/bin/sh' references.
           cairo
           expat
           fribidi
           ;; gcc ; TODO see above. Also will need to be "gcc-for-hypr-ecosystem" for the moment if keeping.
           dbus ; For patching 'dbus-update-activation-environment'.
           git-minimal
           hwdata
           hyprcursor
           hyprlang
           hyprutils
           libdatrie
           libdisplay-info
           libdrm
           ;; ;; TODO Having libglvnd this causes a crash on launch. Hyprland seems fine without it but it's inconsistent with the rest of the hypr ecosystem (perhaps most relevantly aquamarine). Also having all these libglvnds is inconsistent with Guix in general. I'm not sure what to do. Maybe report the issue upstream if I decide to keep the libglvnds.
           ;; ;; The error, for reference:
           ;; ;; [LOG] Creating the CHyprOpenGLImpl!
           ;; ;; [LOG] Supported EGL extensions: (0)
           ;; ;; [CRITICAL] [Tracy GPU Profiling] eglGetProcAddress(eglCreateImageKHR) failed
           ;; libglvnd
           libinput-minimal
           libliftoff
           libseat
           libselinux
           libsepol
           libthai
           libxcursor
           libxkbcommon
           mesa
           pango
           pciutils
           pcre2
           pkgconf ; For patching 'pkgconf'.
           tomlplusplus
           `(,util-linux "lib") ; For libuuid.
           wayland
           wayland-protocols
           ;; For Xwayland.
           libxcb
           libxdmcp
           xcb-util
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

(define %aquamarine-commit "e4a13203112a036fc7f437d391c7810f3dd5ab52")
(define-public aquamarine
  (package
    (name "aquamarine")
    ;; (version "0.4.1")
    (version (git-version "0.4.1" "0" %aquamarine-commit))
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/aquamarine")
                    ;; (commit (string-append "v" version))
                    (commit %aquamarine-commit)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                ;; "19yrwaiyh4za8d3xixjkqdif1l4r71q7rzqa05by5zc3za3vzlzw"
                "19yrwaiyh4za8d3xixjkqdif1l4r71q7rzqa05by5zc3za3vzlzw"))))
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
     (list gcc-for-hypr-ecosystem
           hyprwayland-scanner
           pkg-config
           wayland)) ; For wayland-scanner.
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
    (version "1.3.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/xdg-desktop-portal-hyprland")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "14n4a8b91ili0kp2kjqlw3h57bsxkrjwg5bhlw2h3q93zaxv2b3k"))))
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
     (list gcc-for-hypr-ecosystem
           pkg-config
           wayland)) ; For wayland-scanner.
    (inputs
     (list hyprland-protocols
           hyprlang
           libdrm
           mesa
           pipewire
           qtbase
           qttools
           qtwayland
           sdbus-c++
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
    (version "0.4.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprlock")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1zzv7w7hn8k71w75a9mz548cbl4f8zcsd8i92abgnrx5x9i35q63"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list gcc-for-hypr-ecosystem
           pkg-config))
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
    (version "0.1.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hypridle")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "10l0yxy1avryjj54gimw2blhl7348dypyhh43b73a8ncjicpjnzc"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list gcc-for-hypr-ecosystem
           pkg-config))
    (inputs
     (list hyprlang
           hyprutils
           sdbus-c++
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
     (list gcc-for-hypr-ecosystem
           pkg-config
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
    (version "0.3.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprpicker")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "14vw74ml99kllxfy9vjlix6lwj2ajd32fi8gd8w9wv1s6gbhb105"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f ; No tests.
      #:configure-flags
      #~(list (string-append "-DCMAKE_INSTALL_MANDIR=" #$output "/share/man"))))
    (native-inputs
     (list gcc-for-hypr-ecosystem
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

(define-public hyprwayland-scanner
  (package
    (name "hyprwayland-scanner")
    (version "0.4.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprwayland-scanner")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1xc2xcxpq61lg964ihk0wbfzqqvibw20iz09g0p33ym51gwlpxr4"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    (native-inputs
     (list gcc-for-hypr-ecosystem
           pkg-config))
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
    (version "0.3.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprland-protocols")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "01j5hc8qnjzqiiwryfawx1wzrhkn0m794knphyc0vsxwkcmjaj8x"))))
    (build-system meson-build-system)
    (native-inputs
     (list gcc-for-hypr-ecosystem))
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
    (version "0.1.9")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprcursor")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0z3ar580n630145nq80qw0p8v0kai6knvhi6nr9z0y1jrb07b0ql"))
              (patches
               (search-patches "hyprcursor-dirs.patch"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; There are a couple of tests but they seem more like examples and
      ;; require a cursor theme to be available.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-runtime-dependency-path
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "hyprcursor-util/src/main.cpp"
                (("xcur2png") (search-input-file inputs "bin/xcur2png"))))))))
    (native-inputs
     (list gcc-for-hypr-ecosystem
           pkg-config))
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
    (version "0.5.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprlang")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "17i0372yv0fcwnyki36crz7afw8c5f3j985m083p7rjbh4fn3br6"))))
    (build-system cmake-build-system)
    (native-inputs
     (list gcc-for-hypr-ecosystem
           pkg-config))
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
    (version "0.2.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprutils")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0nxx5yb5k9726x95n8gi27xyxyzwb0ma0nj3czpb51sda1k0hz0g"))))
    (build-system cmake-build-system)
    (native-inputs
     (list gcc-for-hypr-ecosystem
           pkg-config))
    (inputs
     (list pixman))
    (home-page "https://github.com/hyprwm/hyprutils")
    (synopsis "Small C++ library for utilities used across the Hypr* ecosystem")
    (description
     "Hyprland utilities library used across the ecosystem.")
    (license license:bsd-3)))
