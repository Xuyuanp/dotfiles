vim.api.nvim_set_hl(0, '@kubebuilder.go', {
    link = 'Keyword',
})

for name, link in pairs({
    rbac = 'Structure',
    object = 'Structure',
    subresource = 'Structure',
    webhook = 'Structure',
    default = 'Structure',
    validation = 'Structure',
    example = 'Structure',
}) do
    vim.api.nvim_set_hl(0, '@kubebuilder.' .. name .. '.go', {
        link = link,
    })
end
