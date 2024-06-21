;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2016 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2016, 2017, 2018 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2017, 2018, 2019 Rutger Helling <rhelling@mykolab.com>
;;; Copyright © 2017, 2020 Nicolas Goaziou <mail@nicolasgoaziou.fr>
;;; Copyright © 2018–2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2019 Pierre Neidhardt <mail@ambrevar.xyz>
;;; Copyright © 2022 Liliana Marie Prikler <liliana.prikler@gmail.com>
;;; Copyright © 2023 Kaelyn Takata <kaelyn.alexi@protonmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages wine)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages image)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mingw)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages samba)
  #:use-module (gnu packages scanner)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

(define (wine-source version hash)
  (let* ((wine-version (version-major+minor version))
         (subdirectory (string-append
                        (version-major version)
                        (if (string-suffix? ".0" wine-version)
                            ".0"
                            ".x"))))
    (origin
      (method url-fetch)
      (uri (string-append "https://dl.winehq.org/wine/source/"
                          subdirectory "/"
                          "wine-" wine-version ".tar.xz"))
      (file-name (string-append "wine-" wine-version ".tar.xz"))
      (sha256
       (base32 hash)))))

(define (install-wine-mono version hash)
  (let ((wine-mono (make-wine-mono version hash)))
    #~(lambda _
        (let ((dir (string-append #$output
                                  "/share/wine/mono/wine-mono-"
                                  #$(package-version wine-mono))))
          (mkdir-p dir)
          (copy-recursively (string-append #$wine-mono) dir)))))

(define (install-wine-gecko bits version hash)
  (let ((wine-gecko (make-wine-gecko bits version hash)))
    #~(lambda _
        (let ((dir (string-append #$output
                                  "/share/wine/gecko/wine-gecko-"
                                  #$(package-version wine-gecko)
                                  "-"
                                  #$(match bits
                                      ('32 "x86")
                                      ('64 "x86_64")))))
          (mkdir-p dir)
          (copy-recursively (string-append #$wine-gecko) dir)))))

(define-public wine
  (package
    (name "wine")
    (version "9.0")
    (source
     (wine-source version
                  "1vm61hrkinjqicxidhbhq3j8sb1iianfypdvjmnvgxcmac50kzbw"))
    (build-system gnu-build-system)
    (native-inputs
     (list bison
           flex
           gettext-minimal
           mingw-w64-i686
           perl
           pkg-config))
    (inputs
     ;; Some libraries like libjpeg are now compiled into native PE objects.
     ;; The ELF objects provided by Guix packages are of no use.  Whilst this
     ;; is technically bundling, it's quite defensible.  It might be possible
     ;; to build some of these from Guix PACKAGE-SOURCE but attempts were not
     ;; fruitful so far.  See <https://www.winehq.org/announce/7.0>.
     (list alsa-lib
           bash-minimal
           cups
           dbus
           eudev
           fontconfig
           freetype
           gnutls
           gst-plugins-base
           libgphoto2
           openldap
           samba
           sane-backends
           libpcap
           libusb
           libice
           libx11
           libxi
           libxext
           libxcursor
           libxrender
           libxrandr
           libxinerama
           libxxf86vm
           libxcomposite
           mit-krb5
           openal
           pulseaudio-minimal
           sdl2
           unixodbc
           v4l-utils
           vulkan-loader

           ;; For wayland support.
           libxkbcommon
           wayland
           wayland-protocols))
    (arguments
     (list
      ;; Force a 32-bit build targeting a similar architecture, i.e.:
      ;; armhf for armhf/aarch64, i686 for i686/x86_64.
      #:system (match (%current-system)
                 ((or "armhf-linux" "aarch64-linux") "armhf-linux")
                 (_ "i686-linux"))
      ;; XXX: There's a test suite, but it's unclear whether it's supposed to
      ;; pass.
      #:tests? #f
      #:make-flags
      #~(list "SHELL=bash"
              (string-append "libdir=" #$output "/lib/wine32"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-SHELL
            (lambda _
              (substitute* "configure"
                ;; configure first respects CONFIG_SHELL, clobbers SHELL later.
                (("/bin/sh")
                 (which "bash")))))
          (add-after 'configure 'patch-dlopen-paths
            ;; Hardcode dlopened sonames to absolute paths.
            (lambda _
              (let* ((library-path (search-path-as-string->list
                                    (getenv "LIBRARY_PATH")))
                     (find-so (lambda (soname)
                                (search-path library-path soname))))
                (substitute* "include/config.h"
                  (("(#define SONAME_.* )\"(.*)\"" _ defso soname)
                   (format #f "~a\"~a\"" defso (find-so soname)))))))
          (add-after 'patch-generated-file-shebangs 'patch-makedep
            (lambda* (#:key outputs #:allow-other-keys)
              (substitute* "tools/makedep.c"
                (("output_filenames\\( unix_libs \\);" all)
                 (string-append all
                                "output ( \" -Wl,-rpath=%s \", arch_install_dirs[arch] );")))))
          (add-before 'build 'set-widl-time-override
            ;; Set WIDL_TIME_OVERRIDE to avoid embedding the current date in
            ;; files generated by WIDL.
            (lambda _
              (setenv "WIDL_TIME_OVERRIDE" "315532800")))
          ;; Explicitly set the 32-bit version of vulkan-loader when installing
          ;; to i686-linux or x86_64-linux.
          ;; TODO: Add more JSON files as they become available in Mesa.
          #$@(match (%current-system)
               ((or "i686-linux" "x86_64-linux")
                `((add-after 'install 'wrap-executable
                   (lambda* (#:key inputs outputs #:allow-other-keys)
                     (let* ((out (assoc-ref outputs "out"))
                            (icd (string-append out "/share/vulkan/icd.d")))
                       (mkdir-p icd)
                       (copy-file (search-input-file
                                   inputs
                                   "/share/vulkan/icd.d/radeon_icd.i686.json")
                                  (string-append icd "/radeon_icd.i686.json"))
                       (copy-file (search-input-file
                                   inputs
                                   "/share/vulkan/icd.d/intel_icd.i686.json")
                                  (string-append icd "/intel_icd.i686.json"))
                       (wrap-program (string-append out "/bin/wine-preloader")
                         `("VK_ICD_FILENAMES" ":" =
                           (,(string-append icd
                                            "/radeon_icd.i686.json" ":"
                                            icd "/intel_icd.i686.json")))))))))
               (_
                `()))
          (add-after 'install 'install-mono
            #$(install-wine-mono
               "8.1.0"
               "1m7d1rznh226s9n1x69fsajgkn5fy7jfn735kqz9wk4yf908lgjf"))
          (add-after 'install 'install-gecko32
            #$(install-wine-gecko
               '32
               "2.47.4"
               "1dmg221nxmgyhz7clwlnvwrx1wi630z62y4azwgf40l6jif8vz1c")))))
    (home-page "https://www.winehq.org/")
    (synopsis "Implementation of the Windows API (32-bit only)")
    (description
     "Wine (originally an acronym for \"Wine Is Not an Emulator\") is a
compatibility layer capable of running Windows applications.  Instead of
simulating internal Windows logic like a virtual machine or emulator, Wine
translates Windows API calls into POSIX calls on-the-fly, eliminating the
performance and memory penalties of other methods and allowing you to cleanly
integrate Windows applications into your desktop.")
    (license license:lgpl2.1+)
    ;; Any platform should be able to build wine, but based on '#:system' these
    ;; are the ones we currently support.
    (supported-systems '("i686-linux" "x86_64-linux" "armhf-linux"))))

(define-public wine64
  (package
    (inherit wine)
    (name "wine64")
    (native-inputs (modify-inputs (package-native-inputs wine)
                     (prepend mingw-w64-x86_64)))
    (inputs (modify-inputs (package-inputs wine)
              (prepend wine)))
    (arguments
     (substitute-keyword-arguments
         (strip-keyword-arguments '(#:system) (package-arguments wine))
       ((#:make-flags _)
        #~(list "SHELL=bash"
                (string-append "libdir=" #$output "/lib/wine64"))
        )
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'install 'copy-wine32-binaries
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let ((out (assoc-ref %outputs "out")))
                  ;; Copy the 32-bit binaries needed for WoW64.
                  (copy-file (search-input-file inputs "/bin/wine")
                             (string-append out "/bin/wine"))
                  ;; Copy the real 32-bit wine-preloader instead of the wrapped
                  ;; version.
                  (copy-file (search-input-file inputs "/bin/.wine-preloader-real")
                             (string-append out "/bin/wine-preloader")))))
            ;; Explicitly set both the 64-bit and 32-bit versions of vulkan-loader
            ;; when installing to x86_64-linux so both are available.
            ;; TODO: Add more JSON files as they become available in Mesa.
            #$@(match (%current-system)
                 ((or "x86_64-linux")
                  `((delete 'wrap-executable)
                    (add-after 'copy-wine32-binaries 'wrap-executable
                      (lambda* (#:key inputs outputs #:allow-other-keys)
                        (let* ((out (assoc-ref outputs "out"))
                               (icd-files (map
                                           (lambda (basename)
                                             (search-input-file
                                              inputs
                                              (string-append "/share/vulkan/icd.d/"
                                                             basename)))
                                           '("radeon_icd.x86_64.json"
                                             "intel_icd.x86_64.json"
                                             "radeon_icd.i686.json"
                                             "intel_icd.i686.json"))))
                          (wrap-program (string-append out "/bin/wine-preloader")
                            `("VK_ICD_FILENAMES" ":" = ,icd-files))
                          (wrap-program (string-append out "/bin/wine64-preloader")
                            `("VK_ICD_FILENAMES" ":" = ,icd-files)))))))
                 (_
                  `()))
            (add-after 'install 'copy-wine32-libraries
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  (copy-recursively (search-input-directory inputs "/lib/wine32")
                                    (string-append out "/lib/wine32")))))
            (add-after 'install-gecko32 'install-gecko64
              #$(install-wine-gecko
                 '64
                 "2.47.4"
                 "0518m084f9bdl836gs3d8qm8jx65j2y1w35zi9x8s1bxadzgr27x"))
            (add-after 'compress-documentation 'copy-wine32-manpage
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  ;; Copy the missing man file for the wine binary from wine.
                  (copy-file (search-input-file inputs "/share/man/man1/wine.1.gz")
                             (string-append out "/share/man/man1/wine.1.gz")))))))
       ((#:configure-flags configure-flags '())
        #~(cons "--enable-win64" #$configure-flags))))
    (synopsis "Implementation of the Windows API (WoW64 version)")
    (supported-systems '("x86_64-linux" "aarch64-linux"))))

(define %wine-devel-version "9.11")

(define-public wine-devel
  (package
    (inherit wine)
    (name "wine-devel")
    (version %wine-devel-version)
    (source
     (wine-source version
                  "0h3jz1xxdss4hvgh0aj213xn3rya90z876l45b86j4d79qk0r86z"))
    (arguments
     (substitute-keyword-arguments (package-arguments wine)
       ((#:phases phases)
        #~(modify-phases #$phases
            (replace 'install-mono
              #$(install-wine-mono
                 "9.1.0"
                 "0rw7r09g7fkkxl6lgg9aw8fy0mc8aflmdcs6v6ziya9v4386j4b0"))))))))

(define-public wine64-devel
  (package
    (inherit wine64)
    (name "wine64-devel")
    (version %wine-devel-version)
    (source
     (wine-source version
                  "0h3jz1xxdss4hvgh0aj213xn3rya90z876l45b86j4d79qk0r86z"))
    (arguments
     (substitute-keyword-arguments (package-arguments wine64)
       ((#:phases phases)
        #~(modify-phases #$phases
            (replace 'install-mono
              #$(install-wine-mono
                 "9.1.0"
                 "0rw7r09g7fkkxl6lgg9aw8fy0mc8aflmdcs6v6ziya9v4386j4b0"))
            (replace 'copy-wine32-manpage
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  ;; Copy the missing man file for the wine binary from wine.
                  (copy-file (search-input-file inputs "/share/man/man1/wine.1.zst")
                             (string-append out "/share/man/man1/wine.1.zst")))))))))))

(define-public wine-staging-patchset-data
  (package
    (name "wine-staging-patchset-data")
    (version %wine-devel-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/wine-staging/wine-staging")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1aiawcpagg6p7k6zryiibsamq80znsdh8yk2pnqm2imdqs865ady"))))
    (build-system trivial-build-system)
    (native-inputs
     (list coreutils))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((build-directory ,(string-append name "-" version))
                (source (assoc-ref %build-inputs "source"))
                (coreutils (assoc-ref %build-inputs "coreutils"))
                (out (assoc-ref %outputs "out"))
                (wine-staging (string-append out "/share/wine-staging")))
           (copy-recursively source build-directory)
           (with-directory-excursion build-directory
             (substitute* '("patches/gitapply.sh" "staging/patchinstall.py")
               (("/usr/bin/env")
                (string-append coreutils "/bin/env"))))
           (copy-recursively build-directory wine-staging)
           #t))))
    (home-page "https://github.com/wine-staging")
    (synopsis "Patchset for Wine")
    (description
     "wine-staging-patchset-data contains the patchset to build Wine-Staging.")
    (license license:lgpl2.1+)))

(define-public wine-staging
  (package
    (inherit wine-devel)
    (name "wine-staging")
    (inputs (modify-inputs (package-inputs wine-devel)
              (prepend autoconf ; for autoreconf
                       ffmpeg
                       gtk+
                       libva
                       mesa
                       python
                       util-linux ; for hexdump
                       wine-staging-patchset-data)))
    (native-inputs
     (modify-inputs (package-native-inputs wine-devel)
       (prepend python-3)))
    (arguments
     (substitute-keyword-arguments (package-arguments wine-devel)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'patch-SHELL)
            (add-before 'configure 'apply-wine-staging-patches
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke (search-input-file
                         inputs
                         "/share/wine-staging/staging/patchinstall.py")
                        "DESTDIR=."
                        "--all")))
            (add-after 'apply-wine-staging-patches 'patch-SHELL
              (assoc-ref #$phases 'patch-SHELL))))))
    (synopsis "Implementation of the Windows API (staging branch, 32-bit only)")
    (description "Wine-Staging is the testing area of Wine.  It
contains bug fixes and features, which have not been integrated into
the development branch yet.  The idea of Wine-Staging is to provide
experimental features faster to end users and to give developers the
possibility to discuss and improve their patches before they are
integrated into the main branch.")
    (home-page "https://github.com/wine-staging")
    ;; In addition to the regular Wine license (lgpl2.1+), Wine-Staging
    ;; provides Liberation and WenQuanYi Micro Hei fonts.  Those use
    ;; different licenses.  In particular, the latter is licensed under
    ;; both GPL3+ and Apache 2 License.
    (license
     (list license:lgpl2.1+ license:silofl1.1 license:gpl3+ license:asl2.0))))

(define-public wine64-staging
  (package
    (inherit wine-staging)
    (name "wine64-staging")
    (inputs (modify-inputs (package-inputs wine-staging)
              (prepend wine-staging)))
    (arguments
     (substitute-keyword-arguments (package-arguments wine64-devel)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'patch-SHELL)
            (add-before 'configure 'apply-wine-staging-patches
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke (search-input-file
                         inputs
                         "/share/wine-staging/staging/patchinstall.py")
                        "DESTDIR=."
                        "--all")))
            (add-after 'apply-wine-staging-patches 'patch-SHELL
              (assoc-ref #$phases 'patch-SHELL))))))
    (synopsis "Implementation of the Windows API (staging branch, WoW64
version)")
    (supported-systems '("x86_64-linux" "aarch64-linux"))))

(define (make-wine-mono version hash)
  (package
    (name "wine-mono")
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://dl.winehq.org/wine/wine-mono/"
                           version "/wine-mono-" version "-x86.tar.xz"))
       (sha256
        (base32 hash))))
    (build-system copy-build-system)
    (home-page "https://wiki.winehq.org/Mono")
    (synopsis "Wine's built-in replacement for Microsoft's .NET Framework")
    (description "Mono is an open-source and cross-platform implementation of
the .NET Framework.  Wine Mono is a fork of Mono that Wine uses to run .NET
Framework applications.")
    (license (list license:gpl2+ license:lgpl2.1 license:expat))
    (supported-systems '("i686-linux" "x86_64-linux"))))

(define (make-wine-gecko bits version hash)
  (package
    (name (match bits
            ('32 "wine-gecko32")
            ('64 "wine-gecko64")))
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://dl.winehq.org/wine/wine-gecko/"
                           version "/wine-gecko-" version "-"
                           (match bits
                             ('32 "x86")
                             ('64 "x86_64"))
                           ".tar.xz"))
       (sha256
        (base32 hash))))
    (build-system copy-build-system)
    (home-page "https://wiki.winehq.org/Gecko")
    (synopsis "Wine's built-in replacement for Microsoft's Internet Explorer")
    (description "Wine implements its own version of Internet Explorer. The
implementation is based on a custom version of Mozilla's Gecko Layout Engine.")
    (license license:mpl2.0)
    (supported-systems (list (match bits
                               ('32 "i686-linux")
                               ('64 "x86_64-linux"))))))
