;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2016, 2018, 2022 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2017 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2018 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018 Marius Bakke <mbakke@fastmail.com>
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

(define-module (gnu packages libunistring)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages base))

(define-public libunistring
  (package
   (name "libunistring")
   (version "1.2")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "mirror://gnu/libunistring/libunistring-"
                  version ".tar.xz"))
            (sha256
             (base32
              "0i6wvks6abndxn6bzpfpbjyirg98qh0i16ihl2l1r22asxgdcav3"))))
   (propagated-inputs (libiconv-if-needed))
   (outputs '("out" "static"))
   (build-system gnu-build-system)
   (arguments
    ;; Work around parallel build issue whereby C files may be compiled before
    ;; config.h is built: see <http://hydra.gnu.org/build/59381/nixlog/2/raw> and
    ;; <http://lists.openembedded.org/pipermail/openembedded-core/2012-April/059850.html>.
    (list
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          #$@(if (target-aarch64?)
                 #~((add-after 'unpack 'apply-apple-silicon-patch
                      (lambda _
                        (let ((patch
                               #$(local-file
                                  (search-patch "apple-silicon-gnulib-tests.patch"))))
                          (copy-file patch "the-patch")
                          (substitute* "the-patch"
                            (("gnulib-tests/test-fcntl.c")
                             "tests/test-fcntl.c"))
                          (invoke "patch" "--force" "-p1" "-i" "the-patch")))))
                 #~())
          (add-after 'install 'move-static-library
            (lambda* (#:key outputs #:allow-other-keys)
              (with-directory-excursion (string-append #$output "/lib")
                (install-file "libunistring.a"
                              (string-append #$output:static "/lib"))
                (delete-file "libunistring.a")))))))
   (synopsis "C library for manipulating Unicode strings")
   (description
    "GNU libunistring is a library providing functions to manipulate
Unicode strings and for manipulating C strings according to the Unicode
standard.")
   (home-page "https://www.gnu.org/software/libunistring/")
   (license (list lgpl3+ gpl2+))))
