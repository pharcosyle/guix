;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2020 Liliana Marie Prikler <liliana.prikler@gmail.com>
;;; Copyright © 2020 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2021 Felix Gruber <felgru@posteo.net>
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

(define-module (gnu packages unicode)
  #:use-module (gnu packages autotools)
  #:use-module (guix git-download)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial))

(define-public libunibreak
  (package
    (name "libunibreak")
    (version "6.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/adah1972/libunibreak")
                    (commit (string-append "libunibreak_"
                              (string-replace-substring version "." "_")))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0mhkbji89cyjg4g1rviyprchxzpv8pmlmqw4m10cvgfjwmpmwa7k"))))
    (build-system gnu-build-system)
    (native-inputs
      (list autoconf-wrapper
            automake
            libtool))
    (arguments
     `(#:parallel-tests? #f)) ; parallel tests cause non-deterministic
                              ; build failures
    (home-page "https://vimgadgets.sourceforge.net/libunibreak/")
    (synopsis "Unicode line breaking and word breaking algorithms")
    (description
     "Libunibreak is an implementation of the line breaking and word
breaking algorithms as described in Unicode Standard Annex 14 and
Unicode Standard Annex 29.  It is designed to be used in a generic text
renderer.")
    (license zlib)))

(define-public ucd
  (package
    (name "ucd")
    (version "15.1.0")
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append "https://www.unicode.org/Public/zipped/" version
                           "/UCD.zip"))
       (sha256
        (base32 "0xv10nkvg6451415imvb0qx72ljp0hv9f8h1sl6509ir0lync76b"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("." "share/ucd/"))))
    (home-page "https://www.unicode.org")
    (synopsis "Unicode Character Database")
    (description
     "The @dfn{Unicode Character Database} (UCD) consists of a number of data
files listing Unicode character properties and related data.  It also includes
test data for conformance to several important Unicode algorithms.")
    (license unicode)))

(define (unicode-emoji-file name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://www.unicode.org/Public/emoji/"
                        version
                        "/emoji-" name ".txt"))
    (sha256 (base32 hash))))

(define-public unicode-emoji
  (package
    (name "unicode-emoji")
    (version "15.1")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (let ((out (string-append %output "/share/unicode/emoji")))
         (use-modules (guix build utils))
         (mkdir-p out)
         (for-each
          (lambda (input)
            (copy-file
             (cdr input)
             (string-append out "/"
                            (substring (car input) 8) ; strip "unicode-"
                            ".txt")))
          %build-inputs)
         #t)))
    (inputs
     `(("unicode-emoji-sequences"
        ,(unicode-emoji-file
          "sequences" version
          "1lahs35c3dqpai22yvn5ri31livrz0cvc8c63jzgn11mbq8wjwpb"))
       ("unicode-emoji-test"
        ,(unicode-emoji-file
          "test" version
          "1nby2gl5wffhcpa8i91a0qxx3a2751qampx6rxvam3m2k8jfwxnq"))
       ("unicode-emoji-zwj-sequences"
        ,(unicode-emoji-file
          "zwj-sequences" version
          "0mqfzcz1ka78jjk8gk6bfywq4ldmj26rri08zsdqzkfgr8ys0xls"))))
    (home-page "https://www.unicode.org")
    (synopsis "Unicode Emoji data")
    (description
     "This package includes data files listing characters and sequences, that
Unicode emoji supporting fonts or keyboards should support according to the
Unicode Technological Standard #51.")
    (license unicode)))

(define-public unicode-cldr-common
  (package
    (name "unicode-cldr-common")
    (version "45.0")
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append "https://unicode.org/Public/cldr/"
                           (version-major version)
                           "/cldr-common-" version ".zip"))
       (sha256
        (base32
         "07x2jjlc061ljy7nwsmrlcas0rsnal97xajlxf2kyqpwqlp7idh3"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("common" "share/unicode/cldr/"))))
    (home-page "https://www.unicode.org")
    (synopsis "Locale data repository")
    (description
     "The Unicode Common Locale Data Repository (CLDR) is a large repository
of locale data, including among others

@itemize
@item patterns for formatting and parsing,
@item name translations,
@item and various information on languages, scripts and country-specific
  conventions.
@end itemize\n")
    (license unicode)))
