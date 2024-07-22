(define-module (gnu packages hyprland)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system asdf)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system haskell)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system pyproject)
  #:use-module (guix build-system python)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages benchmark)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages calendar)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)

  #:use-module (gnu packages cpp)

  #:use-module (gnu packages crates-io)
  #:use-module (gnu packages crates-graphics)
  #:use-module (gnu packages datastructures)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages fribidi)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages hardware)
  #:use-module (gnu packages haskell-check)
  #:use-module (gnu packages haskell-web)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages image)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lisp-check)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages logging)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages man)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages mpd)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages music)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pretty-print)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages stb)
  #:use-module (gnu packages suckless)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages time)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xdisorg)

  #:use-module (gnu packages xml)

  #:use-module (gnu packages xorg)


  #:use-module (gnu packages qt)
  #:use-module (guix build-system qt)

  #:use-module (gnu packages wm))

;; (define hyprland-name "hyprland")
;; (define hyprland-version "0.34.0")
;; (define hyprland-source
;;   (origin
;;     (method git-fetch)
;;     (uri (git-reference
;;           (url "https://github.com/hyprwm/Hyprland")
;;           (commit (string-append "v" hyprland-version))))
;;     (file-name (git-file-name hyprland-name hyprland-version))
;;     (sha256
;;      (base32
;;       "0jsqfg8yk2b1z52fmqw1jjn6b8qkfh5x0xk1j0zx7ng4il2f6ajr"))))

;; (define-public hyprland
;;   (package
;;     (name hyprland-name)
;;     (version hyprland-version)
;;     (source (origin
;;               (inherit hyprland-source)
;;               (patches
;;                (list (file-append hyprland-source
;;                                   "/nix/patches/meson-build.patch")))))
;;     ;; TODO need this? build --source and check if it's there or whatever
;;     ;; (snippet '(delete-file-recursively "subprojects"))

;;     ;; (source (origin
;;     ;;           (method url-fetch)
;;     ;;           (uri (string-append "https://github.com/hyprwm/Hyprland"
;;     ;;                               "/releases/download/v" version
;;     ;;                               "/source-v" version ".tar.gz"))
;;     ;;           (modules '((guix build utils)))
;;     ;;           (snippet '(delete-file-recursively "subprojects"))
;;     ;;           (patches (list hyprland-unbundle-wlroots-patch))
;;     ;;           (sha256
;;     ;;            (base32
;;     ;;             "0lwib3a3spdpigzz4333wppljm1if6fa97nnb50y1pd4j353jazy"))))
;;     (build-system meson-build-system)
;;     (arguments
;;      (list
;;       #:build-type "release"
;;       #:phases
;;       #~(modify-phases %standard-phases
;;           (add-after 'unpack 'fix-path
;;             (lambda* (#:key inputs #:allow-other-keys)
;;               (substitute* "src/render/OpenGL.cpp"
;;                 (("/usr") #$output))
;;               ;; TODO probably do this a bit nicer. Maybe I can just make it ALL execAndGet as long as search-input-file fails fast.
;;               (substitute* (find-files "src" "\\.cpp")
;;                 (("(execAndGet\\(\\(?\")\\<(cat|fc-list|lspci|nm)\\>"
;;                   _ pre cmd)
;;                  (string-append pre
;;                                 (search-input-file
;;                                  inputs (string-append "/bin/" cmd))))))))))
;;     (native-inputs
;;      (list pkg-config
;;            jq
;;            ;; wayland-scanner
;;            ))
;;     (inputs
;;      (list hyprland-protocols
;;            pango
;;            pciutils
;;            ;; udis86-for-hyprland
;;            ;; wlroots-for-hyprland
;;            wlroots

;;            tomlplusplus

;;            (@(gnu packages version-control) git) ; -minimal?
;;            ;; libgl
;;            libdrm
;;            libinput ; -minimal?
;;            libxkbcommon
;;            mesa
;;            wayland
;;            wayland-protocols

;;            ;; ;; Optional
;;            elogind ;; TODO maybe basu? Might have to patch the build phase or something

;;            ;; Optional, for xwayland
;;            libxcb
;;            xcb-util-wm
;;            xorg-server-xwayland))
;;     (home-page "https://hyprland.org")
;;     (synopsis "Dynamic tiling Wayland compositor based on wlroots")
;;     (description
;;      "Hyprland is a dynamic tiling Wayland compositor based on @code{wlroots}
;; that doesn't sacrifice on its looks.  It supports multiple layouts, fancy
;; effects, has a very flexible IPC model allowing for a lot of customization, and
;; more.")
;;     (license license:bsd-3)))




(define-public aquamarine
  (package
    (name "aquamarine")
    (version "0.1.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/aquamarine")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0py4p26iaysh7zkghwgwc1dnrb1cmgklh1i4p8gqvi521xf7kv5f"))))
    (build-system cmake-build-system)
    ;; TODO
    ;; -- Running /tmp/guix-build-aquamarine-0.1.1.drv-0/source/data/hwdata.sh < //gnu/store/38jxsm28ha5mc5fa65y60hjz5j6l2y4i-hwdata-0.382/share/hwdata/pnp.ids
    ;; CMake Warning at CMakeLists.txt:118 (message):
    ;;   hwdata gathering pnps failed
    ;; TODO
    ;; (arguments
    ;;  (list #:tests? #f)) ; No tests.
    (native-inputs
     (list hwdata ; TODO depsBuildBuild, I thik here is fine
           hyprwayland-scanner
           pkg-config))
    ;; TODO
    (inputs
     (list hyprutils
           libdisplay-info
           libdrm
           libffi
           ;; libGL
           libinput
           libseat
           mesa
           pixman
           eudev ; udev?
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/aquamarine")
    (synopsis "A very light linux rendering backend library")
    (description
     "Aquamarine is a very light linux rendering backend library. It provides
basic abstractions for an application to render on a Wayland session (in a
window) or a native DRM session.")
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
    (native-inputs
     (list pkg-config))
    (inputs
     (list cairo
           hyprlang
           librsvg
           libzip
           tomlplusplus))
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
    (version "0.2.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprutils")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "17iz7w0vdczjwdpkm1hjvkiyj7vx5c4linqn4228y4yvcy6bsq5a"))))
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
     (list ;;  #:tests? #f                  ;No tests ; TODO
           #:qtbase qtbase
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-path
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* (find-files "." "\\.cp?*$")
                     (("/bin/sh") "sh")
                     (("\\<(sh|grim|hyprctl|slurp)\\>" _ cmd)
                      (search-input-file inputs (string-append "/bin/" cmd)))
                     (("\\<(hyprland-share-picker)\\>" _ cmd)
                      (string-append #$output "/bin/" cmd))))))))
    ;; TODO nb: he adds wrapQtAppsHook in native inputs and then does "don't wrap" here. Huh.
    ;; dontWrapQtApps = true;
    ;;
    ;; postInstall = ''
    ;;   wrapProgramShell $out/bin/hyprland-share-picker \
    ;;     "''${qtWrapperArgs[@]}" \
    ;;     --prefix PATH ":" ${lib.makeBinPath [slurp hyprland]}
    ;;
    ;;   wrapProgramShell $out/libexec/xdg-desktop-portal-hyprland \
    ;;     --prefix PATH ":" ${lib.makeBinPath [(placeholder "out")]}
    ;; '';
    (native-inputs
     (list pkg-config
           wayland)) ; For wayland-scanner.
    ;; TODO The upstream list then the RAKINO list, which might be good
    ;; (inputs
    ;;  (list hyprland-protocols
    ;;        hyprlang
    ;;        libdrm
    ;;        mesa
    ;;        pipewire
    ;;        qtbase
    ;;        qttools
    ;;        qtwayland
    ;;        sdbus-cpp
    ;;        systemd
    ;;        wayland
    ;;        wayland-protocols)
    ;;  (list bash-minimal
    ;;        grim
    ;;        hyprland
    ;;        hyprland-protocols
    ;;        hyprlang
    ;;        mesa
    ;;        pipewire
    ;;        qtwayland
    ;;        sdbus-c++
    ;;        slurp
    ;;        wayland-protocols))
    (home-page "https://github.com/hyprwm/xdg-desktop-portal-hyprland")
    (synopsis "XDG Desktop Portal backend for Hyprland")
    (description
     "This package provides @code{xdg-desktop-portal-hyprland}, which extends
@code{xdg-desktop-portal-wlr} for Hyprland with support for
@code{xdg-desktop-portal} screenshot and casting interfaces, while adding a few
extra portals specific to Hyprland, mostly for window sharing.")
    (license license:bsd-3)))





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
    ;; TODO
    ;; (arguments
    ;;  (list #:tests? #f)) ; No tests.
    (native-inputs
     (list pkg-config))
    ;; TODO
    ;; (inputs
    ;;  (list cairo
    ;;        file
    ;;        libdrm
    ;;        libGL
    ;;        libjpeg
    ;;        libwebp
    ;;        libxkbcommon
    ;;        mesa
    ;;        hyprlang
    ;;        hyprutils
    ;;        pam
    ;;        pango
    ;;        wayland
    ;;        wayland-protocols))
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
     (list pkg-config))
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
    (version "0.7.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprpaper")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0426ic89zjd28z35yyzsh0ch7y9rnm80762vha1r5vf00bqdqpcp"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f)) ; No tests.
    ;; TODO Do this? There's also a GIT_COMMIT_MESSAGE that isn't addressed?
    ;;  prePatch = ''
    ;;    substituteInPlace src/main.cpp \
    ;;      --replace GIT_COMMIT_HASH '"${commit}"'
    ;;  '';
    (native-inputs
     (list pkg-config
           hyprwayland-scanner))
    ;; TODO The upstream list then the Nix list.
    ;; (inputs
    ;;  (list cairo
    ;;        expat
    ;;        file
    ;;        fribidi
    ;;        hyprlang
    ;;        hyprutils
    ;;        libdatrie
    ;;        libGL
    ;;        libjpeg
    ;;        libselinux
    ;;        libsepol
    ;;        libthai
    ;;        libwebp
    ;;        pango
    ;;        pcre
    ;;        pcre2
    ;;        wayland
    ;;        wayland-protocols
    ;;        wayland-scanner
    ;;        xorg.libXdmcp
    ;;        util-linux)
    ;;  (list cairo
    ;;        expat
    ;;        file
    ;;        fribidi
    ;;        hyprlang
    ;;        libdatrie
    ;;        libGL
    ;;        libjpeg
    ;;        libselinux
    ;;        libsepol
    ;;        libthai
    ;;        libwebp
    ;;        libXdmcp
    ;;        pango
    ;;        pcre
    ;;        pcre2
    ;;        util-linux
    ;;        wayland
    ;;        wayland-protocols))
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
    (native-inputs
     (list pkg-config))
    ;; TODO The upstream list then the Nix list.
    ;; (inputs
    ;;  (list cairo
    ;;        fribidi
    ;;        hyprutils
    ;;        libdatrie
    ;;        libGL
    ;;        libjpeg
    ;;        libselinux
    ;;        libsepol
    ;;        libthai
    ;;        libxkbcommon
    ;;        pango
    ;;        pcre
    ;;        pcre2
    ;;        utillinux
    ;;        wayland
    ;;        wayland-protocols
    ;;        wayland-scanner
    ;;        xorg.libXdmcp)
    ;;  (list cairo
    ;;        fribidi
    ;;        libGL
    ;;        libdatrie
    ;;        libjpeg
    ;;        libselinux
    ;;        libsepol
    ;;        libthai
    ;;        libxkbcommon
    ;;        pango
    ;;        pcre
    ;;        wayland
    ;;        wayland-protocols
    ;;        wayland-scanner
    ;;        libXdmcp
    ;;        util-linux))
    (home-page "https://github.com/hyprwm/hyprpicker")
    (synopsis "A wlroots-compatible Wayland color picker that does not suck")
    (description "Launch it. Click. That's it.")
    (license license:bsd-3)))
