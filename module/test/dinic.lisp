(defpackage :cp/test/dinic
  (:use :cl :fiveam :cp/dinic :cp/max-flow)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/dinic)
(in-suite base-suite)

(test dinic
  (let ((graph (make-array 2 :element-type 'list :initial-element nil)))
    (add-edge graph 0 1 10)
    (is (= 10 (max-flow! graph 0 1)))
    (is (= 0 (edge-capacity (car (aref graph 0)))))
    (is (= 10 (edge-default-capacity (car (aref graph 0)))))
    (is (= 10 (edge-capacity (car (aref graph 1)))))
    (is (= 0 (edge-default-capacity (car (aref graph 1))))))
  (let ((graph (make-array '(5) :element-type 'list :initial-element nil)))
    (add-edge graph 0 1 10)
    (add-edge graph 0 2 2)
    (add-edge graph 1 2 6)
    (add-edge graph 1 3 6)
    (add-edge graph 3 2 3)
    (add-edge graph 3 4 8)
    (add-edge graph 2 4 5)
    (is (= 11 (max-flow! graph 0 4)))
    (is (= 0 (max-flow! graph 0 4)))
    (reinitialize-flow-network graph)
    (is (= 11 (max-flow! graph 0 4))))
  ;; Example from https://www.geeksforgeeks.org/max-flow-problem-introduction/
  (let ((graph (make-array 6 :element-type 'list :initial-element nil)))
    (add-edge graph 0 1 16)
    (add-edge graph 0 2 13)
    (add-edge graph 1 2 10)
    (add-edge graph 2 1 4)
    (add-edge graph 1 3 12)
    (add-edge graph 3 2 9)
    (add-edge graph 2 4 14)
    (add-edge graph 4 3 7)
    (add-edge graph 3 5 20)
    (add-edge graph 4 5 4)
    (is (= 23 (max-flow! graph 0 5))))
  (is (= 0 (max-flow! (make-array '(4) :element-type 'list :initial-element nil) 0 3)))
  (signals max-flow-overflow (max-flow! (make-array '(4) :element-type 'list :initial-element nil) 0 0)))
