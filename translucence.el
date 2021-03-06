;; set a few defaults
;; TODO: look at using defcustom to allow customization menu options
(setq transparency-step              1)
(setq default-active-transparency   90)
(setq default-inactive-transparency 80)
(setq transparency-diff              5)  ;; diff between active/inactive frame
(setq min-opacity                   20)  ;; emacs' lower limit
(setq max-opacity                  100)  ;; emacs' upper limit

(defun frame-opacity (&optional frame)
  (if frame (frame-parameter frame 'alpha)
    (frame-parameter (selected-frame) 'alpha)))

(defun active-frame-opacity ()
  (car (frame-opacity (selected-frame))))

(defun inactive-frame-opacity ()
  (cadr (frame-opacity (selected-frame))))

(defun opacity-all-frames ()
  (mapcar 'frame-opacity (frame-list)))

(defun set-frame-opacity (active inactive &optional all-frames-p)
  (if all-frames-p
      (eval `(modify-all-frames-parameters '((alpha . (,active ,inactive)))))
    (eval `(modify-frame-parameters nil '((alpha . (,active ,inactive)))))))

(defun transparency (active inactive &optional all-frames-p)
  "Custom set frame transparency"
  (interactive
   "nTransparency on active frame:\s
    nTransparency on inactive frame:\s")
  (if (y-or-n-p "Apply to all frames? ")
      (set-frame-opacity active inactive 't)
    (set-frame-opacity active inactive)))

(defun frame-transparent-p ()
  (< (car (frame-opacity)) 100))

(defun toggle-transparency (&optional all-frames-p)
  "Toggles the transparency of the frame(s)"
  (interactive)
  (if (frame-transparent-p)
      (set-frame-opacity max-opacity (- max-opacity transparency-diff) all-frames-p)
    (set-frame-opacity
     default-active-transparency default-inactive-transparency all-frames-p)))

(defun increase-opacity (&optional all-frames-p)
  "Decreases the transparency of the current frame"
  (interactive)
  (let ((active        (setq active       (active-frame-opacity)))
        (inactive      (setq inactive     (inactive-frame-opacity)))
        (differential  (setq differential (- active transparency-diff)))
        (max-opacity-p (>= active max-opacity)))
    (setq active (if max-opacity-p
                     max-opacity
                   (+ active transparency-step)))
    (if (< active differential)
        (setq inactive (+ inactive transparency-step))
      (setq inactive differential))
    (set-frame-opacity active inactive all-frames-p)))

(defun decrease-opacity (&optional all-frames-p)
  "Increases the transparency of the current frame"
  (interactive)
  (let ((active        (setq active   (active-frame-opacity)))
        (inactive      (setq inactive (inactive-frame-opacity)))
        (min-opacity-p (<= active min-opacity)))
    (setq active   (if min-opacity-p
                       min-opacity
                       (- active transparency-step)))
    (setq inactive (if min-opacity-p
                     min-opacity
                     (- inactive transparency-step)))
    (set-frame-opacity active inactive all-frames-p)))

;; ideally, when we increase or decrease opacity on all frames,
;; they'd shift up from their current values. At this time, they
;; all follow the current frame. Look at -map from dash.el passibly


;; *************************************************************************
;;    "Animate" Transparency Loop
;; *************************************************************************

(require 'timer)

;; (eval-after-load "dash" '(dash-enable-font-lock))
;; I'd like to be able to map fns over the list of (frames-list)
;; (require 'dash)

(defun transparency-loop (upper lower &optional all-frames-p)
  (let ((transparency-step   1)
        (differential        5)
        (transparency-cycle 'disappearing)   ;; diff actv|inactv
        ;; (all-frames-p all-frames-p)
        )
    (cond
     ;; Lower Bounds Catch
     ;; Flips transparency-cycle to 'appearing
     ((and (equalp transparency-cycle 'disappearing)
           (<= (active-frame-transparency) lower))
      (progn
        ;; setting the transparency here ^^^
        (setq transparency-cycle 'appearing)
        (set-frame-opacity lower (- lower differential) all-frames-p)
        (increase-opacity)))

     ;; decrease opacity if we're "disappearing" and not
     ;; below our lower bounds
     ((and (equalp transparency-cycle 'disappearing)
           (not (<= (active-frame-transparency) lower)))
      (decrease-opacity))

     ;; our upper bound is hit and we restart the disappearing cycle
     ((and (equalp transparency-cycle 'appearing)
           (>= (active-frame-transparency) upper))
      (progn
        ;; setting the transparency here \/\/\/
        (set-frame-opacity upper (- upper differential) all-frames-p)
        (setq transparency-cycle 'disappearing)
        (decrease-opacity)))

     ;; increase opacity if we are "appearing"
     ;; and not above our upper bounds
     ((and (equalp transparency-cycle 'appearing)
           (not (>= (active-frame-transparency) upper)))
      (increase-opacity)))))


(defun start-transparency-animation (upper lower interval &optional all-frames-p)
  "Give the upper and lower boandaries and an innterval (sec)"
  (interactive)
  (let )
  (run-at-time nil interval 'transparency-loop upper lower interval all-frames-p))

(defun stop-transparency-animation ()
  (interactive)
  (progn
    (cancel-function-timers 'transparency-loop)))


;; Key Bindings

(global-set-key (kbd "C-M-<wheel-up>")            'increase-opacity)
(global-set-key (kbd "C-M-<double-wheel-up>")     'increase-opacity)
(global-set-key (kbd "C-M-<triple-wheel-up>")     'increase-opacity)

(global-set-key (kbd "C-M-<wheel-down>")          'decrease-opacity)
(global-set-key (kbd "C-M-<double-wheel-down>")   'decrease-opacity)
(global-set-key (kbd "C-M-<triple-wheel-down>")   'decrease-opacity)

(global-set-key (kbd "C-M-S-<wheel-up>")          (lambda () (interactive) (increase-opacity 't)))
(global-set-key (kbd "C-M-S-<double-wheel-up>")   (lambda () (interactive) (increase-opacity 't)))
(global-set-key (kbd "C-M-S-<triple-wheel-up>")   (lambda () (interactive) (increase-opacity 't)))

(global-set-key (kbd "C-M-S-<wheel-down>")        (lambda () (interactive) (decrease-opacity 't)))
(global-set-key (kbd "C-M-S-<double-wheel-down>") (lambda () (interactive) (decrease-opacity 't)))
(global-set-key (kbd "C-M-S-<triple-wheel-down>") (lambda () (interactive) (decrease-opacity 't)))

(global-set-key (kbd "M-<f2>") 'increase-opacity)
(global-set-key (kbd "M-<f1>") 'decrease-opacity)

(global-set-key (kbd "H-M-<f2>") (lambda () (interactive) (increase-opacity 't))) ;; all-frames
(global-set-key (kbd "H-M-<f1>") (lambda () (interactive) (decrease-opacity 't))) ;; all-frames

(global-set-key (kbd "H-0")     'toggle-transparency)
(global-set-key (kbd "M-H-0")   (lambda () (interactive) (toggle-transparency 't))) ;; all-frames
(global-set-key (kbd "H-[")     (lambda () (interactive) (start-transparency-animation 98 75 0.1 't)))
(global-set-key (kbd "H-]")     'stop-transparency-animation)

(global-set-key (kbd "M-[") 'ns-next-frame)
(global-set-key (kbd "M-]") 'ns-prev-frame)

(provide 'hieros-transparency)
