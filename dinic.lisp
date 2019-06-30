;;;
;;; Max flow (Dinic's algorithm)
;;;

(setf *print-circle* t)

(defconstant +graph-max-distance+ #xffffffff)

(define-condition max-flow-overflow (simple-error)
  ((graph :initarg :graph :reader max-flow-overflow-graph))
  (:report
   (lambda (condition stream)
     (let ((*print-circle* t))
       (format stream "MOST-POSITIVE-FIXNUM or more units can flow on graph ~W."
               (max-flow-overflow-graph condition))))))

(defstruct (edge (:constructor %make-edge))
  (to nil :type (integer 0 #.most-positive-fixnum))
  (capacity 0 :type (integer 0 #.most-positive-fixnum))
  (reversed nil :type (or null edge)))

(defun push-edge (from-idx to-idx capacity graph &optional bidirectional)
  "FROM-IDX, TO-IDX := index of vertex
GRAPH := vector of lists

If BIDIRECTIONAL is true, PUSH-EDGE adds the reversed edge of the same capacity
in addition."
  (declare (optimize (speed 3))
           ((integer 0 #.most-positive-fixnum) from-idx to-idx)
           ((simple-array list (*)) graph))
  (let* ((dep (%make-edge :to to-idx :capacity capacity))
         (ret (%make-edge :to from-idx
                          :capacity (if bidirectional capacity 0)
                          :reversed dep)))
    (setf (edge-reversed dep) ret)
    (push dep (aref graph from-idx))
    (push ret (aref graph to-idx))))

(defun %fill-dist-table (src graph dist-table queue)
  "Does BFS and sets the distance between SRC and each vertex of GRAPH to
DIST-TABLE, where an edge of zero capacity is regarded as disconnected."
  (declare (optimize (speed 3) (safety 0))
           ((integer 0 #.most-positive-fixnum) src)
           ((simple-array list (*)) graph)
           ((simple-array (unsigned-byte 32) (*)) dist-table queue))
  (let* ((q-front 0)
         (q-end 0))
    (declare ((integer 0 #.most-positive-fixnum) q-front q-end))
    (labels ((enqueue (obj)
               (setf (aref queue q-end) obj)
               (incf q-end))
             (dequeue ()
               (prog1 (aref queue q-front)
                 (incf q-front))))
      (declare (inline enqueue dequeue))
      (fill dist-table +graph-max-distance+)
      (setf (aref dist-table src) 0)
      (enqueue src)
      (loop until (= q-front q-end)
            for vertex = (dequeue)
            do (dolist (edge (aref graph vertex))
                 (let ((neighbor (edge-to edge)))
                   (when (and (> (edge-capacity edge) 0)
                              (= +graph-max-distance+ (aref dist-table neighbor)))
                     (setf (aref dist-table neighbor)
                           (+ 1 (aref dist-table vertex)))
                     (enqueue neighbor)))))))
  dist-table)

(declaim (ftype (function * (values (integer 0 #.most-positive-fixnum) &optional)) %find-path))
(defun %find-path (src dest tmp-graph dist-table)
  "Finds an augmenting path, sends the maximal flow through it, and returns the
amount of the flow."
  (declare (optimize (speed 3) (safety 0))
           ((integer 0 #.most-positive-fixnum) src dest)
           ((simple-array list (*)) tmp-graph)
           ((simple-array (unsigned-byte 32) (*)) dist-table))
  (labels ((dfs (v flow)
             (declare ((integer 0 #.most-positive-fixnum) v flow))
             (when (= v dest)
               (return-from dfs flow))
             (loop
               (unless (aref tmp-graph v)
                 (return 0))
               (let ((edge (car (aref tmp-graph v))))
                 (when (and (> (edge-capacity edge) 0)
                            (< (aref dist-table v) (aref dist-table (edge-to edge))))
                   (let ((result (dfs (edge-to edge) (min flow (edge-capacity edge)))))
                     (declare ((integer 0 #.most-positive-fixnum) result))
                     (when (> result 0)
                       (decf (edge-capacity edge) result)
                       (incf (edge-capacity (edge-reversed edge)) result)
                       (return result)))))
               (setf (aref tmp-graph v)
                     (cdr (aref tmp-graph v))))))
    (dfs src most-positive-fixnum)))

(defun max-flow! (src dest graph)
  "Destructively sends the maximal flow from SRC to DEST and returns the amount
of the flow. This function signals MAX-FLOW-OVERFLOW error when an infinite
flow (to be precise, >= MOST-POSITIVE-FIXNUM) is possible."
  (declare ((integer 0 #.most-positive-fixnum) src dest)
           ((simple-array list (*)) graph))
  (let* ((n (length graph))
         (dist-table (make-array n :element-type '(unsigned-byte 32)))
         (queue (make-array n :element-type '(unsigned-byte 32)))
         (tmp-graph (make-array n :element-type 'list))
         (result 0))
    (declare ((integer 0 #.most-positive-fixnum) result))
    (loop
      (%fill-dist-table src graph dist-table queue)
      (when (= (aref dist-table dest) +graph-max-distance+) ; not (or no longer) connected
        (return result))
      (dotimes (i n)
        (setf (aref tmp-graph i) (aref graph i)))
      (loop for delta = (%find-path src dest tmp-graph dist-table)
            until (zerop delta)
            do (when (>= (+ result delta) most-positive-fixnum)
                 (error 'max-flow-overflow :graph graph))
               (incf result delta)))))