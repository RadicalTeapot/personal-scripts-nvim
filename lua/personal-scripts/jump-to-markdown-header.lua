local M = {}

M.get_line_node = function(line, line_num)
    return { line = line, line_num = line_num }
end

M.get_header_nodes = function(lines, pattern)
    pattern = pattern or "^#+%s.+$" -- One or more '#' followed by a space, then any number of characters till the end of the line
    local header_nodes = {}
    for i, line in ipairs(lines) do
        if string.match(line, pattern) then
            table.insert(header_nodes, M.get_line_node(line, i))
        end
    end
    return header_nodes
end

M.get_title = function(index, line, index_padding)
    index_padding = index_padding or 1
    index = string.format("%"..index_padding.."d", index)
    return index .. ":" .. string.gsub(line, "#", " ")
end

M.show_header_select_ui = function(line_nodes)
    local array = {}
    local index_padding = #tostring(#line_nodes) -- Get the length of the string representing the count
    for i, line_node in ipairs(line_nodes) do
        local title = M.get_title(i, line_node.line, index_padding)
        table.insert(array, M.get_line_node(title, line_node.line_num))
    end

    vim.ui.select(array, {
        prompt="Select header to jump to",
        format_item = function(line_node)
            return line_node.line
        end,
    }, function(choice)
        if choice then -- Choice is nil if the user cancels the dialog
            vim.api.nvim_win_set_cursor(0, { choice.line_num, 0 })
        end
    end)
end

M.jump_to_header = function()
    local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false)
    if #lines == 0 then
        return
    end
    local header_nodes = M.get_header_nodes(lines)
    if #header_nodes == 0 then
        return
    end
    M.show_header_select_ui(header_nodes)
end

M.setup = function()
    vim.api.nvim_create_user_command("JumpToMarkdownHeader", M.jump_to_header, {})
end

return M
