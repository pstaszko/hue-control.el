;;; hue-control.el -- control your Hue lamps within Emacs

;; Copyright (C) 2018  nilsding

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(require 'cl-lib)
(require 'request)

(defgroup hue-control nil
  "Hue lamp control!  Yay!"
  :prefix "hue-control-"
  :group 'external)

(defcustom hue-control-endpoint "http://philips-hue.local"
  "The URL to your Hue bridge")

(defcustom hue-control-devicename "emacs-hue-control#foxy"
  "The device type.  This will be exchanged with a generated user name once
  authentication is complete")

(defcustom hue-control-username nil
  "The generated user name")

(defun hue-control-authorise ()
  "Authorise with the Hue bridge"
  (interactive)
  (if hue-control-username
      (message "Already authorised.")
    (hue-control-internal-post
     "/api"
     '(("devicetype" . hue-control-devicename))
     (cl-function
      (lambda (&key data &allow-other-keys)
        (let ((obj (aref data 0)))
          (message "%s" obj)
          (if (assoc-default 'error obj)
              (message "Please push the link button on your Hue bridge")
            (progn
              (message "Yay, we are authorised!")
              (customize-save-variable 'hue-control-username (assoc-default 'username (assoc-default 'success obj)))))))))))

(defmacro hue-control-require-auth (&rest authenticated)
  `(if hue-control-username
       (progn . ,authenticated)
     (message "Not authenticated yet, please run hue-control-authorise")))

;; (defun hue-control-lights ()
;;   "Get a list of available lights"
;;   (hue-control-require-auth
;;    (hue-control-internal-get
;;     (format "/api/%s/lights" hue-control-username)
;;     (cl-function
;;      (lambda (&key data &allow-other-keys)
;;        data)))))

(defun hue-control-light-off (light-id)
  (interactive "nLight ID to turn off: ")
  (hue-control-require-auth
   (hue-control-light-set-state light-id :on json-false)))

(defun hue-control-light-on (light-id)
  (interactive "nLight ID to turn on: ")
  (hue-control-require-auth
   (hue-control-light-set-state light-id :on t)))

(defun hue-control-light-brightness (light-id brightness)
  (interactive "nLight ID to change the brightness: \nnBrightness value (1-255): ")
  (hue-control-require-auth
   (hue-control-light-set-state light-id :brightness brightness)))

(cl-defun hue-control-light-set-state (light-id &key brightness on)
  "Modify the state of the light with the id `light-id'"
  (hue-control-require-auth
   (let ((data (seq-filter (lambda (assoc) (cdr assoc)) `(("bri" . ,brightness) ("on" . ,on)))))
     (hue-control-internal-put
      (format "/api/%s/lights/%d/state" hue-control-username light-id)
      data
      (cl-function
       (lambda (&key data &allow-other-keys)
         (message "%S" data)))))))

(defun hue-control-internal-get (path complete)
  "Perform a GET request"
  ;; (message "performing GET %s%s" hue-control-endpoint path)
  (request
   (format "%s%s" hue-control-endpoint path)
   :type "GET"
   :headers '(("Content-Type" . "application/json"))
   :parser 'json-read
   :complete complete))

(defun hue-control-internal-post (path data complete)
  "Perform a POST request"
  ;; (message "performing POST %s%s" hue-control-endpoint path)
  (request
   (format "%s%s" hue-control-endpoint path)
   :type "POST"
   :data (json-encode data)
   :headers '(("Content-Type" . "application/json"))
   :parser 'json-read
   :complete complete))

(defun hue-control-internal-put (path data complete)
  "Perform a PUT request"
  ;; (message "performing PUT %s%s" hue-control-endpoint path)
  (request
   (format "%s%s" hue-control-endpoint path)
   :type "PUT"
   :data (json-encode data)
   :headers '(("Content-Type" . "application/json"))
   :parser 'json-read
   :complete complete))

(provide 'hue-control)