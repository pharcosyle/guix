(define-module (gnu packages gamescope)
  #:use-module (guix build-system meson)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages benchmark)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages image)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages stb)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages wm))

(define (reshade-src commit hash)
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/Joshua-Ashton/reshade")
          (commit commit)))
    (sha256
     (base32 hash))))

;; Gamescope really wants/needs you to use specific versions.

(define reshade-src-for-gamescope
  (reshade-src
   "696b14cd6006ae9ca174e6164450619ace043283"
   "1zvhf3pgd8bhn8bynrsh725xn1dszsf05j8c9g6zabgv7vnz04a5"))

(define wlroots-for-gamescope
  (let ((base-wlroots wlroots-0.18)
        (fork-url "https://github.com/Joshua-Ashton/wlroots")
        (commit "4bc5333a2cbba0b0b88559f281dbde04b849e6ef")
        (revision "0"))
    (package
      (inherit base-wlroots)
      (version (git-version (package-version base-wlroots) revision commit))
      (source
       (origin
         (inherit (package-source base-wlroots))
         (uri (git-reference
               (url fork-url)
               (commit commit)))
         (file-name (git-file-name (package-name base-wlroots) version))
         (sha256
          (base32
           "14m9j9qkaphzm3g36im43b6h92rh3xyjh7j46vw9w2qm602ndwcf")))))))

;; Having a gamescope-specific version for this seems less important
;; (it's not included in gamescope's "force_fallback_for" list) but let's be
;; safe.
(define spirv-headers-for-gamescope
  (let ((commit "d790ced752b5bfc06b6988baadef6eb2d16bdf96")
        (revision "0"))
    (package
      (inherit spirv-headers)
      (version (git-version "1.3.268" revision commit))
      (source
       (origin
         (inherit (package-source spirv-headers))
         (uri (git-reference
               (url "https://github.com/KhronosGroup/SPIRV-Headers")
               (commit commit)))
         (file-name (git-file-name (package-name spirv-headers) version))
         (sha256
          (base32
           "1zzkqbqysiv52dk92i35gsyppnasln3d27b4rqv590zknk5g38is")))))))

(define-public gamescope
  (package
    (name "gamescope")
    (version "3.15.5")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/ValveSoftware/gamescope")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32 "02w7hf82paz9l6n7a3wks96yc5lprmqw02l6w9qm0jnirw0wiq7b"))))
    (build-system meson-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list "-Denable_openvr_support=false"
              "-Dforce_fallback_for=[]")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-deps+paths
            (lambda _
              (substitute* "meson.build"
                (("error.*\"force_fallback_for\" is missing entries.*") ""))
              (substitute* "src/meson.build"
                ;; Make pkgconfig names match. Ours has a version number in it,
                ;; theirs doesn't.
                (("'wlroots'") (string-append "'wlroots-"
                                              #$(version-major+minor
                                                 (package-version
                                                  wlroots-for-gamescope))
                                              "'"))
                (("dependency\\('stb'\\)")
                 (format #f "declare_dependency(include_directories: ['~a'])"
                         (string-join
                          '#$(map (lambda (label)
                                    (this-package-native-input label))
                                  (list "stb-image"
                                        "stb-image-resize"
                                        "stb-image-write"))
                          "','")))
                (("reshade/") (string-append #$reshade-src-for-gamescope "/"))
                (("../thirdparty/SPIRV-Headers")
                 #$(this-package-native-input "spirv-headers"))
                ;; HACK: Add pixman to gamescope executable dependencies to
                ;; work around an error: "DSO missing from command line".
                (("libdecor_dep, eis_dep,")
                 "libdecor_dep, eis_dep, dependency('pixman-1')"))
              (substitute* "src/reshade_effect_manager.cpp"
                (("/usr") #$output))
              (substitute* "src/Utils/Process.cpp"
                (("\"gamescopereaper\"")
                 (string-append "\""
                                #$output "/bin/gamescopereaper"
                                "\""))))))))
    (inputs
     (list glm
           libavif                ; Support for saving .AVIF HDR screenshots
           libcap
           libdecor
           libdisplay-info
           libdrm
           libei                  ; Support for XTest/Input emulation
           libinput-minimal
           libliftoff
           libx11
           libxcomposite
           libxcursor
           libxdamage
           libxext
           libxkbcommon
           libxmu
           libxrender
           libxres
           libxt
           libxtst
           pipewire               ; Screen capture via pipewire
           sdl2                   ; SDL2 Window Backend
           vulkan-loader
           wayland
           wlroots-for-gamescope))
    (native-inputs
     (append
      (list pkg-config)
      (if (%current-target-system)
          (list pkg-config-for-build)
          '())
      (list benchmark             ; Build benchmark tools
            glslang               ; For execuatable
            hwdata
            stb-image
            stb-image-resize
            stb-image-write
            spirv-headers-for-gamescope
            vkroots
            vulkan-headers        ; WSI layer.
            wayland-protocols)))
    (home-page "https://github.com/ValveSoftware/gamescope")
    (synopsis "Micro-compositor for running games")
    (description
     "gamescope is a micro-compositor for running games.  Its goal is to
provide an isolated compositor that is tailored towards gaming and supports
many gaming-centric features such as:
@itemize
@item Spoofing resolutions.
@item Upscaling.
@item Limiting framerates.
@end itemize")
    (license license:bsd-2)))
