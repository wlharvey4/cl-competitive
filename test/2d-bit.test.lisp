(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../2d-bit.lisp"))

(use-package :test-util)

(with-test (:name 2d-bit)
  (let ((tree (coerce-to-bitree! (make-array '(2 3) :initial-contents '((1 2 3) (4 5 6)))))
        (tree2 (make-array '(2 3) :initial-element 0)))
    (assert (= 1 (bitree-sum tree 1 1)))
    (assert (= 3 (bitree-sum tree 1 2)))
    (assert (= 6 (bitree-sum tree 1 3)))
    (assert (= 5 (bitree-sum tree 2 1)))
    (assert (= 12 (bitree-sum tree 2 2)))
    (assert (= 21 (bitree-sum tree 2 3)))
    (assert (= 0 (bitree-sum tree 0 3)))
    (dotimes (i 2)
      (dotimes (j 3)
        (bitree-update! tree2 i j (aref #2a((1 2 3) (4 5 6)) i j))))
    (assert (equalp tree tree2))))
