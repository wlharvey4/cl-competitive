(defpackage :cp/test/symmetric-group
  (:use :cl :fiveam :cp/symmetric-group :cp/test/set-equal)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/symmetric-group)
(in-suite base-suite)

(test cyclic-permutation
  (is (set-equal '((5) (2) (1 4 6 8 3 7) (0))
                     (decompose-to-cycles #(0 4 2 7 6 5 8 1 3))
                     :test #'equal))
  (is (equal '((0)) (decompose-to-cycles #(0))))
  (is (equal nil (decompose-to-cycles #())))
  ;; parity
  (labels ((frob (len)
             (let ((perm (coerce (loop for i below len collect i) 'vector)))
               (dotimes (i 100)
                 (assert (= (logand i 1)
                            (logand (nth-value 1 (decompose-to-cycles perm)) 1)))
                 (let* ((i (random len))
                        (j (random len)))
                   (loop while (= i j)
                         do (setq j (random len)))
                   (rotatef (aref perm i) (aref perm j)))))))
    (finishes (frob 4))
    (finishes (frob 5))
    (finishes (frob 6))))
