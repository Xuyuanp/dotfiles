;; inherits: go
;; extends

 ((comment) @kubebuilder
            (#match? @kubebuilder "^//\\+kubebuilder:")
            (#absoffset! @kubebuilder 0 3 0 11)
            )
