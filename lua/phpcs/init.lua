local M = {};

local phpcs_path = "phpcs"
local phpcbf_path = "phpcbf"
local phpcs_standard = "PSR2"

local Job = require 'plenary.job'

-- Config Variables
M.phpcs_path = vim.g.nvim_phpcs_config_phpcs_path or phpcs_path
M.phpcbf_path = vim.g.nvim_phpcs_config_phpcbf_paths or phpcbf_path
M.phpcs_standard = vim.g.nvim_phpcs_config_phpcs_standard or phpcs_standard
M.last_stderr = ''
M.last_stdout = ''

M.get_phpcs = function()
    local filename = vim.api.nvim_buf_get_name(0)
    local dirname = vim.fs.dirname(filename)
    local next_phpcs = vim.fs.find('phpcs.xml', {
        path = dirname,
        type = "file",
        upward = true
    })[1]
    local phpcs = next_phpcs or M.phpcs_standard

    return phpcs
end

M.cs = function()
    local bufnr = vim.api.nvim_get_current_buf()

    local opts = {
        command = M.phpcs_path,
        args = {
            "--stdin-path=" .. vim.api.nvim_buf_get_name(bufnr),
            "--report=json", "--standard=" .. M.get_phpcs(), "-n", "-q", "-"
        },
        writer = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true),
        on_exit = vim.schedule_wrap(function(j)
            M.publish_diagnostic(j:result(), bufnr)
        end)
    }

    Job:new(opts):start()
end

M.cbf = function(new_opts)
    new_opts = new_opts or {}
    new_opts.bufnr = new_opts.bufnr or vim.api.nvim_get_current_buf()

    if not new_opts.force then
        if vim.api.nvim_buf_line_count(new_opts.bufnr) > 1000 then
            print("File too large. Ignoring code beautifier")
            return
        end
    end

    local opts = {
        command = M.phpcbf_path,
        args = {
            "--stdin-path=" .. vim.api.nvim_buf_get_name(new_opts.bufnr),
            "--standard=" .. M.phpcs_standard, "-"
        },
        writer = vim.api.nvim_buf_get_lines(new_opts.bufnr, 0, -1, true),
        cwd = vim.fn.getcwd()
    }

    local results, status = Job:new(opts):sync(new_opts.timeout or 1000)

    status = tonumber(status)

    if status <= 1 then
        vim.api.nvim_buf_set_lines(new_opts.bufnr, 0, -1, true, results)
        M.cs()
    else
        error("Failed to run code beautifier")
    end
end

M.publish_diagnostic = function(results, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local diagnostics = parse_json(table.concat(results), bufnr)
    local ns = vim.api.nvim_create_namespace("phpcbf")
    vim.diagnostic.set(ns, bufnr, diagnostics)
end

function parse_json(encoded, bufnr)
    local decoded = vim.json.decode(encoded)
    local diagnostics = {}
    local uri = vim.api.nvim_buf_get_name(bufnr);

    local error_codes = {
        ['error'] = vim.lsp.protocol.DiagnosticSeverity.Error,
        warning = vim.lsp.protocol.DiagnosticSeverity.Warning
    }

    if not decoded.files[uri] then return diagnostics end

    for _, message in ipairs(decoded.files[uri].messages) do
        table.insert(diagnostics, {
            severity = error_codes[string.lower(message.type)],
            lnum = tonumber(message.line) - 1,
            col = tonumber(message.column) - 1,
            message = message.message
        })
    end

    return diagnostics
end

return M
