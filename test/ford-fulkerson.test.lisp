(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../ford-fulkerson.lisp"))

(use-package :test-util)

(with-test (:name ford-fulkerson)
  (let ((graph (make-array '(5) :element-type 'list :initial-element nil)))
    (push-edge 0 1 10 graph)
    (push-edge 0 2 2 graph)
    (push-edge 1 2 6 graph)
    (push-edge 1 3 6 graph)
    (push-edge 3 2 3 graph)
    (push-edge 3 4 8 graph)
    (push-edge 2 4 5 graph)
    (assert (= 11 (max-flow! 0 4 graph))))
  ;; Example from https://www.geeksforgeeks.org/max-flow-problem-introduction/
  (let ((graph (make-array 6 :element-type 'list :initial-element nil)))
    (push-edge 0 1 16 graph)
    (push-edge 0 2 13 graph)
    (push-edge 1 2 10 graph)
    (push-edge 2 1 4 graph)
    (push-edge 1 3 12 graph)
    (push-edge 3 2 9 graph)
    (push-edge 2 4 14 graph)
    (push-edge 4 3 7 graph)
    (push-edge 3 5 20 graph)
    (push-edge 4 5 4 graph)
    (assert (= 23 (max-flow! 0 5 graph))))
  (assert (= 0 (max-flow! 0 3 (make-array '(4) :element-type 'list :initial-element nil)))))
