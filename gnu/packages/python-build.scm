;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015, 2024 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015, 2020, 2023 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Leo Famulari <leo@famulari.name>
;;; Copyright © 2020, 2023 Marius Bakke <marius@gnu.org>
;;; Copyright © 2020 Tanguy Le Carrour <tanguy@bioneland.org>
;;; Copyright © 2018, 2021, 2022, 2023 Maxim Cournoyer <maxim.cournoyer@gmail.com>
;;; Copyright © 2019 Vagrant Cascadian <vagrant@debian.org>
;;; Copyright © 2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2020, 2021, 2022, 2023 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2022 Garek Dyszel <garekdyszel@disroot.org>
;;; Copyright © 2022 Greg Hogan <code@greghogan.com>
;;; Copyright © 2024 David Elsing <david.elsing@posteo.net>
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

(define-module (gnu packages python-build)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system python)
  #:use-module (guix build-system pyproject)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages))

;;; Commentary:
;;;
;;; Python packages to build... Python packages.  Since they are bound to be
;;; relied on by many, their dependencies should be kept minimal, and this
;;; module should not depend on other modules containing Python packages.
;;;
;;; Code:


;;; These are dependencies used by the build systems contained herein; they
;;; feel a bit out of place but are kept here to prevent circular module
;;; dependencies.
(define-public python-pathspec
  (package
    (name "python-pathspec")
    (version "0.12.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pathspec" version))
       (sha256
        (base32
         "04jpkzic8f58z6paq7f3f7fdnlv9l89khv3sqsqk7ax10caxb0m4"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "python" "-m" "unittest")))))))
    (native-inputs
     (list python-flit-core
           python-setuptools))
    (home-page "https://github.com/cpburnz/python-pathspec")
    (synopsis "Utility library for gitignore style pattern matching of file paths")
    (description
     "This package provides a utility library for gitignore style pattern
matching of file paths.")
    (license license:mpl2.0)))

(define-public python-pluggy
  (package
   (name "python-pluggy")
   (version "1.5.0")
   (source
    (origin
     (method url-fetch)
     (uri (pypi-uri "pluggy" version))
     (sha256
      (base32
       "1w8c3mpliqm9biqw75ci8cfj1x5pb6g5zwblqp27ijgxjj7aizrc"))))
   (build-system pyproject-build-system)
   (arguments
    (list #:tests? #f)) ; No tests in the pypi archive.
   (native-inputs (list python-setuptools-scm))
   (synopsis "Plugin and hook calling mechanism for Python")
   (description "Pluggy is an extraction of the plugin manager as used by
Pytest but stripped of Pytest specific details.")
   (home-page "https://pypi.org/project/pluggy/")
   (license license:expat)))

(define-public python-pluggy-next
  (package/inherit python-pluggy
    (name "python-pluggy")
    (version "1.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pluggy" version))
       (sha256
        (base32 "1w8c3mpliqm9biqw75ci8cfj1x5pb6g5zwblqp27ijgxjj7aizrc"))))
    (build-system pyproject-build-system)))

(define-public python-toml
  (package
    (name "python-toml")
    (version "0.10.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "toml" version))
       (sha256
        (base32 "13z6rff86bzdpl094x0vmfvls779931xj90dlbs9kpfm138s3gdk"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f))                     ;no tests suite in release
    (native-inputs
     (list python-setuptools
           python-wheel))
    (home-page "https://github.com/uiri/toml")
    (synopsis "Library for TOML")
    (description
     "@code{toml} is a library for parsing and creating Tom's Obvious, Minimal
Language (TOML) configuration files.")
    (license license:expat)))

(define-public python-tomli-w
  (package
    (name "python-tomli-w")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tomli_w" version))
       (sha256
        (base32 "1fg13bfq5qy1ym4x77815nhxh1xpfs0drhn9r9464cz00m1l6qzl"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))      ;to avoid extra dependencies
    (native-inputs (list python-flit-core))
    (home-page "https://github.com/hukkin/tomli-w")
    (synopsis "Minimal TOML writer")
    (description "Tomli-W is a Python library for writing TOML.  It is a
write-only counterpart to Tomli, which is a read-only TOML parser.")
    (license license:expat)))

(define-public python-pytoml
  (package
    (name "python-pytoml")
    (version "0.1.21")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pytoml" version))
       (sha256
        (base32
         "1rv1byiw82k7mj6aprcrqi2vdabs801y97xhfnrz7kxds34ggv4f"))))
    (build-system python-build-system)
    (home-page "https://github.com/avakar/pytoml")
    (synopsis "Parser for TOML")
    (description "This package provides a Python parser for TOML-0.4.0.")
    (license license:expat)))

(define-public python-tomli
  (package
    (name "python-tomli")
    (version "2.0.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/hukkin/tomli")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1l3s70kd2jwmfmlaw32flsf6dn1fbqh2dy008y76fs08fan4qimz"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "python" "-m" "unittest")))))))
    (native-inputs
     (list python-flit-core))
    (home-page "https://github.com/hukkin/tomli")
    (synopsis "Small and fast TOML parser")
    (description "Tomli is a minimal TOML parser that is fully compatible with
@url{https://toml.io/en/v1.0.0,TOML v1.0.0}.  It is about 2.4 times as fast as
@code{python-toml}.")
    (license license:expat)))

;; TODO: tomli is no longer necessary in Python 3.12 so it should be removed or
;; added only conditionally for earlier Python versions. It's in a lot of
;; places so just replace it with a dummy package for the moment to avoid a
;; bunch of potential merge conflicts.
(define-public python-tomli
  (package
    (name "python-tomli-dummy")
    (version "0")
    (source #f)
    (build-system (@ (guix build-system trivial) trivial-build-system))
    (arguments
     `(#:modules ((guix build utils))
       #:target #f
       #:builder (begin
                   (use-modules (guix build utils))
                   (let* ((out (assoc-ref %outputs "out"))
                          (dummy (string-append out "/dummy")))
                     (mkdir-p out)
                     (call-with-output-file dummy
                       (const #t))))))
    (home-page #f)
    (synopsis #f)
    (description #f)
    (license (license:fsdg-compatible "dummy"))))

(define-public python-trove-classifiers
  (package
    (name "python-trove-classifiers")
    (version "2024.7.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trove_classifiers" version))
              (sha256
               (base32
                "0ddcs14r5diry19d9iv4qnfzi0vsxnh6birppcy7gzg35jng4a43"))))
    (build-system pyproject-build-system)
    (arguments (list #:build-backend "setuptools.build_meta"
                     #:tests? #f))      ;keep dependencies to a minimum
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://github.com/pypa/trove-classifiers")
    (synopsis "Canonical source for classifiers on PyPI")
    (description "This package is the canonical source for classifiers use on
PyPI (pypi.org).")
    (license license:asl2.0)))

(define-public python-typing-extensions
  (package
    (name "python-typing-extensions")
    (version "4.12.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "typing_extensions" version))
              (sha256
               (base32
                "1f7z47hmz48kgixzb3ffw6zml8j1iflf6ml8xr6xsng5qxasszhs"))))
    (build-system pyproject-build-system)
    ;; Disable the test suite to keep the dependencies to a minimum.  Also,
    ;; the test suite requires Python's test module, not available in Guix.
    (arguments (list #:tests? #f))
    (native-inputs (list python-flit-core))
    (home-page "https://github.com/python/typing_extensions")
    (synopsis "Experimental type hints for Python")
    (description
     "The typing_extensions module contains additional @code{typing} hints not
yet present in the of the @code{typing} standard library.
Included are implementations of:
@enumerate
@item ClassVar
@item ContextManager
@item Counter
@item DefaultDict
@item Deque
@item NewType
@item NoReturn
@item overload
@item Protocol
@item runtime
@item Text
@item Type
@item TYPE_CHECKING
@item AsyncGenerator
@end enumerate\n")
    (license license:psfl)))

(define-public python-typing-extensions-4.10
  (package
    (inherit python-typing-extensions)
    (version "4.10.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "typing_extensions" version))
       (sha256
        (base32
         "1jxkj4pni8pdyrn79sq441lsp40xzw363n0qvfc6zfcgkv4dgaxh"))))))


;;;
;;; Python builder packages.
;;;
(define-public python-pip
  (package
    (name "python-pip")
    (version "23.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pip" version))
       (sha256
        (base32
         "0jnk639v9h7ghslm4jnlic6rj3v29nygflx1hgxxndg5gs4kk1a0"))
       (snippet
        #~(begin
            (delete-file "src/pip/_vendor/certifi/cacert.pem")
            (delete-file "src/pip/_vendor/certifi/core.py")
            (with-output-to-file "src/pip/_vendor/certifi/core.py"
              (lambda _
                (display "\"\"\"
certifi.py
~~~~~~~~~~
This file is a Guix-specific version of core.py.

This module returns the installation location of SSL_CERT_FILE or
/etc/ssl/certs/ca-certificates.crt, or its contents.
\"\"\"
import os

_CA_CERTS = None

try:
    _CA_CERTS = os.environ [\"SSL_CERT_FILE\"]
except:
    _CA_CERTS = os.path.join(\"/etc\", \"ssl\", \"certs\", \"ca-certificates.crt\")

def where() -> str:
    return _CA_CERTS

def contents() -> str:
    with open(where(), \"r\", encoding=\"ascii\") as data:
        return data.read()")))))))
    (build-system python-build-system)
    (arguments
     '(#:tests? #f))          ; there are no tests in the pypi archive.
    (home-page "https://pip.pypa.io/")
    (synopsis "Package manager for Python software")
    (description
     "Pip is a package manager for Python software, that finds packages on the
Python Package Index (PyPI).")
    (license license:expat)))

(define-public python-setuptools
  (package
    (name "python-setuptools")
    (version "72.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "setuptools" version))
       (sha256
        (base32
         "1v32n59aw1fccwc983rfaj7jfh99wdmdwvkrgy0yb5fhavzkw94d"))
       (modules '((guix build utils)))
       (snippet
        ;; TODO: setuptools now bundles the following libraries:
        ;; packaging, pyparsing, six and appdirs.  How to unbundle?
        ;; Remove included binaries which are used to build self-extracting
        ;; installers for Windows.
        '(for-each delete-file (find-files "setuptools"
                                           "^(cli|gui).*\\.exe$")))))
    (build-system pyproject-build-system)
    (native-inputs
     (list python-wheel))
    ;; FIXME: Tests require pytest, which itself relies on setuptools.
    ;; One could bootstrap with an internal untested setuptools.
    (arguments (list #:tests? #f))
    (home-page "https://pypi.org/project/setuptools/")
    (synopsis "Library designed to facilitate packaging Python projects")
    (description "Setuptools is a fully-featured, stable library designed to
facilitate packaging Python projects, where packaging includes:
@itemize
@item Python package and module definitions
@item distribution package metadata
@item test hooks
@item project installation
@item platform-specific details.
@end itemize")
    (license (list license:psfl         ;setuptools itself
                   license:expat        ;six, appdirs, pyparsing
                   license:asl2.0       ;packaging is dual ASL2/BSD-2
                   license:bsd-2))))

;; This is the last version with use_2to3 support.
(define-public python-setuptools-57
  (package
    (inherit python-setuptools)
    (version "57.5.0")
    (source (origin
              (inherit (package-source python-setuptools))
              (uri (pypi-uri "setuptools" version))
              (sha256
               (base32
                "091sp8lrin7qllrhhx7y0iiv5gdb1d3l8a1ip5knk77ma1njdlyr"))))))

(define-public python-wheel
  (package
    (name "python-wheel")
    (version "0.43.0")
    (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "wheel" version))
        (sha256
         (base32
          "118x5y37152by7f8gvzwda441jd8b42w92ngs6i5sp7sd4ngjpj6"))))
    (build-system pyproject-build-system)
    (native-inputs
     (list python-flit-core))
    (arguments
     '(#:tests? #f))
    (home-page "https://github.com/pypa/wheel")
    (synopsis "Format for built Python packages")
    (description
     "A wheel is a ZIP-format archive with a specially formatted filename and
the @code{.whl} extension.  It is designed to contain all the files for a PEP
376 compatible install in a way that is very close to the on-disk format.  Many
packages will be properly installed with only the @code{Unpack} step and the
unpacked archive preserves enough information to @code{Spread} (copy data and
scripts to their final locations) at any later time.  Wheel files can be
installed with a newer @code{pip} or with wheel's own command line utility.")
    (license license:expat)))

(define-public python-pyparsing
  (package
    (name "python-pyparsing")
    (version "3.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pyparsing" version))
       (sha256
        (base32 "1bcl1x123xj3wl6jghcl9jnmd1ipr79r9jkqxp1yqm8iav7c1fm1"))))
    (build-system pyproject-build-system)
    (outputs '("out" "doc"))
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'install-doc
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((doc (string-append (assoc-ref outputs "doc")
                                        "/share/doc/" ,name "-" ,version))
                    (html-doc (string-append doc "/html"))
                    (examples (string-append doc "/examples")))
               (mkdir-p html-doc)
               (mkdir-p examples)
               (for-each
                (lambda (dir tgt)
                  (map (lambda (file)
                         (install-file file tgt))
                       (find-files dir ".*")))
                (list "docs" "htmldoc" "examples")
                (list doc html-doc examples))))))))
    (native-inputs
     (list python-flit-core))
    (home-page "https://github.com/pyparsing/pyparsing")
    (synopsis "Python parsing class library")
    (description
     "The pyparsing module is an alternative approach to creating and
executing simple grammars, vs. the traditional lex/yacc approach, or the use
of regular expressions.  The pyparsing module provides a library of classes
that client code uses to construct the grammar directly in Python code.")
    (license license:expat)))

;;; This is the last release compatible with Python 2.
(define-public python-pyparsing-2.4.7
  (package
    (inherit python-pyparsing)
    (version "2.4.7")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pyparsing" version))
       (sha256
        (base32 "1hgc8qrbq1ymxbwfbjghv01fm3fbpjwpjwi0bcailxxzhf3yq0y2"))))))

(define-public python-packaging-bootstrap
  (package
    (name "python-packaging-bootstrap")
    (version "24.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "packaging" version))
       (sha256
        (base32
         "00phyhvsrw6dh7lsa46svg8pz4lqhqjp41cmz1dwxz6kiqndfvh2"))))
    (build-system pyproject-build-system)
    (arguments `(#:tests? #f))         ;disabled to avoid extra dependencies
    (native-inputs
     (list python-flit-core))
    (home-page "https://github.com/pypa/packaging")
    (synopsis "Core utilities for Python packages")
    (description "Packaging is a Python module for dealing with Python packages.
It offers an interface for working with package versions, names, and dependency
information.")
    ;; From 'LICENSE': This software is made available under the terms of
    ;; *either* of the licenses found in LICENSE.APACHE or LICENSE.BSD.
    ;; Contributions to this software is made under the terms of *both* these
    ;; licenses.
    (license (list license:asl2.0 license:bsd-2))))

(define-public python-poetry-core-1.0
  (package
    (name "python-poetry-core")
    (version "1.0.7")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "poetry-core" version))
       (sha256
        (base32 "01n2rbsvks7snrq3m1d08r3xz9q2715ajb62fdb6rvqnb9sirhcq"))))
    (build-system python-build-system)
    (home-page "https://github.com/python-poetry/poetry-core")
    (synopsis "Poetry PEP 517 build back-end")
    (description
     "The @code{poetry-core} module provides a PEP 517 build back-end
implementation developed for Poetry.  This project is intended to be
a light weight, fully compliant, self-contained package allowing PEP 517
compatible build front-ends to build Poetry managed projects.")
    (license license:expat)))

(define-public python-poetry-core
  (package
    (name "python-poetry-core")
    (version "1.9.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "poetry_core" version))
       (sha256
        (base32 "18imz7hm6a6n94r2kyaw5rjvs8dk22szwdagx0p5gap8x80l0yps"))))
    (build-system pyproject-build-system)
    (arguments
     `(#:tests? #f))                      ;disabled to avoid extra dependencies
    (home-page "https://github.com/python-poetry/poetry-core")
    (synopsis "Poetry PEP 517 build back-end")
    (description
     "The @code{poetry-core} module provides a PEP 517 build back-end
implementation developed for Poetry.  This project is intended to be
a light weight, fully compliant, self-contained package allowing PEP 517
compatible build front-ends to build Poetry managed projects.")
    (license license:expat)))

(define-public python-flit-core
  (package
    (name "python-flit-core")
    (version "3.9.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "flit" version))
       (sha256
        (base32 "1is410a121m9cv6jaj9qx3p0drjigzwad9kh6paj1ni4ndgdypnp"))))
    (build-system pyproject-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'chdir
           (lambda _
             (chdir "flit_core"))))))
    (home-page "https://github.com/pypa/flit")
    (synopsis "Core package of the Flit Python build system")
    (description "This package provides @code{flit-core}, a PEP 517 build
backend for packages using Flit.  The only public interface is the API
specified by PEP 517, @code{flit_core.buildapi}.")
    (license license:bsd-3)))

(define-public python-flit-scm
  (package
    (name "python-flit-scm")
    (version "1.7.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "flit_scm" version))
              (sha256
               (base32
                "1ckbkykfr7f7wzjzgh0gm7h6v3pqzx2l28rw6dsvl6zk4kxxc6wn"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f        ;to avoid extra dependencies
                     ;; flit-scm wants to use flit-core, which it renames to
                     ;; 'buildapi', but that isn't found even when adding the
                     ;; current directory to PYTHONPATH.  Use setuptools'
                     ;; builder instead.
                     #:build-backend "setuptools.build_meta"))
    (propagated-inputs (list python-flit-core python-setuptools-scm python-tomli))
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://gitlab.com/WillDaSilva/flit_scm")
    (synopsis "PEP 518 build backend combining flit_core and setuptools_scm")
    (description "This package provides a PEP 518 build backend that uses
@code{setuptools_scm} to generate a version file from your version control
system, then @code{flit_core} to build the package.")
    (license license:expat)))

(define-public python-setuptools-scm
  (package
    (name "python-setuptools-scm")
    (version "8.1.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "setuptools_scm" version))
              (sha256
               (base32 "19y84rzqwb2rd88bjrlafrhfail2bnk6apaig8xskjviayva3pj2"))))
    (build-system pyproject-build-system)
    (arguments (list #:build-backend "setuptools.build_meta"
                     #:tests? #f))    ;avoid extra dependencies such as pytest
    (propagated-inputs (list python-packaging-bootstrap
                             python-setuptools
                             python-tomli
                             python-typing-extensions))
    (home-page "https://github.com/pypa/setuptools_scm/")
    (synopsis "Manage Python package versions in SCM metadata")
    (description
     "Setuptools_scm handles managing your Python package versions in
@dfn{software configuration management} (SCM) metadata instead of declaring
them as the version argument or in a SCM managed file.")
    (license license:expat)))

(define-public python-editables
  (package
    (name "python-editables")
    (version "0.5")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/pfmoore/editables")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1bp959fz987jvrnkilhyr41fw4g00g9jfyiwmfvy96hv1yl68w8b"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (native-inputs
     (list python-flit-core))
    (home-page "https://github.com/pfmoore/editables")
    (synopsis "Editable installations")
    (description "This library supports the building of wheels which, when
installed, will expose packages in a local directory on @code{sys.path} in
``editable mode''.  In other words, changes to the package source will be
reflected in the package visible to Python, without needing a reinstall.")
    (license license:expat)))

(define-public python-hatchling
  (package
    (name "python-hatchling")
    (version "1.25.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "hatchling" version))
              (sha256
               (base32
                "0qj29z3zckbk5svvfkhw8g8xcl8mv0dzzlx4a0iba416a4d66r3h"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))                  ;to keep dependencies to a minimum
    (propagated-inputs (list python-editables
                             python-packaging-bootstrap
                             python-pathspec
                             python-pluggy
                             python-tomli
                             python-trove-classifiers))
    (home-page "https://hatch.pypa.io/latest/")
    (synopsis "Modern, extensible Python build backend")
    (description "Hatch is a modern, extensible Python project manager.  It
has features such as:
@itemize
@item Standardized build system with reproducible builds by default
@item Robust environment management with support for custom scripts
@item Easy publishing to PyPI or other indexes
@item Version management
@item Configurable project generation with sane defaults
@item Responsive CLI, ~2-3x faster than equivalent tools.
@end itemize")
    (license license:expat)))

(define-public python-hatch-fancy-pypi-readme
  (package
    (name "python-hatch-fancy-pypi-readme")
    (version "22.8.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "hatch_fancy_pypi_readme" version))
              (sha256
               (base32
                "0sn2wsfbpsbf2mqhjvw62h1cfy5mz3d7iqyqvs5c20cnl0n2i4fs"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))      ;avoid extra test dependencies
    (propagated-inputs (list python-hatchling python-tomli
                             python-typing-extensions))
    (home-page "https://github.com/hynek/hatch-fancy-pypi-readme")
    (synopsis "Fancy PyPI READMEs with Hatch")
    (description "This hatch plugin allows defining a project description in
terms of concatenated fragments that are based on static strings, files and
parts of files defined using cut-off points or regular expressions.")
    (license license:expat)))

(define-public python-hatch-vcs
  (package
    (name "python-hatch-vcs")
    (version "0.4.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "hatch_vcs" version))
              (sha256
               (base32
                "1xyr0wdiq2q9czlyvm1jsbpwm216mk0z5g7sa7ab07g0ixs10f09"))))
    (arguments (list #:tests? #f))      ;avoid extra test dependencies
    (build-system pyproject-build-system)
    (propagated-inputs (list python-hatchling python-setuptools-scm))
    (home-page "https://github.com/ofek/hatch-vcs")
    (synopsis "Hatch plugin for versioning with your preferred VCS")
    (description "This package is a plugin for Hatch that uses your preferred
version control system (like Git) to determine project versions.")
    (license license:expat)))

(define-public python-pdm-backend
  (package
    (name "python-pdm-backend")
    (version "2.0.6")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "pdm_backend" version))
              (sha256
               (base32
                "06bq846yy33alxbljgcf4lx9g2mx4b2sv04i59rrn9rxapcg2651"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f)) ; Depends on pytest, which we cannot import into this module.
    (home-page "https://pdm-backend.fming.dev/")
    (synopsis
     "PEP 517 build backend for PDM")
    (description
     "PDM-Backend is a build backend that supports the latest packaging
standards, which includes PEP 517, PEP 621 and PEP 660.")
    (license license:expat)))

