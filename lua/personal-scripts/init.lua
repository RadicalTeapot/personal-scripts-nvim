local M = {}

M.default = {
    new_periodic = true,
    planing_layout = true,
    to_pandoc = true,
    window_dimmer = true,
    jump_to_markdown_header = true,
}

M.setup = function(opts)
    opts = vim.tbl_deep_extend('force', M.default, opts)

    if opts.new_periodic then
        require('personal-scripts.new-periodic').setup()
    end
    if opts.planing_layout then
        require('personal-scripts.planning-layout').setup()
    end
    if opts.to_pandoc then
        require('personal-scripts.to-pandoc').setup()
    end
    if opts.window_dimmer then
        require('personal-scripts.window-dimmer').setup()
    end
    if opts.jump_to_markdown_header then
        require('personal-scripts.jump-to-markdown-header').setup()
    end
end

return M
