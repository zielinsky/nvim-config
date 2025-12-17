return {
  {
    'scalameta/nvim-metals',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ft = { 'scala', 'sbt', 'java' },
    config = function()
      local metals = require 'metals'
      local metals_config = metals.bare_config()

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, 'blink.cmp')
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end
      metals_config.capabilities = capabilities

      local current_settings = {
        showImplicitArguments = true,
        showImplicitConversionsAndClasses = true,
        showInferredType = true,
        superMethodLensesEnabled = true,
        inlayHints = {
          hintsXRayMode = { enable = false },
          byNameParameters = { enable = false },
          closingLabels = { enable = false },
          hintsInPatternMatch = { enable = false },
          implicitArguments = { enable = false },
          implicitConversions = { enable = false },
          inferredTypes = { enable = false },
          namedParameters = { enable = false },
          typeParameters = { enable = false },
        },
      }

      metals_config.settings = current_settings
      metals_config.init_options.statusBarProvider = 'on'

      metals_config.on_attach = function(client, bufnr)
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        if client.server_capabilities.codeLensProvider then
          vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
            buffer = bufnr,
            callback = function()
              vim.lsp.codelens.refresh { bufnr = bufnr }
            end,
            group = vim.api.nvim_create_augroup('MetalsCodeLens', { clear = true }),
          })
        end
        vim.keymap.set('n', 'm', function()
          local function show_menu(items, title, callback_override)
            vim.ui.select(items, {
              prompt = title,
              format_item = function(item)
                return item.label
              end,
            }, function(choice)
              if choice then
                if callback_override then
                  callback_override(choice)
                else
                  choice.func()
                end
              end
            end)
          end

          local function open_navigation_menu()
            local items = {
              {
                label = 'Go to Definition',
                func = function()
                  vim.lsp.buf.definition()
                end,
              },
              {
                label = 'Go to Type Definition',
                func = function()
                  vim.lsp.buf.type_definition()
                end,
              },
              {
                label = 'Go to Implementation',
                func = function()
                  vim.lsp.buf.implementation()
                end,
              },
              {
                label = 'Find References',
                func = function()
                  vim.lsp.buf.references()
                end,
              },
              {
                label = 'Document Symbols',
                func = function()
                  vim.lsp.buf.document_symbol()
                end,
              },
              {
                label = 'Workspace Symbols',
                func = function()
                  vim.lsp.buf.workspace_symbol()
                end,
              },
            }
            show_menu(items, 'Metals Navigation')
          end

          local function open_refactoring_menu()
            local items = {
              {
                label = 'Rename',
                func = function()
                  vim.lsp.buf.rename()
                end,
              },
              {
                label = 'Code Action',
                func = function()
                  vim.lsp.buf.code_action()
                end,
              },
              {
                label = 'Format',
                func = function()
                  vim.lsp.buf.format()
                end,
              },
            }
            show_menu(items, 'Refactoring')
          end

          local function open_testing_menu()
            local items = {
              {
                label = 'Run/Debug Test (CodeLens)',
                func = function()
                  vim.lsp.codelens.run()
                end,
              },
              {
                label = 'DAP Continue',
                func = function()
                  local dap_status, dap = pcall(require, 'dap')
                  if dap_status then
                    dap.continue()
                  else
                    vim.notify('Nvim-dap not installed', vim.log.levels.WARN)
                  end
                end,
              },
              {
                label = 'DAP Toggle Breakpoint',
                func = function()
                  local dap_status, dap = pcall(require, 'dap')
                  if dap_status then
                    dap.toggle_breakpoint()
                  end
                end,
              },
            }
            show_menu(items, 'Testing')
          end

          local function open_settings_toggles_menu()
            local function label(name, val)
              local status = val and '✅ [ON] ' or '❌ [OFF] '
              return status .. name
            end

            local options_map = {
              { name = 'Show Implicit Arguments', key = 'showImplicitArguments' },
              { name = 'Show Implicit Conversions', key = 'showImplicitConversionsAndClasses' },
              { name = 'Show Inferred Type', key = 'showInferredType' },
              { name = 'Super Method Lenses', key = 'superMethodLensesEnabled' },
              { name = 'Inlay: Inferred Types', nested = 'inferredTypes' },
              { name = 'Inlay: Implicit Arguments', nested = 'implicitArguments' },
              { name = 'Inlay: Implicit Conversions', nested = 'implicitConversions' },
              { name = 'Inlay: Type Parameters', nested = 'typeParameters' },
              { name = 'Inlay: Named Parameters', nested = 'namedParameters' },
              { name = 'Inlay: XRay mode', nested = 'hintsXRayMode' },
              { name = 'Inlay: Hints inside Pattern Match', nested = 'hintsInPatternMatch' },
            }

            local items = {}
            for _, opt in ipairs(options_map) do
              local current_val
              if opt.nested then
                current_val = current_settings.inlayHints[opt.nested].enable
              else
                current_val = current_settings[opt.key]
              end

              table.insert(items, {
                label = label(opt.name, current_val),
                option = opt,
              })
            end

            show_menu(items, 'Toggle Metals Settings', function(choice)
              local opt = choice.option

              if opt.nested then
                local val = current_settings.inlayHints[opt.nested].enable
                current_settings.inlayHints[opt.nested].enable = not val
              else
                local val = current_settings[opt.key]
                current_settings[opt.key] = not val
              end

              client.notify('workspace/didChangeConfiguration', { settings = current_settings })

              vim.notify('Zmieniono: ' .. opt.name, vim.log.levels.INFO)

              open_settings_toggles_menu()
            end)
          end

          local function open_metals_commands_menu()
            local items = {
              {
                label = 'Settings Toggles',
                func = open_settings_toggles_menu,
              },
              {
                label = 'Metals Info',
                func = function()
                  vim.cmd 'MetalsInfo'
                end,
              },
              {
                label = 'Metals Doctor',
                func = function()
                  vim.cmd 'MetalsRunDoctor'
                end,
              },
              {
                label = 'Metals Switch BSP',
                func = function()
                  vim.cmd 'MetalsSwitchBsp'
                end,
              },
              {
                label = 'Metals Restart Build',
                func = function()
                  vim.cmd 'MetalsRestartBuild'
                end,
              },
              {
                label = 'Organize Imports',
                func = function()
                  vim.cmd 'MetalsOrganizeImports'
                end,
              },
            }
            show_menu(items, 'Metals Commands')
          end

          local main_items = {
            { label = 'Navigation...', func = open_navigation_menu },
            { label = 'Refactoring...', func = open_refactoring_menu },
            { label = 'Testing...', func = open_testing_menu },
            { label = 'Metals Commands...', func = open_metals_commands_menu },
          }
          show_menu(main_items, 'Metals Main Menu')
        end, { buffer = bufnr, desc = 'Metals Menu' })

        local dap_ok = pcall(require, 'dap')
        if dap_ok then
          metals.setup_dap()
        end
      end

      local group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'scala', 'sbt', 'java' },
        callback = function()
          metals.initialize_or_attach(metals_config)
        end,
        group = group,
      })
    end,
  },
}
