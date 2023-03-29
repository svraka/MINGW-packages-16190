(defun test-subprocesses ()
  ;; Emacs launched from an MSYS shell is not set up properly
  (if (eq shell-file-name "")
      (setq shell-file-name (concat (file-name-directory
                                     (directory-file-name invocation-directory))
                                    "libexec/emacs/28.2/x86_64-w64-mingw32/cmdproxy.exe")))
  (async-shell-command "dir")
  (sleep-for 5)
  ;; I can't make Windows Emacs print anything to stdout. `message'
  ;; would work on unix-like.
  (write-region (number-to-string (length (process-list)))
                nil
                "res"))
