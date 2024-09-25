;; inherits: go
;; extends

; stupid

 ((comment) @kubebuilder
            (#match? @kubebuilder "^//\\+kubebuilder:")
            (#absoffset! @kubebuilder 0 3 0 11)
            )

 ((comment) @kubebuilder.rbac
            (#match? @kubebuilder.rbac "^//\\+kubebuilder:rbac:")
            (#offset! @kubebuilder.rbac 0 15 0 -1)
            (#absoffset! @kubebuilder.rbac 0 0 0 4)
            )

 ((comment) @kubebuilder.object
            (#match? @kubebuilder.object "^//\\+kubebuilder:object:")
            (#offset! @kubebuilder.object 0 15 0 -1)
            (#absoffset! @kubebuilder.object 0 0 0 6)
            )

 ((comment) @kubebuilder.subresource
            (#match? @kubebuilder.subresource "^//\\+kubebuilder:subresource:")
            (#offset! @kubebuilder.subresource 0 15 0 -1)
            (#absoffset! @kubebuilder.subresource 0 0 0 11)
            )

 ((comment) @kubebuilder.webhook
            (#match? @kubebuilder.webhook "^//\\+kubebuilder:webhook:")
            (#offset! @kubebuilder.webhook 0 15 0 -1)
            (#absoffset! @kubebuilder.webhook 0 0 0 7)
            )

 ((comment) @kubebuilder.validation
            (#match? @kubebuilder.validation "^//\\+kubebuilder:validation:")
            (#offset! @kubebuilder.validation 0 15 0 -1)
            (#absoffset! @kubebuilder.validation 0 0 0 10)
            )

 ((comment) @kubebuilder.default
            (#match? @kubebuilder.default "^//\\+kubebuilder:default:")
            (#offset! @kubebuilder.default 0 15 0 -1)
            (#absoffset! @kubebuilder.default 0 0 0 7)
            )

 ((comment) @kubebuilder.example
            (#match? @kubebuilder.example "^//\\+kubebuilder:example:")
            (#offset! @kubebuilder.example 0 15 0 -1)
            (#absoffset! @kubebuilder.example 0 0 0 7)
            )

("return" @keyword.return.go (#set! "priority" 200))
