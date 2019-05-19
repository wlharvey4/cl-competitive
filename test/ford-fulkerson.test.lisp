(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util.lisp")
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
    (assert (= 11 (max-flow 0 4 graph)))))

(quit-with-test-result)
