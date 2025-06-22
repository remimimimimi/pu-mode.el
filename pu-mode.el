;;; pu-mode.el --- toki pona dictionary lookup -*- lexical-binding: t -*-

;; Author: remimimimimi
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1"))
;; Homepage: https://github.com/remimimimimi/pu.el
;; Keywords: toki pona eldoc

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package uses eldoc to display translation for toki pona word
;; at point. We use linku.la dictionary, available at
;; <https://linku.la/jasima/data.json>. Package checks if this file is
;; available in it's local directory. If not, then it automatically
;; downloads it. If file already available then it just use it.

;;; Code:

(require 'url)

(defcustom pu-dict-url "https://linku.la/jasima/data.json"
  "Url where to download linku.la dictionary file."
  :type 'string
  :group 'pu)

(defcustom pu-dict-filename
  (file-name-concat
   (file-name-directory (file-truename (buffer-file-name)))
   "data.json")
  "Name of the dictionary file."
  :type 'string
  :group 'pu)

(defcustom pu-display-language 'en
  "Language in which description of word will be shown."
  :type 'symbol
  :group 'pu)

(defun pu-download-dictionary ()
  "Download dictionary file if not exists."
  (interactive)
  (unless (file-exists-p pu-dict-filename)
    (url-copy-file pu-dict-url pu-dict-filename t)))

(defun pu-delete-dictionary ()
  "Remove dictionary file."
  (interactive)
  (delete-file pu-dict-filename))

(defun pu--read-dict ()
  "Ensure that file exists and read it as JSON, converting to s-expression."
  (pu-download-dictionary)
  (json-read-file pu-dict-filename))

(defun pu--word-info (word)
  "Get information about word from `pu--dict'."
  (when-let* ((words (alist-get 'data pu--dict))
              (word-symbol (intern word))
              (word-info (alist-get word-symbol words)))
    word-info))

(defun pu--word-translation (word)
  "Translate toki pona word to chosen `pu-display-language'."
  (when-let* ((word-info (pu--word-info word))
              (word-def (or (alist-get 'pu_verbatim word-info)
                            (alist-get 'def word-info)))
              (translation (alist-get pu-display-language word-def)))
    translation))

;; TODO: Display all relevant information from `pu--word-info'.
(defun pu--display-in-eldoc (callback)
  "Eldoc documentation function for live typst previews.

CALLBACK is supplied by Eldoc, see `eldoc-documentation-functions'."
  (let* ((word (current-word))
         (translation (pu--word-translation word)))
    (when (and word translation)
      (funcall callback translation))))

;;;###autoload
(define-minor-mode pu-mode "Show translation of toki pona words using eldoc."
  :ligher "pu"
  (cond
   (pu-mode
    (pu-download-dictionary)
    (set (make-local-variable 'pu--dict) (pu--read-dict))
    (add-hook
     'eldoc-documentation-functions #'pu--display-in-eldoc
     nil t))
   (nil
    (kill-local-variable 'pu--dict)
    (remove-hook
     'eldoc-documentation-functions #'pu--display-in-eldoc
     t))))

;;;###autoload
(define-global-minor-mode global-pu-mode pu-mode
  (lambda () (pu-mode 1))
  :group 'convenience)

(provide 'pu)
;;; pu-mode.el ends here
