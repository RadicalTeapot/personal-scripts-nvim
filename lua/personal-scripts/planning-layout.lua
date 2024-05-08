-- TODO Some of this file is duplicated in new-periodic.lua, move to a common file and require it here
local M = {
    root_dir = "01 Periodic notes",
    suffix = {
        day = "daily",
        week = "weekly",
        month = "monthly",
    },
}

M.get_file_names = function()
    -- Strip away time hours info (i.e. only keep date info)
    local now_table = os.date("*t", os.time())
    local now = os.time({ year = now_table.year, month = now_table.month, day = now_table.day })
    local week = math.ceil(now_table.yday / 7)

    local today = os.date("%Y-%m-%d", now)
    local this_week = now_table.year .. "-W" .. week -- There's no convenience method to get the week number with os.date
    local this_month = os.date("%Y-%m", now)

    return { day = today, week = this_week, month = this_month }
end

M.get_existing_file_path = function(file_name, root_dir, extension)
    assert(file_name, "file_name cannot be nil")
    assert(root_dir, "root_dir cannot be nil")
    extension = extension or ".md"
    local path = vim.fs.normalize(root_dir .. "/" .. file_name .. extension)
    assert((vim.loop or vim.uv).fs_stat(path), "Could not find file at " .. path)
    return path
end

M.open_in_splits = function(top_left, bottom_left, right)
    vim.cmd("tabnew")
    vim.cmd("edit " .. top_left)
    vim.cmd("sp " .. bottom_left)
    vim.cmd("vert bo sp " .. right)
end


M.open_layout = function()
    local paths = {}
    for key, value in pairs(M.get_file_names()) do
        assert(M.suffix[key], "Could not find key "..key.." in suffixes")
        paths[key] = M.get_existing_file_path(value, M.root_dir.."/"..M.suffix[key])
    end
    M.open_in_splits(paths.day, paths.month, paths.week)
end

M.setup = function()
    vim.api.nvim_create_user_command("OpenPlanningLayout", M.open_layout, { desc = "Open planning layout" })
end

return M
