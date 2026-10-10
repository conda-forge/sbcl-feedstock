;;; Drop a probe into sbclrc.d; the next SBCL start must load it via sbclrc.
(with-open-file (s (merge-pathnames "sbclrc.d/99-conda-test-probe.lisp"
                                    (sb-int:sbcl-homedir-pathname))
                   :direction :output :if-exists :supersede)
  (write-line "(defparameter cl-user::*sbclrc-d-probe* :loaded)" s))
