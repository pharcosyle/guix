;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2018, 2019 Rutger Helling <rhelling@mykolab.com>
;;; Copyright © 2018, 2019 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018, 2023 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2020, 2023 Marius Bakke <marius@gnu.org>
;;; Copyright © 2021 Mathieu Othacehe <othacehe@gnu.org>
;;; Copyright © 2022 Kaelyn Takata <kaelyn.alexi@protonmail.com>
;;; Copyright © 2022 dan <i@dan.games>
;;; Copyright © 2023 Zheng Junjie <873216071@qq.com>
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

(define-module (gnu packages vulkan)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages check)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages wine)
  #:use-module (gnu packages xorg))

(define %vulkan-sdk-version "vulkan-sdk-1.3.275.0")

(define-public spirv-headers
  (package
    (name "spirv-headers")
    (version %vulkan-sdk-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/SPIRV-Headers")
             (commit version)))
       (sha256
        (base32
         "18gr715ap9w1rjvzd6l9pl9lwfqiikm2la5apv2lplj4a0k5v3zw"))
       (file-name (git-file-name name version))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f))                    ;no tests
    (home-page "https://github.com/KhronosGroup/SPIRV-Headers")
    (synopsis "Machine-readable files from the SPIR-V Registry")
    (description
     "SPIRV-Headers is a repository containing machine-readable files from
the SPIR-V Registry.  This includes:
@itemize
@item Header files for various languages.
@item JSON files describing the grammar for the SPIR-V core instruction set,
and for the GLSL.std.450 extended instruction set.
@item The XML registry file.
@end itemize\n")
    (license (license:x11-style
              (string-append "https://github.com/KhronosGroup/SPIRV-Headers/blob/"
                             version "/LICENSE")))))

(define-public spirv-tools
  (package
    (name "spirv-tools")
    (version %vulkan-sdk-version)
    (source
     (origin
      (method git-fetch)
      (uri (git-reference
            (url "https://github.com/KhronosGroup/SPIRV-Tools")
            (commit version)))
      (sha256
       (base32 "1hmfhvswg66x7x2ww5gj3mhgh59kgp7pwv36xagwyhbm7fhayca7"))
      (file-name (git-file-name name version))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags (list "-DBUILD_SHARED_LIBS=ON"
                               ;; Some packages like mpv fail to link
                               ;; when the static libraries are built.
                               "-DSPIRV_TOOLS_BUILD_STATIC=OFF"
                               (string-append
                                "-DSPIRV-Headers_SOURCE_DIR="
                                (assoc-ref %build-inputs "spirv-headers")))))
    (inputs (list spirv-headers))
    (native-inputs (list pkg-config python))
    (home-page "https://github.com/KhronosGroup/SPIRV-Tools")
    (synopsis "API and commands for processing SPIR-V modules")
    (description
     "The SPIR-V Tools project provides an API and commands for processing
SPIR-V modules.  The project includes an assembler, binary module
parser,disassembler, validator, and optimizer for SPIR-V.")
    (license license:asl2.0)))

(define-public spirv-cross
  (package
    (name "spirv-cross")
    (version %vulkan-sdk-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/SPIRV-Cross")
             (commit version)))
       (sha256
        (base32 "0zdpgj0lv8kqzcna7y44qdjvxjifaxmmmcar835y4cdr35izf6ij"))
       (file-name (git-file-name name version))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags
       (list "-DSPIRV_CROSS_SHARED=YES")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-tests-to-find-deps
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "CMakeLists.txt"
               (("\\$\\{CMAKE_(.*)_DIR\\}/external/glslang(.*)/bin")
                (string-append (assoc-ref inputs "glslang") "/bin")))
             (substitute* "CMakeLists.txt"
               (("\\$\\{CMAKE_(.*)_DIR\\}/external/spirv-tools(.*)/bin")
                (string-append (assoc-ref inputs "spirv-tools") "/bin")))))
         (add-before 'check 'update-reference-shaders
           (lambda _
             (with-directory-excursion "../source"
               (invoke "./update_test_shaders.sh")))))))
    (inputs
     (list glslang spirv-headers spirv-tools))
    (native-inputs (list python))
    (home-page "https://github.com/KhronosGroup/SPIRV-Cross")
    (synopsis "Parser for and converter of SPIR-V to other shader languages")
    (description
     "SPIRV-Cross tries hard to emit readable and clean output from the
SPIR-V, aiming to emit GLSL or MSL that looks like human-written code.")
    (license license:asl2.0)))

(define-public spirv-llvm-translator
  (package
    (name "spirv-llvm-translator")
    (version "17.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/SPIRV-LLVM-Translator")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0wvw1d75lnby5wjs6ny60g97y1jbmr7k1r3fyi95ng285wzvjfa7"))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags
       (list (string-append "-DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR="
                            (assoc-ref %build-inputs "spirv-headers")
                            "/include/spirv")
             (string-append "-DLLVM_EXTERNAL_LIT="
                            (assoc-ref %build-inputs "python-lit")
                            "/bin/lit")
             "-DLLVM_SPIRV_INCLUDE_TESTS=ON")))
    (inputs (list llvm-17))
    (native-inputs (list clang-17 llvm-17 python-lit spirv-headers))
    (home-page "https://github.com/KhronosGroup/SPIRV-LLVM-Translator")
    (synopsis "Bi-directional translation between SPIR-V and LLVM IR")
    (description
     "The LLVM/SPIR-V Bi-Directional Translator is a library and tool for
translation between LLVM IR and SPIR-V.")
    (license license:asl2.0)))

(define-public glslang
  (package
    (name "glslang")
    (version %vulkan-sdk-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/glslang")
             (commit version)))
       (sha256
        (base32
         "15xf1p9wwyvcps2kbyfiqnch3x2a1a9bd9aixq2y4yv9ir9hhhpf"))
       (file-name (git-file-name name version))))
    (build-system cmake-build-system)
    (arguments
     '(#:configure-flags '("-DBUILD_SHARED_LIBS=ON"
                           "-DALLOW_EXTERNAL_SPIRV_TOOLS=ON"
                           "-DGLSLANG_TESTS=ON")))
    (native-inputs
     (list pkg-config python))
    (inputs
     (list spirv-tools))
    (home-page "https://github.com/KhronosGroup/glslang")
    (synopsis "OpenGL and OpenGL ES shader front end and validator")
    (description
     "Glslang is the official reference compiler front end for the
OpenGL@tie{}ES and OpenGL shading languages.  It implements a strict
interpretation of the specifications for these languages.")
    ;; Modified BSD license. See "copyright" section of
    ;; https://www.khronos.org/opengles/sdk/tools/Reference-Compiler/
    (license (list license:bsd-3
                   ;; include/SPIRV/{bitutils,hex_float}.h are Apache 2.0.
                   license:asl2.0))))

(define-public vulkan-headers
  (package
    (name "vulkan-headers")
    (version %vulkan-sdk-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/Vulkan-Headers")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1ihzbn6aw20i40mlqv2ys3xw1g9ld79890a0bm7wpqmbp67s84wh"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f))                    ; No tests.
    (home-page
     "https://github.com/KhronosGroup/Vulkan-Headers")
    (synopsis "Vulkan Header files and API registry")
    (description
     "Vulkan-Headers contains header files and API registry for Vulkan.")
    (license (list license:asl2.0)))) ;LICENSE.txt

(define-public vulkan-loader
  (package
    (name "vulkan-loader")
    (version %vulkan-sdk-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/Vulkan-Loader")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0kcq6xsm151mk08vvqjlhj5mfxv4zgq35a2yi4f7yax20mfd8wz7"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; As many as 23 tests are expected to fail per architecture.
      ;; Limit the tests to those architectures tested upstream.
      #:tests? (and (%current-system)
                    (target-x86?))
      #:configure-flags
      #~(list (string-append "-DVULKAN_HEADERS_INSTALL_DIR="
                             (dirname (dirname
                                       (search-input-directory
                                        %build-inputs "include/vulkan"))))
              #$@(if (%current-target-system)
                     #~("-DBUILD_TESTS=OFF" "-DUSE_GAS=OFF")
                     #~("-DBUILD_TESTS=ON")))
       #:phases
       #~(modify-phases %standard-phases
           (add-after 'unpack 'fix-pkg-config-file
             (lambda* (#:key inputs #:allow-other-keys)
               (let ((vulkan-headers (dirname (search-input-directory
                                               inputs "include/vulkan"))))
                 ;; Ensure the pkg-config file refers to vulkan-headers.
                 (substitute* "loader/vulkan.pc.in"
                   (("^includedir=.*")
                    (string-append "includedir=" vulkan-headers "\n"))))))
           (add-after 'unpack 'use-system-googletest
             (lambda _
               ;; Inform the build system that googletest is already built.
               (substitute* "tests/CMakeLists.txt"
                 (("if.*IS_DIRECTORY.*googletest.*")
                  (string-append "if(true)\n"
                                 "    find_package(GTest REQUIRED)\n"
                                 "elseif(false)\n")))
               ;; Use the namespaced variable.
               (substitute* "tests/framework/CMakeLists.txt"
                 (("PUBLIC gtest ")
                  "PUBLIC GTest::gtest ")))))))
    (native-inputs
     (list googletest
           libxrandr
           pkg-config
           python
           wayland))
    (inputs
     (list vulkan-headers libxrandr))
    (home-page
     "https://github.com/KhronosGroup/Vulkan-Loader")
    (synopsis "Khronos official ICD loader and validation layers for Vulkan")
    (description
     "Vulkan allows multiple @dfn{Installable Client Drivers} (ICDs) each
supporting one or more devices to be used collectively.  The loader is
responsible for discovering available Vulkan ICDs on the system and inserting
Vulkan layer libraries, including validation layers between the application
and the ICD.")
    ;; This software is mainly Apache 2.0 licensed, but contains some components
    ;; covered by other licenses.  See COPYRIGHT.txt for details.
    (license (list license:asl2.0       ;LICENSE.txt
                   (license:x11-style "file://COPYRIGHT.txt")
                   license:bsd-3))))

(define-public vulkan-tools
  (package
    (name "vulkan-tools")
    (version %vulkan-sdk-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/KhronosGroup/Vulkan-Tools")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0g604gzzlqibnkjd18iss6iwn852nnsfrrgfnwn97khpr0xk1h6j"))))
    (build-system cmake-build-system)
    (inputs
     (list glslang libxrandr vulkan-loader wayland wayland-protocols))
    (native-inputs
     (list pkg-config python vulkan-headers))
    (arguments
     `(#:tests? #f                      ;no tests
       #:configure-flags (list (string-append "-DGLSLANG_INSTALL_DIR="
                               (assoc-ref %build-inputs "glslang")))))
    (home-page
     "https://github.com/KhronosGroup/Vulkan-Tools")
    (synopsis "Tools and utilities for Vulkan")
    (description
     "Vulkan-Tools provides tools and utilities that can assist development by
enabling developers to verify their applications correct use of the Vulkan
API.")
    (license (list license:asl2.0)))) ;LICENSE.txt

(define-public shaderc
  (package
    (name "shaderc")
    ;; shaderc doesn't follow the versioning scheme of vulkan sdk
    (version "2023.8")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/google/shaderc")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         ;; "0cs36p1y2269gjfv75fvs43ymsapmc8gsy2n91jnaqs3mpgqkjbk"
         "0cs26p1y2269gjfv75fvs43ymsapmc8gsy2n91jnaqs3mpgqkjbk")))) ; TODO Doesn't build, bogus hash to see if I end up needing it anywhere. Maybe wine?
    (build-system cmake-build-system)
    (arguments
     `(;; FIXME: Skip most of the tests, because enabling system gtest breaks
       ;; the build: <https://github.com/google/shaderc/issues/470>.
       #:configure-flags
       (list "-DSHADERC_SKIP_TESTS=ON"
             ;; Note: despite the name, this just specifies the headers.
             (string-append "-Dglslang_SOURCE_DIR="
                            (assoc-ref %build-inputs "glslang") "/include/glslang"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'do-not-look-for-bundled-sources
           (lambda _
             (substitute* "CMakeLists.txt"
               (("add_subdirectory\\(third_party\\)")
                ""))

             (substitute* "glslc/test/CMakeLists.txt"
               (("\\$<TARGET_FILE:spirv-dis>")
                (which "spirv-dis")))

             ;; Do not attempt to use git to encode version information.
             (substitute* "glslc/CMakeLists.txt"
               (("add_dependencies\\(glslc_exe build-version\\)")
                ""))
             (call-with-output-file "glslc/src/build-version.inc"
               (lambda (port)
                 (format port "\"~a\"\n\"~a\"\n\"~a\"~%"
                         ,version
                         ,(package-version spirv-tools)
                         ,(package-version glslang))))
             #t))
         ;; see: https://github.com/google/shaderc/pull/1276
         (add-after 'do-not-look-for-bundled-sources 'drop-additional-glslang-deps
           (lambda _
             (substitute* "glslc/CMakeLists.txt"
               (("OSDependent OGLCompiler") ""))
             (substitute* "libshaderc/CMakeLists.txt"
               (("OSDependent OGLCompiler") ""))
             (substitute* "libshaderc_util/CMakeLists.txt"
               (("OSDependent OGLCompiler") "")))))))
    (inputs
     (list glslang python spirv-headers spirv-tools))
    (native-inputs
     (list pkg-config))
    (home-page "https://github.com/google/shaderc")
    (synopsis "Tools for shader compilation")
    (description "Shaderc is a collection of tools, libraries, and tests for
shader compilation.")
    (license license:asl2.0)))

(define-public vkd3d
  (let ((commit "0c33f82f72c800f5925a55910e06a35de8197473")) ; Release 1.10. ; TODO There are tags, why aren't we using them?
    (package
     (name "vkd3d")
     (version "1.10")
     (source
      (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://source.winehq.org/git/vkd3d.git")
             (commit commit)))
       (sha256
        (base32
         "03acrv4z8na0nfqsffxfscy95386bznz1vvp8v2id99am3qmr6zz"))
       (file-name (string-append name "-" version "-checkout"))))
     (build-system gnu-build-system)
     (arguments
      `(#:configure-flags '("--with-spirv-tools")
        #:phases (modify-phases %standard-phases
                   (add-after 'unpack 'patch-for-new-vulkan
                     (lambda _
                       ;; Mimic upstream commit 8e7bf8a5c3e0047 for
                       ;; compatibility with newer vulkan-headers.
                       (substitute* "libs/vkd3d/vkd3d_private.h"
                         (("VK_PIPELINE_BIND_POINT_RANGE_SIZE")
                          "2u"))
                       #t)))))
     (native-inputs
      `(("autoconf" ,autoconf)
        ("automake" ,automake)
        ("gettext" ,gettext-minimal)
        ("libtool" ,libtool)
        ("pkg-config" ,pkg-config)))
     (inputs
      (list libx11
            libxcb
            spirv-headers
            spirv-tools
            vulkan-headers
            vulkan-loader
            wine-minimal ; Needed for 'widl'.
            xcb-util
            xcb-util-keysyms
            xcb-util-wm))
     (home-page "https://source.winehq.org/git/vkd3d.git/")
     (synopsis "Direct3D 12 to Vulkan translation library")
     (description "vkd3d is a library for translating Direct3D 12 to Vulkan.")
     (license license:lgpl2.1))))

(define-public vulkan-validationlayers
  (package
    (name "vulkan-validationlayers")
    (version %vulkan-sdk-version)
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url
                     "https://github.com/KhronosGroup/Vulkan-ValidationLayers")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0j39j43siz6jwqai8miy0hgcz5b4lln9xfhk1vzds21kgn17r744"))))
    (build-system cmake-build-system)
    (inputs (list glslang
                  libxrandr
                  mesa
                  shaderc
                  spirv-tools
                  vulkan-loader
                  wayland))
    (native-inputs (list pkg-config python spirv-headers vulkan-headers))
    (arguments
     (list #:tests? #f ;no tests
           #:configure-flags
           #~(list "-DUSE_ROBIN_HOOD_HASHING=OFF"
                   (string-append "-DGLSLANG_INSTALL_DIR="
                                  (dirname (dirname
                                            (search-input-directory
                                             %build-inputs
                                             "include/glslang"))))
                   (string-append "-DSPIRV_HEADERS_INSTALL_DIR="
                                  (dirname (dirname
                                            (search-input-directory
                                             %build-inputs
                                             "include/spirv"))))
                   (string-append "-DSPIRV_TOOLS_INSTALL_DIR="
                                  (dirname (dirname
                                            (search-input-directory
                                             %build-inputs
                                             "include/spirv-tools"))))
                   (string-append "-DVULKAN_HEADERS_INSTALL_DIR="
                                  (dirname (dirname
                                            (search-input-directory
                                             %build-inputs
                                             "include/vulkan"))))
                   "-Wno-dev")
           #:phases #~(modify-phases %standard-phases
                        (add-after 'install 'set-layer-path-in-manifest
                          (lambda _
                            (let ((manifest (string-append #$output
                                             "/share/vulkan/explicit_layer.d"
                                             "/VkLayer_khronos_validation.json")))
                              (substitute* manifest
                                (("\"libVkLayer_khronos_validation.so\"")
                                 (string-append "\"" #$output
                                  "/lib/libVkLayer_khronos_validation.so\"")))))))))
    (home-page "https://github.com/KhronosGroup/Vulkan-ValidationLayers")
    (synopsis "Khronos official validation layers for Vulkan")
    (description
     "Vulkan-ValidationLayers provides the Khronos official validation layers that
can assist development by enabling developers to verify their applications correctly
use the Vulkan API.")
    (license license:asl2.0)))

(define-public volk
  (package
    (name "volk")
    (version %vulkan-sdk-version)
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/zeux/volk")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1zmr3wy0hc1hpwyifvjyxxfs7vc4ipqrfj0mav7cjdq6jf0cnf5r"))))
    (build-system cmake-build-system)
    (arguments
     '(#:tests? #f                      ;no test
       #:configure-flags '("-DVOLK_INSTALL=ON" "-DVOLK_PULL_IN_VULKAN=ON")))
    (inputs (list vulkan-headers))
    (synopsis "Meta loader for Vulkan API")
    (description
     "Volk is a meta-loader for Vulkan.  It allows you to dynamically load
entrypoints required to use Vulkan without linking the Vulkan loader.
Additionally, volk simplifies the use of Vulkan extensions by automatically
loading all associated entrypoints.  Finally, volk enables loading Vulkan
entrypoints directly from the driver which can increase performance by
skipping loader dispatch overhead.")
    (home-page "https://github.com/zeux/volk")
    (license license:expat)))

(define-public vulkan-memory-allocator
  (package
    (name "vulkan-memory-allocator")
    (version "3.0.1")
    (source
     (origin
       (method git-fetch)
       (uri
        (git-reference
         (url "https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator")
         (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1hpzjwl5bgqv9hmf1fdldihfllcbdg515f391a200klg0rnixdds"))))
    (build-system cmake-build-system)
    (arguments
     ;; no test
     `(#:tests? #f))
    (inputs (list vulkan-loader vulkan-headers))
    (synopsis "Vulkan memory allocation library")
    (description
     "The Vulkan Memory Allocator (VMA) library provides a simple and easy to
integrate API to help users allocate memory for Vulkan buffer and image
storage.")
    (home-page
     "https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator")
    (license license:expat)))
