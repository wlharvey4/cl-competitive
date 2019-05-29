(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../ext-gcd.lisp"))

(use-package :test-util)

(with-test (:name mod-log)
  (dotimes (i 100)
    (let ((a (- (random 20) 10))
          (b (- (random 20) 10)))
      (multiple-value-bind (x y) (ext-gcd a b)
        (assert (= (+ (* a x) (* b y)) (gcd a b))))))
  (assert (= 8 (mod-log 6 4 44)))
  (assert (= 8 (mod-log -38 -40 44)))
  (assert (null (mod-log 6 2 44)))
  (assert (= 2 (mod-log 8 4 12)))
  (assert (= 4 (mod-log 3 13 17)))
  (assert (= 1 (mod-log 12 0 4)))
  (assert (= 2 (mod-log 12 0 8)))
  (assert (null (mod-log 12 1 8)))
  (assert (= 1 (mod-log 0 0 100))))

(with-test (:name mod-inverse)
  (dotimes (i 1000)
    (let ((a (random 100))
          (m (+ 2 (random 100))))
      (assert (or (/= 1 (gcd a m))
                  (= 1 (mod (* a (mod-inverse a m)) m)))))))

(with-test (:name solve-bezout)
  (assert (= (calc-min-factor 8 3) -2))
  (assert (= (calc-min-factor -8 3) 3))
  (assert (= (calc-min-factor 8 -3) 2))
  (assert (= (calc-min-factor -8 -3) -3))
  (assert (= (calc-max-factor 8 3) -3))
  (assert (= (calc-max-factor -8 3) 2))
  (assert (= (calc-max-factor 8 -3) 3))
  (assert (= (calc-max-factor -8 -3) -2)))

(with-test (:name mod-echelon)
  (assert (equalp #2a((1 0 1000000005 1000000004) (0 1 1 4) (0 0 0 0))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((1 3 1 9) (1 1 -1 1) (3 11 5 35))) 1000000007)))
  (assert (= 2 (nth-value 1 (mod-echelon! #2a((1 3 1 9) (1 1 -1 1) (3 11 5 35)) 1000000007))))
  (assert (equalp #2a((1 0 1000000005 0) (0 1 1 0) (0 0 0 1))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((1 3 1 9) (1 1 -1 1) (3 11 5 37))) 1000000007)))
  (assert (= 3 (nth-value 1 (mod-echelon! #2a((1 3 1 9) (1 1 -1 1) (3 11 5 37)) 1000000007))))
  ;; extended
  (assert (equalp #2a((1 0 1000000005 1000000004) (0 1 1 4) (0 0 0 1))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((1 3 1 9) (1 1 -1 1) (3 11 5 36))) 1000000007 t)))
  (assert (= 2 (nth-value 1 (mod-echelon! #2a((1 3 1 9) (1 1 -1 1) (3 11 5 36)) 1000000007 t))))
  (assert (equalp #2a((1 0 0 4) (0 1 0 3) (0 0 1 0))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((3 1 4 1) (5 2 6 5) (0 5 2 1))) 7 t))))

(with-test (:name mod-inverse-matrix)
  (assert (equalp #2a((1 0 0) (0 1 0) (0 0 1)) (mod-inverse-matrix! #2a((1 0 0) (0 1 0) (0 0 1)) 7)))
  (assert (equalp #2a((0 0 1) (0 1 0) (1 0 0)) (mod-inverse-matrix! #2a((0 0 1) (0 1 0) (1 0 0)) 7)))
  (assert (null (mod-inverse-matrix! #2a((0 0 1) (1 1 1) (1 1 1)) 7))))
