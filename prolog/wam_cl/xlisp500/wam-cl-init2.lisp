
(flet 
  ((satisfies (object elem &key key test test-not)
	 (let* ((zi (if key (funcall key elem) elem))
		(r (funcall (or test test-not #'eql) object zi)))
	   (if test-not (not r) r)))

       (satisfies-if (predicate elem &key key)
	 (funcall predicate (if key (funcall key elem) elem)))
       (satisfies-if-not (predicate elem &key key)
	 (not (funcall predicate (if key (funcall key elem) elem))))
       (seq-start (sequence &key (start 0) end from-end)
	 (if (listp sequence)
	     (if from-end
		 (let ((acc nil)
		       (sequence (nthcdr start sequence)))
		   (tagbody
		    start
		      (when (and sequence (or (not end) (< start end)))
			(push sequence acc)
			(setf sequence (cdr sequence))
			(setf start (+ 1 start))
			(go start)))
		   (list 3 acc start))
		 (list 2 (nthcdr start sequence) start))
	     (if from-end (cons 1 (- end 1)) (cons 0 start))))
       (seq-position (iter)
	 (case (car iter)
	   ((0 1) (cdr iter))
	   (t (caddr iter))))
       (seq-next (iter)
	 (case (car iter)
	   (0 (setf (cdr iter) (+ 1 (cdr iter))))
	   (1 (setf (cdr iter) (- (cdr iter) 1)))
	   (2 (setf (cadr iter) (cdadr iter))
	      (setf (caddr iter) (+ 1 (caddr iter))))
	   (t (setf (cadr iter) (cdadr iter))
	      (setf (caddr iter) (- (caddr iter) 1)))))
       (seq-ref (sequence iter)
	 (case (car iter)
	   ((0 1) (aref sequence (cdr iter)))
	   (2 (caadr iter))
	   (t (caaadr iter))))
       (seq-set (sequence iter value)
	 (case (car iter)
	   ((0 1) (setf (aref sequence (cdr iter)) value))
	   (2 (setf (caadr iter) value))
	   (t (setf (caaadr iter) value))))
       (seq-end-p (sequence iter &key start end from-end)
	 (case (car iter)
	   (0 (or (= (cdr iter) (length sequence))
		  (and end (= end (cdr iter)))))
	   (1 (< (cdr iter) start))
	   (2 (or (null (cadr iter)) (and end (= end (caddr iter)))))
	   (t (or (null (cadr iter)) (< (caddr iter) start)))))
       (seq-result (sequence iter result)
	 (case (car iter)
	   (0 (make-array (length result)
			  :element-type (array-element-type sequence)
			  :initial-contents (reverse result)))
	   (1 (make-array (length result)
			  :element-type (array-element-type sequence)
			  :initial-contents result))
	   (2 (reverse result))
	   (3 result))))


  (defun member (item list &rest rest)
    (tagbody
       start
       (when list
	 (when (apply #'satisfies item (car list) rest)
	   (return-from member list))
	 (setf list (cdr list))
	 (go start))))
  (defun member-if (predicate list &rest rest)
    (tagbody
       start
       (when list
	 (when (apply #'satisfies-if predicate (car list) rest)
	   (return-from member-if list))
	 (setf list (cdr list))
	 (go start))))
  (defun member-if-not (predicate list &rest rest)
    (tagbody
       start
       (when list
	 (when (apply #'satisfies-if-not predicate (car list) rest)
	   (return-from member-if list))
	 (setf list (cdr list))
	 (go start))))
  (defun subst (new old tree &rest rest)
    (if (consp tree)
	(let ((a (apply #'subst new old (car tree) rest))
	      (d (apply #'subst new old (cdr tree) rest)))
	  (if (and (eq a (car tree)) (eq d (cdr tree)))
	      tree
	      (cons a d)))
	(if (apply #'satisfies old tree rest) new tree)))
  (defun subst-if (new predicate tree &rest rest)
    (if (consp tree)
	(let ((a (apply #'subst new predicate (car tree) rest))
	      (d (apply #'subst new predicate (cdr tree) rest)))
	  (if (and (eq a (car tree)) (eq d (cdr tree)))
	      tree
	      (cons a d)))
	(if (apply #'satisfies-if predicate tree rest) new tree)))
  (defun subst-if-not (new predicate tree &rest rest)
    (if (consp tree)
	(let ((a (apply #'subst new predicate (car tree) rest))
	      (d (apply #'subst new predicate (cdr tree) rest)))
	  (if (and (eq a (car tree)) (eq d (cdr tree)))
	      tree
	      (cons a d)))
	(if (apply #'satisfies-if-not predicate tree rest) new tree)))
  (defun nsubst (new old tree &rest rest)
    (if (consp tree)
	(progn
	  (setf (car tree) (apply #'subst new old (car tree) rest))
	  (setf (cdr tree) (apply #'subst new old (cdr tree) rest))
	  tree)
	(if (apply #'satisfies old tree rest) new tree)))
  (defun nsubst-if (new predicate tree &rest rest)
    (if (consp tree)
	(progn
	  (setf (car tree) (apply #'subst new predicate (car tree) rest))
	  (setf (cdr tree) (apply #'subst new predicate (cdr tree) rest))
	  tree)
	(if (apply #'satisfies-if predicate tree rest) new tree)))
  (defun nsubst-if-not (new predicate tree &rest rest)
    (if (consp tree)
	(progn
	  (setf (car tree) (apply #'subst new predicate (car tree) rest))
	  (setf (cdr tree) (apply #'subst new predicate (cdr tree) rest))
	  tree)
	(if (apply #'satisfies-if-not predicate tree rest) new tree)))
  (defun assoc (item alist &rest rest)
    (dolist (elem alist)
      (when (apply #'satisfies item (car elem) rest)
	(return-from assoc elem))))
  (defun assoc-if (predicate alist &rest rest)
    (dolist (elem alist)
      (when (apply #'satisfies-if predicate (car elem) rest)
	(return-from assoc-if elem))))
  (defun assoc-if-not (predicate alist &rest rest)
    (dolist (elem alist)
      (when (apply #'satisfies-if-not predicate (car elem) rest)
	(return-from assoc-if-not elem))))
  (defun rassoc (item alist &rest rest)
    (dolist (elem alist)
      (when (apply #'satisfies item (cdr elem) rest)
	(return-from rassoc elem))))
  (defun rassoc-if (predicate alist &rest rest)
    (dolist (elem alist)
      (when (apply #'satisfies-if predicate (cdr elem) rest)
	(return-from rassoc-if elem))))
  (defun rassoc-if-not (predicate alist &rest rest)
    (dolist (elem alist)
      (when (apply #'satisfies-if-not predicate (cdr elem) rest)
	(return-from rassoc-if-not elem))))
  (defun adjoin (item list &rest rest)
    (dolist (elem list (cons item list))
      (when (apply #'satisfies item elem rest)
	(return-from adjoin list))))
  (defun set-exclusive-or (list-1 list-2 &rest rest &key key)
    (let ((result nil))
      (dolist (item list-1)
	(unless (apply #'member (if key (funcall key item) item) list-2 rest)
	  (push item result)))
      (dolist (item list-2)
	(block matches
	  (dolist (elem list-1)
	    (when (apply #'satisfies
			 (if key (funcall key elem) elem) item rest)
	      (return-from matches)))
	  (push item result)))
      result))
  (defun nset-exclusive-or (list-1 list-2 &rest rest &key key)
    (let ((result nil)
	  (list nil)
	  (item nil))
      (tagbody
       start-1
	 (unless list-1 (go start-2))
	 (setf item (car list-1))
	 (setf list list-2)
	 (setf prev nil)
       start-1-in
	 (unless list (go end-1-in))
	 (let ((elem (if key (funcall key (car list)) (car list))))
	   (when (apply #'satisfies item (if key (funcall key elem) elem) rest)
	     (if prev
		 (setf (cdr prev) (cdr list))
		 (setf list-2 (cdr list)))
	     (setf list-1 (cdr list-1))
	     (go start-1)))
	 (setf prev list)
	 (setf list (cdr list))
	 (go start-1-in)
       end-1-in
	 (setf item (cdr list-1))
	 (setf (cdr list-1) result)
	 (unless result (setf end list-1))
	 (setf result list-1)
	 (setf list-1 item)
	 (go start-1)
       start-2
	 (return-from nset-exclusive-or
	   (if end (progn (setf (cdr end) list-2) result) list-2)))))
  (defun fill (sequence item &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (seq-set sequence iter item)
	   (seq-next iter)
	   (go start))))
    sequence)
  (defun every (predicate &rest sequences)
    (let ((iters (mapcar #'seq-start sequences)))
      (tagbody
       start
	 (unless (some-list-2 #'seq-end-p sequences iters)
	   (unless (apply predicate (mapcar #'seq-ref sequences iters))
	     (return-from every nil))
	   (mapc #'seq-next iters)
	   (go start))))
    t)
  (defun some (predicate &rest sequences)
    (let ((iters (mapcar #'seq-start sequences)))
      (tagbody
       start
	 (unless (some-list-2 #'seq-end-p sequences iters)
	   (let ((result (apply predicate (mapcar #'seq-ref sequences iters))))
	     (when result (return-from some result)))
	   (mapc #'seq-next iters)
	   (go start)))))
  (defun notevery (predicate &rest sequences)
    (let ((iters (mapcar #'seq-start sequences)))
      (tagbody
       start
	 (unless (some-list-2 #'seq-end-p sequences iters)
	   (unless (apply predicate (mapcar #'seq-ref sequences iters))
	     (return-from every t))
	   (mapc #'seq-next iters)
	   (go start)))))
  (defun notany (predicate &rest sequences)
    (let ((iters (mapcar #'seq-start sequences)))
      (tagbody
       start
	 (unless (some-list-2 #'seq-end-p sequences iters)
	   (when (apply predicate (mapcar #'seq-ref sequences iters))
	     (return-from every nil))
	   (mapc #'seq-next iters)
	   (go start))))
    t)
  (defun map-into (result-sequence function &rest sequences)
    (let ((result-iter (seq-start result-sequence))
	  (iters (mapcar #'seq-start sequences)))
      (tagbody
       start
	 (unless (some-list-2 #'seq-end-p sequences iters)
	   (seq-set result-sequence result-iter
		    (apply function (mapcar #'seq-ref sequences iters)))
	   (seq-next result-iter)
	   (mapc #'seq-next iters)
	   (go start))))
    result-sequence)
  (defun reduce (function sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (if (apply #'seq-end-p sequence iter rest)
	  (funcall function)
	  (let ((elem (seq-ref sequence iter)))
	    (seq-next iter)
	    (unless (apply #'seq-end-p sequence iter rest)
	      (tagbody
	       start
		 (setq elem (funcall function elem (seq-ref sequence iter)))
		 (seq-next iter)
		 (unless (apply #'seq-end-p sequence iter rest)
		   (go start))))
	    elem))))
  (defun count (item sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest))
	  (count 0))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (when (apply #'satisfies item (seq-ref sequence iter) rest)
	     (setf count (+ 1 count)))
	   (seq-next iter)
	   (go start)))
      count))
  (defun count-if (predicate sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest))
	  (count 0))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (when (apply #'satisfies-if predicate (seq-ref sequence iter) rest)
	     (setf count (+ 1 count)))
	   (seq-next iter)
	   (go start)))
      count))
  (defun count-if-not (predicate sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest))
	  (count 0))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (when (apply #'satisfies-if-not predicate (seq-ref sequence iter)
			rest)
	     (setf count (+ 1 count)))
	   (seq-next iter)
	   (go start)))
      count))
  (defun find (item sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (let ((elem (seq-ref sequence iter)))
	     (when (apply #'satisfies item elem rest)
	       (return-from find elem)))
	   (seq-next iter)
	   (go start)))))
  (defun find-if (predicate sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (let ((elem (seq-ref sequence iter)))
	     (when (apply #'satisfies-if predicate elem rest)
	       (return-from find-if elem)))
	   (seq-next iter)
	   (go start)))))
  (defun find-if-not (predicate sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (let ((elem (seq-ref sequence iter)))
	     (when (apply #'satisfies-if-not predicate elem rest)
	       (return-from find-if-not elem)))
	   (seq-next iter)
	   (go start)))))
  (defun position (item sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (when (apply #'satisfies item (seq-ref sequence iter) rest)
	     (return-from position (seq-position iter)))
	   (seq-next iter)
	   (go start)))))
  (defun position-if (predicate sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (when (apply #'satisfies-if predicate (seq-ref sequence iter) rest)
	     (return-from position-if (seq-position iter)))
	   (seq-next iter)
	   (go start)))))
  (defun position-if-not (predicate sequence &rest rest)
    (let ((iter (apply #'seq-start sequence rest)))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (when (apply #'satisfies-if-not predicate (seq-ref sequence iter)
			rest)
	     (return-from position-if-not (seq-position iter)))
	   (seq-next iter)
	   (go start)))))
  (defun remove (item sequence &rest rest &key count)
    (let ((iter (apply #'seq-start sequence rest))
	  (result nil))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (let ((elem (seq-ref sequence iter)))
	     (unless (and (apply #'satisfies item elem rest)
			  (or (not count) (not (minusp (decf count)))))
	       (push elem result)))
	   (seq-next iter)
	   (go start)))
      (seq-result sequence iter result)))
  (defun remove-if (predicate sequence &rest rest &key count)
    (let ((iter (apply #'seq-start sequence rest))
	  (result nil))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (let ((elem (seq-ref sequence iter)))
	     (unless (and (apply #'satisfies-if predicate elem rest)
			  (or (not count) (not (minusp (decf count)))))
	       (push elem result)))
	   (seq-next iter)
	   (go start)))
      (seq-result sequence iter result)))
  (defun remove-if-not (predicate sequence &rest rest &key count)
    (let ((iter (apply #'seq-start sequence rest))
	  (result nil))
      (tagbody
       start
	 (unless (apply #'seq-end-p sequence iter rest)
	   (let ((elem (seq-ref sequence iter)))
	     (unless (and (apply #'satisfies-if-not predicate elem rest)
			  (or (not count) (not (minusp (decf count)))))
	       (push elem result)))
	   (seq-next iter)
	   (go start)))
      (seq-result sequence iter result)))
)



(defparameter *standard-class* (makei 1 0))
(setf (iref *standard-class* 1) *standard-class*)
(defparameter *structure-class* (makei 1 *standard-class*))



(defparameter *hash-table* (makei 1 *structure-class*))
(defun hash-eql (object)
  (if (and (= (ldb '(2 . 0) (ival object)) 3) (= (jref object 1) 84))
      (floor (abs object))
      (ival object)))
(defun sxhash (object &optional (level 4))
  (if (zerop level)
      0
      (let ((lvl (- level 1)))
	(case (ldb '(2 . 0) (ival object))
	  (0 (ival object))
	  (1 (+ (sxhash (car object) lvl) (sxhash (cdr object) lvl)))
	  (2 (case (iref object 1)
	       (t (ival object))))
	  (3 (case (jref object 1)
	       (20 (hash object))
	       (84 (floor (abs object)))
	       (t (ival object))))))))
(defun make-hash-table (&key (test 'eql) (size 61) (rehash-size 1.999)
			(rehash-threshold 1))
  (when (functionp test)
    (setq test (iref test 6)))
  (makei 6 *hash-table* 0 rehash-size rehash-threshold test
	 (case test
	   (eq #'ival)
	   (eql #'hash-eql)
	   (equal #'sxhash)
	   (equalp #'hash-equalp)
	   (t (error "Unknown test function ~A." test)))
	 (makei size 3)))
(defun gethash (key hash-table &optional default)
  (let* ((table (hash-table-table hash-table))
	 (test (hash-table-test hash-table))
	 (index (mod (funcall (hash-table-hash hash-table) key)
		     (length table))))
    (dolist (cons (iref table (+ 2 index)) (values default nil))
      (when (funcall test (car cons) key)
	(return (values (cdr cons) t))))))
(defun (setf gethash) (new-value key hash-table &optional default)
  (let* ((table (hash-table-table hash-table))
	 (test (hash-table-test hash-table))
	 (index (mod (funcall (hash-table-hash hash-table) key)
		     (length table))))
    (dolist (cons (iref table (+ 2 index))
	     (progn
	       (push (cons key new-value) (iref table (+ 2 index)))
	       (unless (< (incf (hash-table-count hash-table))
			  (* (hash-table-rehash-threshold hash-table)
			     (length table)))
		 (setf (hash-table-table hash-table)
		       (makei (floor (* (hash-table-rehash-size hash-table)
					(length table)))
			      3))
		 (setf (hash-table-count hash-table) 0)
		 (dotimes (index (length table))
		   (dolist (cons (iref table (+ 2 index)))
		     (setf (gethash (car cons) hash-table) (cdr cons)))))))
      (when (funcall test (car cons) key)
	(setf (cdr cons) new-value)
	(return (values (cdr cons) t)))))
  new-value)
(defun remhash (key hash-table)
  (let* ((table (hash-table-table hash-table))
	 (test (hash-table-test hash-table))
	 (index (mod (funcall (hash-table-hash hash-table) key)
		     (length table)))
	 (cons (iref table (+ 2 index)))
	 (prev-cons nil))
    (tagbody
     start
       (unless cons (return-from remhash))
       (unless (funcall test (caar cons) key)
	 (setq prev-cons cons)
	 (setq cons (cdr cons))
	 (go start)))
    (if prev-cons
	(setf (cdr prev-cons) (cdr cons))
	(setf (iref table (+ 2 index)) (cdr cons)))
    (decf (hash-table-count hash-table))
    t))
(defun maphash (function hash-table)
  (let ((table (hash-table-table hash-table)))
    (dotimes (index (length table))
      (dolist (cons (iref table (+ 2 index)))
	(funcall function (car cons) (cdr cons))))))
(defun hash-table-iterator (hash-table)
  (let ((table (hash-table-table hash-table))
	(index 0)
	(cons nil))
    #'(lambda ()
	(block nil
	  (tagbody
	   start
	     (unless cons
	       (unless (< index (length table))
		 (return))
	       (setq cons (iref table (+ 2 index)))
	       (incf index)
	       (go start)))
	  (let ((pair (pop cons)))
	    (values t (car pair) (cdr pair)))))))
(defmacro with-hash-table-iterator ((name hash-table) &rest forms)
  (let ((iterator (gensym)))
    `(let ((,iterator (hash-table-iterator ,hash-table)))
      (macrolet ((,name ()
		   `(funcall ,,iterator)))
	,@forms))))
(defun clrhash (hash-table)
  (let ((table (hash-table-table hash-table)))
    (dotimes (index (length table))
      (setf (iref table (+ 2 index)) nil)))
  (setf (hash-table-count hash-table) 0)
  hash-table)
(defun hash-table-count (hash-table) (iref hash-table 2))
(defun (setf hash-table-count) (new-value hash-table)
  (setf (iref hash-table 2) new-value))
(defun hash-table-rehash-size (hash-table) (iref hash-table 3))
(defun hash-table-rehash-threshold (hash-table) (iref hash-table 4))
(defun hash-table-test (hash-table) (iref hash-table 5))
(defun hash-table-hash (hash-table) (iref hash-table 6))
(defun hash-table-table (hash-table) (iref hash-table 7))
(defun (setf hash-table-table) (new-value hash-table)
  (setf (iref hash-table 7) new-value))
(defparameter *class-hash* (make-hash-table))
(defun find-class (symbol &optional (errorp t) environment)
  (multiple-value-bind (class foundp)
      (gethash symbol *class-hash*)
    (when (and errorp (not foundp))
      (error "Class ~A not found." symbol))
    class))