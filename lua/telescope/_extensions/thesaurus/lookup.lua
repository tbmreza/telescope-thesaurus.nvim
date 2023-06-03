-- Telescope-thesaurus
-- https://github.com/rafi/telescope-thesaurus.nvim

local M = {}

-- Make new picker and fetch suggestions.
---@private
---@param word string
---@param opts table
M._new_picker = function(word, opts)
	local actions = require('telescope.actions')
	local action_state = require('telescope.actions.state')
	local suggestions = M._get_synonyms(word)

	if not suggestions then
		return
	end

	require('telescope.pickers').new(opts, {
		layout_strategy = 'cursor',
		layout_config = { width = 0.27, height = 0.55 },
		prompt_title = '[ Thesaurus: '.. word ..' ]',
		finder = require('telescope.finders').new_table({ results = suggestions }),
		sorter = require('telescope.config').values.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				if selection == nil then
					require('telescope.utils').__warn_no_selection('builtin.thesaurus')
					return
				end

				action_state.get_current_picker(prompt_bufnr)._original_mode = 'i'
				actions.close(prompt_bufnr)
				vim.cmd('normal! ciw' .. selection[1])
				vim.cmd 'stopinsert'
			end)
			return true
		end,
	})
	:find()
end

function expect(t)
	if t == nil then
		vim.notify('unexpected structure', vim.log.levels.ERROR)
		return
	else
		return t
	end
end

function parse_syn_list_item(t)
	local syn = expect(t.wd)

	if syn == nil then
		return ''
	end
	return syn
end

function parse_synonyms(t)
	local syn_list = expect(t[0].def[0].sseq[0][0][1].syn_list[0])

	local res = {}
	for item in syn_list do
		local parsed = parse_syn_list_item(item)
		if not (parsed == '') then
			table.insert(res, parsed)
		end
	end

	return res
end

function assert_list_of_words(t)
	-- Warn unexpected structure if input is not a flat list of words.
	local ok = true
	return ok, t
end

function get_dictionaryapi(word)
	local api_route = 'https://www.dictionaryapi.com/api/v3/references/thesaurus/json/'
	local key_env = vim.env.DICTIONARYAPI_KEY or ''
	local key_str = '?key=' .. key_env

	-- Construct string of the following format:
	-- https://www.dictionaryapi.com/api/v3/references/thesaurus/json/<WORD>?key=<API_KEY>
	local url = api_route .. word .. key_str
	vim.notify(url, vim.log.levels.DEBUG)

	local response = require('plenary.curl').get(url)
	if not (response and response.body) then
		vim.notify('failed getting dictionaryapi.com', vim.log.levels.INFO)
		return
	end

	local ok, response_body = pcall(vim.json.decode, response.body)
	if not (ok and response_body) then
		vim.notify('failed decoding response body', vim.log.levels.ERROR)
		return
	end

	return ok, response_body
end

M._picker_contents = function(word)
	local ok, response_body = get_dictionaryapi(word)

	if ok then
		is_flat_list, t = assert_list_of_words(response_body)
		if is_flat_list then
			return t
		else
			return parse_synonyms(response_body)
		end
	end

	vim.notify('unexpected response body structure', vim.log.levels.INFO)
	return
end

M._staging_picker = function(word, opts)
	local actions = require('telescope.actions')
	local action_state = require('telescope.actions.state')
	local contents = M._picker_contents(word)

	if not contents then
		return
	end

	require('telescope.pickers').new(opts, {
		layout_strategy = 'cursor',
		layout_config = { width = 0.27, height = 0.55 },
		prompt_title = '[ synonyms for `'.. word ..'` ]',
		finder = require('telescope.finders').new_table({ results = contents }),
		sorter = require('telescope.config').values.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				if selection == nil then
					require('telescope.utils').__warn_no_selection('builtin.thesaurus')
					return
				end

				action_state.get_current_picker(prompt_bufnr)._original_mode = 'i'
				actions.close(prompt_bufnr)
				vim.cmd('normal! ciw' .. selection[1])
				vim.cmd 'stopinsert'
			end)
			return true
		end,
	})
	:find()
end

-- Lookup words in thesaurus.com
---@private
---@param word string
---@return table?
M._get_synonyms = function(word)
	local url = 'https://www.thesaurus.com/browse/' .. word
	local response = require('plenary.curl').get(url)
	if not (response and response.body) then
		vim.notify('Unable to fetch from thesaurus.com', vim.log.levels.ERROR)
		return
	end

	local json_raw = response.body
		:match('window.INITIAL_STATE = (.*);')
		:gsub('undefined', 'null')
	if not json_raw then
		vim.notify('Unable to parse response', vim.log.levels.ERROR)
		return
	end
	local ok, decoded = pcall(vim.json.decode, json_raw)
	if not ok or decoded == nil or not decoded.searchData then
		vim.notify('Unable to decode response', vim.log.levels.ERROR)
		return
	end
	local data = decoded.searchData.tunaApiData
	if data == vim.NIL then
		local msg = ''
		if decoded.searchData.pageName == 'misspelling' then
			local suggestions = decoded.searchData.spellSuggestionsData
			if #suggestions > 0 then
				msg = 'Did you mean "'..suggestions[1].term..'"?'
				if #suggestions > 1 then
					msg = msg .. ' or "'..suggestions[2].term..'"?'
				end
			end
		end
		vim.notify(msg, vim.log.levels.WARN, { title = 'No definition available' })
		return
	end

	local synonyms = {}
	for _, tab in ipairs(data.posTabs) do
		for _, synonym in ipairs(tab.synonyms) do
			if synonym.term then
				table.insert(synonyms, synonym.term)
			end
		end
		break
	end
	return synonyms
end

--- Lookup word under cursor.
---@param opts table
M.lookup = function(opts)
	local cursor_word = vim.fn.expand('<cword>')
	M._new_picker(cursor_word, opts)
end

--- Query word manually.
---@param opts table<string, string>
M.query = function(opts)
	if not opts.word then
		vim.notify('You must specify a word', vim.log.levels.ERROR)
	end
	M._new_picker(opts.word, opts)
end

--- Use Merriam-Webster Collegiate API backend.
M.staging = function(opts)
	if not opts.word then
		vim.notify('You must specify a word', vim.log.levels.ERROR)
	end
	M._staging_picker(opts.word, opts)
end

return M
