;;; aider-mode.el --- Emacs mode for interfacing with Aider

;;; Commentary:
;; This mode provides basic commands to interact with Aider from Emacs.

;;; Code:

(defvar aider-process nil
  "The process object for the Aider server.")

(defvar aider-output-buffer "*Aider Output*"
  "Buffer name for Aider output.")

(defvar aider-input-buffer "*Aider Input*"
  "Buffer name for Aider input.")

(defvar aider-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c a a") 'aider-add)
    (define-key map (kbd "C-c a c") 'aider-code)
    (define-key map (kbd "C-c a d") 'aider-diff)
    (define-key map (kbd "C-c a e") 'aider-exit)
    (define-key map (kbd "C-c a g") 'aider-git)
    (define-key map (kbd "C-c a h") 'aider-help)
    (define-key map (kbd "C-c a l") 'aider-lint)
    (define-key map (kbd "C-c a m") 'aider-map)
    (define-key map (kbd "C-c a r") 'aider-run)
    (define-key map (kbd "C-c a s") 'aider-settings)
    (define-key map (kbd "C-c a t") 'aider-test)
    (define-key map (kbd "C-c a u") 'aider-undo)
    map)
  "Keymap for Aider mode.")

(defvar aider-args nil
  "List of arguments passed to Aider.")

(defvar aider-venv-path (expand-file-name "aider-venv" (concat user-emacs-directory ".cache"))
  "Path to the Aider virtual environment.")

(defun aider-process-filter (process output)
  "Filter function for Aider PROCESS OUTPUT."
  (with-current-buffer (get-buffer-create aider-output-buffer)
    (goto-char (point-max))
    (insert output)))

(defun aider-process-sentinel (process event)
  "Sentinel function for Aider PROCESS EVENT."
  (message "Aider process event: %s" event))

(defun aider-send-command (command)
  "Send COMMAND to the Aider server."
  (aider-start-server)
  (process-send-string aider-process (concat command "\n")))

(defun aider-add ()
  "Add a file to the chat, defaulting to the current buffer's file."
  (interactive)
  (let ((file-path (expand-file-name (read-file-name "File to add: " nil (buffer-file-name)))))
    (aider-send-command (concat "/add " file-path))))

(defun aider-code ()
  "Ask for changes to your code with a user-provided message."
  (interactive)
  (let ((message (read-string "aider /code: ")))
    (aider-send-command (concat "/code " message))))

(defun aider-diff ()
  "Display the diff of changes since the last message."
  (interactive)
  (aider-send-command "/diff"))

(defun aider-exit ()
  "Exit the Aider application."
  (interactive)
  (aider-send-command "/exit"))

(defun aider-git ()
  "Run a git command."
  (interactive)
  (aider-send-command "/git"))

(defun aider-help ()
  "Ask questions about Aider."
  (interactive)
  (aider-send-command "/help"))

(defun aider-lint ()
  "Lint and fix in-chat files or all dirty files if none in chat."
  (interactive)
  (aider-send-command "/lint"))

(defun aider-map ()
  "Print out the current repository map."
  (interactive)
  (aider-send-command "/map"))

(defun aider-run ()
  "Run a shell command and optionally add the output to the chat."
  (interactive)
  (aider-send-command "/run"))

(defun aider-settings ()
  "Print out the current settings."
  (interactive)
  (aider-send-command "/settings"))

(defun aider-test ()
  "Run a shell command and add the output to the chat on non-zero exit code."
  (interactive)
  (aider-send-command "/test"))

(defun aider-undo ()
  "Undo the last git commit if it was done by Aider."
  (interactive)
  (aider-send-command "/undo"))


(defun aider-start-server ()
  "Start the Aider server process within the virtual environment."
  (unless (process-live-p aider-process)
    (unless (eq (shell-command "command -v aider") 0)
      (aider-activate-venv))
    (setq aider-process (start-process-shell-command "aider" aider-output-buffer
                                       (mapconcat #'identity (append (cons "aider" aider-args)) " ")))
    (set-process-filter aider-process 'aider-process-filter)
    (set-process-sentinel aider-process 'aider-process-sentinel)))

;; create venv

(defun aider-activate-venv ()
  "Activate the Aider virtual environment."
  (aider-create-venv)
  (setenv "VIRTUAL_ENV" aider-venv-path)
  (setenv "PATH" (concat aider-venv-path "/bin:" (getenv "PATH"))))


(defun aider-create-venv ()
  "Create a Python virtual environment in Emacs .cache directory and install Aider."
  (if (file-exists-p aider-venv-path)
      (message "Virtual environment already exists at %s" aider-venv-path)
    (progn
      (message "Creating virtual environment...")
      (shell-command (concat "python3 -m venv " aider-venv-path))
      (aider-install-in-venv aider-venv-path))))

(defun aider-install-in-venv (venv-path)
  "Install Aider in a python3 virtual environment at VENV-PATH."
  (interactive "DEnter path to virtual environment: ")
  (let ((activate-script (concat venv-path "/bin/activate")))
    (if (file-exists-p activate-script)
        (progn
          (message "Activating virtual environment...")
          (setenv "VIRTUAL_ENV" venv-path)
          (setenv "PATH" (concat venv-path "/bin:" (getenv "PATH")))
          (message "Installing Aider...")
          (shell-command (concat "pip install aider-chat")))
      (message "Virtual environment not found at %s" venv-path))))

;;;###autoload
(define-minor-mode aider-mode
  "Minor mode for interacting with Aider."
  :lighter " Aider"
  :keymap aider-mode-map)

(provide 'aider-mode)
;;; aider-mode.el ends here
