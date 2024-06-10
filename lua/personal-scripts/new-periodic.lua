-- TODO Some of this file is duplicated from planning-layout.lua, move to a common file and require it here
local M = {
    config = {
        root_dir = "01 Periodic notes",
        extension = ".md",
        day = {
            subdirectory = "daily",
            to_string = function(now)
                return os.date("%Y-%m-%d", now)
            end,
        },
        week = {
            subdirectory = "weekly",
            to_string = function(now)
                local now_table = os.date("*t", now)
                local week = math.ceil(now_table.yday / 7)
                return now_table.year .. "-W" .. week -- There's no convenience method to get the week number with os.date
            end,
        },
        month = {
            subdirectory = "monthly",
            to_string = function(now)
                return os.date("%Y-%m", now)
            end,
        },
    },
}

M.build_path = function(name, key, include_extension)
    include_extension = include_extension == nil and true or false
    local path = M.config.root_dir .. "/" .. M.config[key].subdirectory .. "/" .. name
    if include_extension then
        path = path .. M.config.extension
    end
    return vim.fs.normalize(path)
end

M.create_or_open_note = function(path, content)
    if (vim.uv or vim.loop).fs_stat(path) then
        vim.cmd("edit " .. path)
    else
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
        vim.cmd("buffer " .. buf)
        vim.cmd("write " .. path)
    end
end

------------ Daily ------------

M.get_daily_dates = function(offset)
    assert(type(offset) == "number", "Offset value should be a number")
    offset = math.floor(offset)

    -- Strip away time hours info (i.e. only keep date info)
    local now_table = os.date("*t", os.time())
    local today = os.time({ year = now_table.year, month = now_table.month, day = now_table.day + offset })
    local yesterday = os.time({ year = now_table.year, month = now_table.month, day = now_table.day + offset - 1 })
    local tommorow = os.time({ year = now_table.year, month = now_table.month, day = now_table.day + offset + 1 })

    return {
        yesterday = M.config.day.to_string(yesterday),
        today = M.config.day.to_string(today),
        tommorow = M.config.day.to_string(tommorow),
    }
end

M.get_daily_content = function(dates)
    return {
        "---",
        "type: daily",
        'date: "' .. dates.today .. '"',
        "tags:",
        "- daily",
        "- TBP",
        "---",
        "# " .. dates.today,
        "",
        "< [[" .. M.build_path(dates.yesterday, "day", false) .. "|Yesterday]] | [[" .. M.build_path(
            dates.tommorow,
            "day",
            false
        ) .. "|Tommorow]] >",
        "",
        "## Tasks",
        "",
        "## Notes",
    }
end

M.create_or_open_daily_note = function(offset)
    offset = offset and tonumber(offset) or 0
    local dates = M.get_daily_dates(offset)
    local path = M.build_path(dates.today, "day")
    local content = M.get_daily_content(dates)
    M.create_or_open_note(path, content)
end

------------ Weekly ------------

M.get_weekly_dates = function(offset)
    assert(type(offset) == "number", "Offset value should be a number")
    offset = math.floor(offset) * 7 -- Convert from week number to day number

    -- Strip away time hours info (i.e. only keep date info)
    local now_table = os.date("*t", os.time())
    local weekday = (now_table.wday + 5) % 7 -- Sunday is one by default, offset and wrap so Monday to Sunday is [0-7]
    local first_week_day = now_table.day - weekday -- Shift today to Monday of this week
    local this_week = os.time({ year = now_table.year, month = now_table.month, day = first_week_day + offset })
    local last_week = os.time({ year = now_table.year, month = now_table.month, day = first_week_day + offset - 7 })
    local next_week = os.time({ year = now_table.year, month = now_table.month, day = first_week_day + offset + 7 })

    return {
        first_day = M.config.day.to_string(this_week),
        last_week = M.config.week.to_string(last_week),
        this_week = M.config.week.to_string(this_week),
        next_week = M.config.week.to_string(next_week),
    }
end

M.get_weekly_content = function(dates)
    return {
        "---",
        "type: weekly",
        'date: "' .. dates.first_day .. '"',
        "tags:",
        "- weekly",
        "- TBP",
        "---",
        "# " .. dates.this_week,
        "",
        "< [[" .. M.build_path(dates.last_week, "week", false) .. "|Previous week]] | [[" .. M.build_path(
            dates.next_week,
            "week",
            false
        ) .. "|Next week]] >",
        "",
        "## To tackle this week",
    }
end

M.create_or_open_weekly_note = function(offset)
    offset = offset and tonumber(offset) or 0
    local dates = M.get_weekly_dates(offset)
    local path = M.build_path(dates.this_week, "week")
    local content = M.get_weekly_content(dates)
    M.create_or_open_note(path, content)
end

------------ Monthly ------------

M.get_monthly_dates = function(offset)
    assert(type(offset) == "number", "Offset value should be a number")
    offset = math.floor(offset)

    -- Strip away time hours info (i.e. only keep date info)
    local now_table = os.date("*t", os.time())
    local this_month = os.time({ year = now_table.year, month = now_table.month + offset, day = 1 })
    local last_month = os.time({ year = now_table.year, month = now_table.month + offset - 1, day = 1 })
    local next_month = os.time({ year = now_table.year, month = now_table.month + offset + 1, day = 1 })

    return {
        first_day = M.config.day.to_string(this_month),
        last_month = M.config.month.to_string(last_month),
        this_month = M.config.month.to_string(this_month),
        next_month = M.config.month.to_string(next_month),
    }
end

M.get_monthly_content = function(dates)
    return {
        "---",
        "type: monthly",
        'date: "' .. dates.first_day .. '"',
        "tags:",
        "- monthly",
        "- TBP",
        "---",
        "# " .. dates.this_month,
        "",
        "< [[" .. M.build_path(dates.last_month, "month", false) .. "|Previous month]] | [[" .. M.build_path(
            dates.next_month,
            "month",
            false
        ) .. "|Next month]] >",
        "",
        "## To tackle this month",
    }
end

M.create_or_open_monthly_note = function(offset)
    offset = offset and tonumber(offset) or 0
    local dates = M.get_monthly_dates(offset)
    local path = M.build_path(dates.this_month, "month")
    local content = M.get_monthly_content(dates)
    M.create_or_open_note(path, content)
end

------------ Commands ------------

M.setup = function()
    vim.api.nvim_create_user_command("OpenDailyNote", function(opts)
        M.create_or_open_daily_note(opts.fargs[1])
    end, { desc = "Creates or opens today's note", nargs = "?" })

    vim.api.nvim_create_user_command("OpenWeeklyNote", function(opts)
        M.create_or_open_weekly_note(opts.fargs[1])
    end, { desc = "Creates or opens this week's note", nargs = "?" })

    vim.api.nvim_create_user_command("OpenMonthlyNote", function(opts)
        M.create_or_open_monthly_note(opts.fargs[1])
    end, { desc = "Creates or opens this month's note", nargs = "?" })
end

return M
