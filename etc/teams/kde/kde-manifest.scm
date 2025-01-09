;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2025 Zheng Junjie <873216071@qq.com>
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
;;; Commentary:
;;;
;;; Code:

(use-modules (guix packages)
             (guix profiles)
             (srfi srfi-1)
             (srfi srfi-2))

(manifest
 (map package->manifest-entry
      (fold-packages
       (lambda (package lst)
         (if (or (and-let* ((uri (and=> (package-source package)
                                        (lambda (x)
                                          (and (origin? x)
                                               (origin-uri x)))))
                            ((string? uri)))
                   (string-prefix? "mirror://kde/" uri))
                 (any
                  (lambda (pkg)
                    (string=? "extra-cmake-modules" (first pkg)))
                  (append (package-native-inputs package)
                          (package-propagated-inputs package)
                          (package-inputs package))))
             (cons package lst)
             lst))
       (list))))
