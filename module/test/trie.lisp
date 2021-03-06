(defpackage :cp/test/trie
  (:use :cl :fiveam :cp/trie)
  (:import-from :cp/test/base #:base-suite))
(in-package :cp/test/trie)
(in-suite base-suite)

(test trie
  (let ((trie (make-trie)))
    (trie-add! trie "abra")
    (trie-add! trie "abrac")
    (trie-add! trie "rac")
    (trie-add! trie "racad")
    (is (= 1 (trie-get trie "abra")))
    (is (= 2 (trie-get trie "abra" :target :prefix)))
    (is (= 0 (trie-get trie "ab")))
    (is (= 2 (trie-get trie "ab" :target :prefix)))
    (is (= 0 (trie-get trie "")))
    (is (= 4 (trie-get trie "" :target :prefix)))
    (trie-add! trie "")
    (is (= 1 (trie-get trie "")))
    (is (= 5 (trie-get trie "" :target :prefix)))
    (is (= 0 (trie-get trie "abracada")))))
