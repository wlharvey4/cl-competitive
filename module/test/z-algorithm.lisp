(defpackage :cp/test/z-algorithm
  (:use :cl :fiveam :cp/z-algorithm)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/z-algorithm)
(in-suite base-suite)

(test z-algorithm
  (is (equalp #() (make-z-array "")))
  (is (equalp #(1) (make-z-array "a")))
  (is (equalp #(4 3 2 1) (make-z-array "aaaa")))
  (is (equalp #(6 0 4 0 2 0) (make-z-array "ababab")))
  (is (equalp #(11 0 0 1 0 1 0 4 0 0 1) (make-z-array "abracadabra"))))
