;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015, 2016, 2021 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2019, 2020 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2024 Efraim Flashner <efraim@flashner.co.il>
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

(define-module (gnu packages netpbm)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages image)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:select (gpl2))
  #:use-module (guix packages)
  #:use-module (guix svn-download)
  #:use-module (guix utils))

(define-public netpbm
  (package
   (name "netpbm")
   (version "11.7.0")
   (source (origin
            (method svn-fetch)
            ;; At the time of first packaging, the "super-stable" and
            ;; "stable" versions did not compile with newer libpng;
            ;; we needed the "advanced" version.
            ;; The currently highest stable version is 10.47.53,
            ;; the currently highest advanced version is 10.69.4,
            ;; svn release 2397.
            ;; To determine the correct release: "svn log version.mk".
            (uri (svn-reference
                   (url "http://svn.code.sf.net/p/netpbm/code/advanced")
                   (revision 4928)))
            (sha256
              (base32
               "1jb2h55igay6dyrmf1qzwxkh4zsglbbygq9052jjl85xgbv3zak3"))
            (patches (search-patches "netpbm-CVE-2017-2586.patch"
                                     "netpbm-CVE-2017-2587.patch"))
            (file-name (string-append name "-" version "-checkout"))
            (modules '((guix build utils)))
            (snippet
             '(begin
                ;; Remove non-FSDG-compliant code.

                (define-syntax drop
                  (syntax-rules (in)
                    ;; Remove PROGRAM from DIRECTORY/Makefile, and remove
                    ;; DIRECTORY/PROGRAM and DIRECTORY/PROGRAM.c.
                    ((_ program ... in directory)
                     (begin
                       (substitute* (string-append directory "/Makefile")
                         ((program) "") ...)

                       (let* ((subdir (string-append directory "/" program))
                              (dot-c  (string-append subdir ".c")))
                         (when (file-exists? subdir)
                           (delete-file-recursively subdir))
                         (when (file-exists? dot-c)
                           (delete-file dot-c)))

                       ...))))

                ;; Drop advertisement for non-free program.
                (drop "hpcdtoppm" in "converter/ppm")

                ;; Drop programs without a license, see
                ;; <http://packages.debian.org/changelogs/pool/main/n/netpbm-free/netpbm-free_10.0-12.2/libnetpbm10.copyright>.
                (drop "pbmto4425" "pbmtoln03" "pbmtolps" "pbmtopk" "pktopbm"
                      in "converter/pbm")
                (drop "spottopgm" in "converter/pgm")
                (drop "ppmtopjxl" in "converter/ppm")

                ;; Remove timestamps from the generated code.
                (substitute* "buildtools/makepointerman"
                  (("gmctime[(][)]")
                   "\"Thu Jan 1 00:00:00 1970\""))
                (substitute* "buildtools/stamp-date"
                  (("^DATE=.*")
                   "DATE=\"Thu Jan 01 00:00:00+0000 1970\"\n")
                  (("^USER=.*")
                   "USER=Guix\n"))
                #t))))

   (build-system gnu-build-system)
   (inputs `(("ghostscript" ,ghostscript)
             ("libjpeg" ,libjpeg-turbo)
             ("libpng" ,libpng)
             ("libtiff" ,libtiff)
             ("libxml2" ,libxml2)
             ("xorg-rgb" ,xorg-rgb)
             ("zlib" ,zlib)))
   (native-inputs
     `(("flex" ,flex)
       ("perl" ,perl)
       ("pkg-config" ,pkg-config)
       ("python" ,python-wrapper)))
   (arguments
    `(#:modules ((guix build gnu-build-system)
                 (guix build utils)
                 (ice-9 match))
      #:phases
      (modify-phases %standard-phases
       (replace 'configure
         (lambda* (#:key inputs outputs #:allow-other-keys)
           (copy-file "config.mk.in" "config.mk")
           (chmod "config.mk" #o664)
           (let ((f (open-file "config.mk" "a")))
             (display "CC=gcc\n" f)
             (display "CFLAGS_SHLIB += -fPIC\n" f)
             (display "TIFFLIB = libtiff.so\n" f)
             (display "JPEGLIB = libjpeg.so\n" f)
             (display "ZLIB = libz.so\n" f)
             (display (string-append "LDFLAGS += -Wl,-rpath=" %output "/lib") f)
             (close-port f))

           (let ((rgb (search-input-file inputs "/share/X11/rgb.txt")))
             (substitute* "config.mk"
               (("/usr/share/netpbm/rgb.txt") rgb))

             ;; Our Ghostscript no longer provides the 'gs' command, only
             ;; 'gsc', so look for that instead.
             (substitute* "converter/other/pstopnm.c"
               (("\"%s/gs\"")
                "\"%s/gsc\"")
               (("/usr/bin/gs")
                (search-input-file inputs "/bin/gsc"))))))
       (add-before 'check 'setup-check
         (lambda _
           ;; install temporarily into /tmp/netpbm
           (invoke "make" "package")
           ;; remove test requiring X
           (substitute* "test/all-in-place.test" (("pamx") ""))
           ;; do not worry about non-existing file
           (substitute* "test/all-in-place.test" (("^rm ") "rm -f "))

           (substitute* "test/Test-Order"
             ;; remove four tests that fail for unknown reasons.
             (("all-in-place.test") "")
             (("pnmpsnr.test") "")
             (("pnmremap1.test") "")
             (("pnmindex.test") "")

             ;; These two tests fail on powerpc-linux.
             ,@(if (target-ppc32?)
                   `((("pbmtog3\\.test") "")
                     (("g3-roundtrip\\.test") ""))
                   '())

             ;; Started failing in netpbm-10.78.3.
             (("pbmtext.test") "")

             ;; Skip tests that use nonfree programs that we don't build.
             (("ps-alt-roundtrip.test") "" )
             (("pbm-misc-converters.test") "")
             (("lps-roundtrip.test") ""))
           #t))
       (replace 'install
         (lambda* (#:key outputs make-flags #:allow-other-keys)
           (let ((out (assoc-ref outputs "out")))
             (apply invoke "make" "package"
                    (string-append "pkgdir=" out) make-flags)
             ;; Remove superfluous files.
             (with-directory-excursion out
               (for-each delete-file-recursively
                         '("config_template" "pkginfo" "README" "VERSION"
                           "sharedlink/" "staticlink/" "misc/"))
               ;; Install the required ‘libnetpbm.so’ link.
               ;; See <https://issues.guix.gnu.org/issue/40376>.
               (with-directory-excursion "lib"
                 (symlink
                  (match (find-files "." "^libnetpbm\\.so\\.[^.]*\\.[^.]*$")
                         ((head _ ...) head))
                  "libnetpbm.so"))
               #t)))))))
   (synopsis "Toolkit for manipulation of images")
   (description
    "Netpbm is a toolkit for the manipulation of graphic images, including
the conversion of images between a variety of different formats.
There are over 300 separate tools in the package including converters for
about 100 graphics formats.")
   (license gpl2)
   (home-page "https://netpbm.sourceforge.net/")))
