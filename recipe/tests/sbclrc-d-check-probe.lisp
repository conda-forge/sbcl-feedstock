;;; Fail unless sbclrc loaded the probe from sbclrc.d at startup.
(let ((probe (merge-pathnames "sbclrc.d/99-conda-test-probe.lisp"
                              (sb-int:sbcl-homedir-pathname))))
  (unwind-protect
       (unless (and (boundp 'cl-user::*sbclrc-d-probe*)
                    (eq (symbol-value 'cl-user::*sbclrc-d-probe*) :loaded))
         (format *error-output* "sbclrc did not load ~A~%" probe)
         (sb-ext:exit :code 1))
    (delete-file probe)))
