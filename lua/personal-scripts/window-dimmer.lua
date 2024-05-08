local M = {
    ns = vim.api.nvim_create_namespace("WindowDimmer"),
    augrp_name = "WindowDimmerAuGroup",
    hl_group = "Twilight", -- NOTE This supposes the `Twilight" group exists!
    enabled = false,
    enabled_buf = nil,
}

M.enable = function()
    if not M.enabled then
        M.enabled = true
        vim.api.nvim_create_autocmd({ "WinEnter" }, {
            group = vim.api.nvim_create_augroup(M.augrp_name, { clear = true }),
            callback = M.on_win_enter,
        })
    end
    M.on_win_enter()
end

M.disable = function()
    if M.enabled then
        M.enabled = false
        M.enabled_buf = nil
        vim.api.nvim_del_augroup_by_name(M.augrp_name)
    end
    M.clear_all()
end

M.on_win_enter = function()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_win_get_buf(current_win)

    for buf, _ in pairs(M.get_visible_buffers()) do
        if M.should_buffer_be_dimmed(buf, current_buf) then
            M.dim(buf)
        end
    end

    M.clear(current_buf)
    -- Mark current buffer as the enabled one (need to happen after dimming as it relies on value being nil for proper
    -- initialization)
    M.enabled_buf = current_buf
end

M.clear_all = function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            M.clear(buf)
        end
    end
end

M.dim = function(buf)
    local top = 0
    local bottom = vim.api.nvim_buf_line_count(buf)
    for i = top, bottom do
        pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, i, 0, {
            end_line = i + 1,
            end_col = 0,
            hl_group = M.hl_group,
            hl_eol = true,
            priority = 10000,
        })
    end
end

M.clear = function(buf)
    vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
end

M.get_visible_buffers = function()
    local bufs = {}
    for _, win in pairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        bufs[buf] = true -- Overwrite buffer key if opened in more than one window
    end
    return bufs
end

M.should_buffer_be_dimmed = function(buf, current_buf)
    return buf ~= current_buf -- Don't dim the current buffer
        and (M.enabled_buf == nil or M.enabled_buf == buf) -- Dim only if status changed or first time the command is ran
end

M.setup = function()
    vim.api.nvim_create_user_command("DimWindowsOn", M.enable, {})
    vim.api.nvim_create_user_command("DimWindowsOff", M.disable, {})
end

return M
