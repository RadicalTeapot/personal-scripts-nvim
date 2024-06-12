local M = {}

M.pandocStringSubstitution = {
    ["\\%["] = "[",
    ["\\%]"] = "]",
    ["‘"] = "'",
    ["’"] = "'",
    ["“"] = [["]],
    ["”"] = [["]],
    ["\\%*"] = "*",
    ["\\>"] = ">"
}

M.cleanPandocString = function(input)
    for pattern, replacement in pairs(M.pandocStringSubstitution) do
        input = string.gsub(input, pattern, replacement)
    end
    return input
end

M.sendToPandoc = function(opts)
    local start = (opts.line1 or 1) - 1
    local last = opts.line2 or -1
    local lines = vim.api.nvim_buf_get_lines(0, start, last, false)

    local out = vim.system({"pandoc", "--columns=120", "-t", "gfm"}, {stdin=lines, text=true}):wait()
    assert(out.code == 0, "An error occured "..(out.stderr or ""))

    local cleaned = M.cleanPandocString(out.stdout)
    local splits = vim.split(cleaned, "\n", {plain=true})
    table.remove(splits) -- pop extra last element
    vim.api.nvim_buf_set_lines(0, start, last, false, splits)
end

M.setup = function()
    vim.api.nvim_create_user_command("SendToPandoc", M.sendToPandoc, {range="%"})
end

return M
