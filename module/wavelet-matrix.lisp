;;;
;;; Wavelet matrix
;;;

(defpackage :cp/wavelet-matrix
  (:use :cl :cp/compact-bit-vector)
  (:export #:wavelet-integer #:wavelet-matrix #:invalid-wavelet-index-error
           #:make-wavelet-matrix #:wavelet-ref #:wavelet-count
           #:wavelet-zeros #:wavelet-data #:wavelet-length #:wavelet-depth
           #:wavelet-range-count #:wavelet-map-frequency #:wavelet-kth-smallest #:wavelet-kth-largest))
(in-package :cp/wavelet-matrix)

(deftype wavelet-integer () '(integer 0 #.most-positive-fixnum))

(defstruct (wavelet-matrix (:constructor %make-wavelet-matrix
                               (length data zeros
                                &aux (depth (array-dimension data 0))))
                           (:copier nil)
                           (:conc-name wavelet-))
  (depth 0 :type (integer 1 #.most-positive-fixnum))
  (length 0 :type (integer 0 #.most-positive-fixnum))
  (data nil :type (simple-array compact-bit-vector (*)))
  (zeros nil :type (simple-array (integer 0 #.most-positive-fixnum) (*))))

#+sbcl
(eval-when (:compile-toplevel :load-toplevel :execute)
  (sb-c:defknown make-wavelet-matrix ((integer 1 #.most-positive-fixnum) vector)
      wavelet-matrix (sb-c:flushable)
    :overwrite-fndb-silently t))

;; TODO: add deftransform for better type derivation
(defun make-wavelet-matrix (bit-depth vector)
  (declare ((integer 1 #.most-positive-fixnum) bit-depth))
  (let* ((len (length vector))
         (fitted-len (* sb-vm:n-word-bits (ceiling len sb-vm:n-word-bits)))
         (data (locally (declare #+sbcl (sb-ext:muffle-conditions style-warning))
                 (make-array bit-depth :element-type 'compact-bit-vector)))
         (zeros (make-array bit-depth :element-type '(integer 0 #.most-positive-fixnum)))
         (tmp (copy-seq vector))
         (lefts (make-array len :element-type (array-element-type vector)))
         (rights (make-array len :element-type (array-element-type vector)))
         (bits (make-array fitted-len :element-type 'bit)))
    (declare ((integer 0 #.most-positive-fixnum) len fitted-len)
             (vector tmp))
    (loop for d from (- bit-depth 1) downto 0
          do (let ((lpos 0)
                   (rpos 0))
               (declare ((integer 0 #.most-positive-fixnum) lpos rpos))
               (dotimes (i len)
                 (let ((bit (logand 1 (ash (aref tmp i) (- d)))))
                   (if (zerop bit)
                       (setf (aref lefts lpos) (aref tmp i)
                             lpos (+ lpos 1))
                       (setf (aref rights rpos) (aref tmp i)
                             rpos (+ rpos 1)))
                   (setf (aref bits i) bit)))
               (setf (aref data d) (make-compact-bit-vector! (copy-seq bits))
                     (aref zeros d) lpos)
               (rotatef lefts tmp)
               (replace tmp rights :start1 lpos :end2 rpos)))
    (%make-wavelet-matrix len data zeros)))

(define-condition invalid-wavelet-index-error (type-error)
  ((wavelet :initarg :wavelet :reader invalid-wavelet-index-error-wavelet)
   (index :initarg :index :reader invalid-wavelet-index-error-index))
  (:report
   (lambda (condition stream)
     (let ((index (invalid-wavelet-index-error-index condition)))
       (if (consp index)
           (format stream "Invalid range [~W, ~W) for wavelet-matrix ~W."
                   (car index)
                   (cdr index)
                   (invalid-wavelet-index-error-wavelet condition))
           (format stream "Invalid index ~W for wavelet-matrix ~W."
                   index
                   (invalid-wavelet-index-error-wavelet condition)))))))

(defun wavelet-ref (wmatrix index)
  "Returns the value at INDEX."
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) index))
  (let ((depth (wavelet-depth wmatrix))
        (data (wavelet-data wmatrix))
        (zeros (wavelet-zeros wmatrix))
        (res 0))
    (declare (wavelet-integer res))
    (when (>= index (wavelet-length wmatrix))
      (error 'invalid-wavelet-index-error :index index :wavelet wmatrix))
    (loop for d from (- depth 1) downto 0
          for sbv = (aref data d)
          for bit = (cbv-ref sbv index)
          do (setq res (logior bit (ash res 1))
                   index (+ (cbv-count sbv bit index)
                            (* bit (aref zeros d)))))
    res))

(defun wavelet-count (wmatrix value l r)
  "Returns the number of VALUE in [L, R)"
  (declare (optimize (speed 3))
           (wavelet-integer value)
           ((integer 0 #.most-positive-fixnum) l r))
  (let ((depth (wavelet-depth wmatrix))
        (data (wavelet-data wmatrix))
        (zeros (wavelet-zeros wmatrix)))
    (unless (<= l r (wavelet-length wmatrix))
      (error 'invalid-wavelet-index-error :index (cons l r) :wavelet wmatrix))
    (loop for d from (- depth 1) downto 0
          for bit = (logand 1 (ash value (- d)))
          do (setq l (+ (cbv-count (aref data d) bit l)
                        (* bit (aref zeros d)))
                   r (+ (cbv-count (aref data d) bit r)
                        (* bit (aref zeros d)))))
    (- r l)))

(defun wavelet-kth-smallest (wmatrix k &optional (start 0) end)
  "Returns the (0-based) K-th smallest number of WMATRIX in the range [START,
END). Returns 2^<bit depth>-1 if K is equal to END - START."
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) k start)
           ((or null (integer 0 #.most-positive-fixnum)) end))
  (let ((depth (wavelet-depth wmatrix))
        (end (or end (wavelet-length wmatrix)))
        (data (wavelet-data wmatrix))
        (zeros (wavelet-zeros wmatrix))
        (result 0))
    (declare (wavelet-integer result)
             ((integer 0 #.most-positive-fixnum) end))
    (when (< (- end start) k)
      (error "The range [~D, ~D) contains less than ~D elements" start end k))
    (loop for d from (- depth 1) downto 0
          for lcount = (cbv-rank (aref data d) start)
          for rcount = (cbv-rank (aref data d) end)
          for zero-count of-type (integer 0 #.most-positive-fixnum)
             = (- (- end start) (- rcount lcount))
          do (if (<= zero-count k)
                 (setq start (+ lcount (aref zeros d))
                       end (+ rcount (aref zeros d))
                       k (- k zero-count)
                       result (logior result (the wavelet-integer (ash 1 d))))
                 (setq start (- start lcount)
                       end (- end rcount))))
    result))

;; TODO: maybe better to integrate kth-smallest and kth-largest
(defun wavelet-kth-largest (wmatrix k &optional (start 0) end)
  "Returns the (0-based) K-th largest number of WMATRIX in the range [START, END)"
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) k start)
           ((or null (integer 0 #.most-positive-fixnum)) end))
  (let ((depth (wavelet-depth wmatrix))
        (end (or end (wavelet-length wmatrix)))
        (data (wavelet-data wmatrix))
        (zeros (wavelet-zeros wmatrix))
        (result 0))
    (declare (wavelet-integer result)
             ((integer 0 #.most-positive-fixnum) end))
    (when (< (- end start) k)
      (error "The range [~D, ~D) contains less than ~D elements" start end k))
    (loop for d from (- depth 1) downto 0
          for lcount = (cbv-rank (aref data d) start)
          for rcount = (cbv-rank (aref data d) end)
          for one-count of-type (integer 0 #.most-positive-fixnum) = (- rcount lcount)
          do (if (> one-count k)
                 (setq start (+ lcount (aref zeros d))
                       end (+ rcount (aref zeros d))
                       result (logior result (the wavelet-integer (ash 1 d))))
                 (setq k (- k one-count)
                       start (- start lcount)
                       end (- end rcount))))
    result))

(defun wavelet-map-frequency (function wmatrix lo hi &optional (start 0) end)
  "Maps all values within [LO, HI). FUNCTION must take two arguments: value and
its frequency."
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) lo hi start)
           ((or null (integer 0 #.most-positive-fixnum)) end)
           (function function))
  (let ((data (wavelet-data wmatrix))
        (zeros (wavelet-zeros wmatrix))
        (end (or end (wavelet-length wmatrix))))
    (assert (<= lo hi))
    (unless (<= start end (wavelet-length wmatrix))
      (error 'invalid-wavelet-index-error :index (cons start end) :wavelet wmatrix))
    (labels
        ((dfs (depth start end value)
           (declare ((integer 0 #.most-positive-fixnum) start end value)
                    ((integer -1 #.most-positive-fixnum) depth))
           (when (and (< value hi) (< start end))
             (if (= -1 depth)
                 (when (<= lo value)
                   (funcall function value (- end start)))
                 (let* ((next-value (logior value
                                            (the wavelet-integer (ash 1 depth))))
                        (upper-bound (logior next-value
                                             (- (the wavelet-integer (ash 1 depth)) 1))))
                   (when (<= lo upper-bound)
                     (let ((lcount (cbv-rank (aref data depth) start))
                           (rcount (cbv-rank (aref data depth) end)))
                       (dfs (- depth 1)
                            (- start lcount)
                            (- end rcount)
                            value)
                       (dfs (- depth 1)
                            (+ (aref zeros depth) lcount)
                            (+ (aref zeros depth) rcount)
                            next-value))))))))
      (dfs (- (wavelet-depth wmatrix) 1) start end 0))))

(defun wavelet-range-count (wmatrix lo hi &optional (start 0) end)
  "Returns the number of the values within [LO, HI)."
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) lo hi start)
           ((or null (integer 0 #.most-positive-fixnum)) end))
  (let ((data (wavelet-data wmatrix))
        (zeros (wavelet-zeros wmatrix))
        (end (or end (wavelet-length wmatrix))))
    (assert (<= lo hi))
    (unless (<= start end (wavelet-length wmatrix))
      (error 'invalid-wavelet-index-error :index (cons start end) :wavelet wmatrix))
    (labels
        ((dfs (depth start end value)
           (declare ((integer 0 #.most-positive-fixnum) start end value)
                    ((integer -1 #.most-positive-fixnum) depth)
                    #+sbcl (values (integer 0 #.most-positive-fixnum)))
           (cond ((or (= start end)
                      (<= hi value))
                  0)
                 ((= depth -1)
                  (if (< value lo)
                      0
                      (- end start)))
                 (t
                  (let* ((next-value (logior value
                                             (the wavelet-integer (ash 1 depth))))
                         (upper-bound (logior next-value
                                              (- (the wavelet-integer (ash 1 depth)) 1))))
                    (cond ((< upper-bound lo)
                           0)
                          ((and (<= lo value) (< upper-bound hi))
                           (- end start))
                          (t
                           (let ((lcount (cbv-rank (aref data depth) start))
                                 (rcount (cbv-rank (aref data depth) end)))
                             (+ (dfs (- depth 1)
                                     (- start lcount)
                                     (- end rcount)
                                     value)
                                (dfs (- depth 1)
                                     (+ (aref zeros depth) lcount)
                                     (+ (aref zeros depth) rcount)
                                     next-value))))))))))
      (dfs (- (wavelet-depth wmatrix) 1) start end 0))))
