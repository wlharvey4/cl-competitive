(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../generalized-bit.lisp"))

(use-package :test-util)

(with-test (:name generalized-bit)
  (let ((tree (coerce-to-bitree! (vector 10 2 0 0 1 2 2)))
        (tree2 (coerce-to-bitree! (vector 1 0 0 1))))
    (assert (= 0 (bitree-bisect-left tree -1)))
    (assert (= 0 (bitree-bisect-left tree 0)))
    (assert (= 0 (bitree-bisect-left tree 3)))
    (assert (= 0 (bitree-bisect-left tree 10)))
    (assert (= 1 (bitree-bisect-left tree 11)))
    (assert (= 1 (bitree-bisect-left tree 12)))
    (assert (= 4 (bitree-bisect-left tree 13)))
    (assert (= 5 (bitree-bisect-left tree 14)))
    (assert (= 6 (bitree-bisect-left tree 17)))
    (assert (= 7 (bitree-bisect-left tree 18)))
    (assert (= 7 (bitree-bisect-left tree 200)))
    (assert (= 0 (bitree-bisect-left tree2 0)))
    (assert (= 0 (bitree-bisect-left tree2 1)))
    (assert (= 3 (bitree-bisect-left tree2 2)))
    (assert (= 1 (bitree-sum tree2 3)))
    (assert (= 2 (bitree-sum tree2 4)))
    (assert (= 4 (bitree-bisect-left tree2 30000)))
    (assert (= 0 (bitree-bisect-right tree2 -1)))
    (assert (= 0 (bitree-bisect-right tree2 0)))
    (assert (= 3 (bitree-bisect-right tree2 1)))
    (assert (= 4 (bitree-bisect-right tree2 2)))
    (assert (= 4 (bitree-bisect-right tree2 30000)))))