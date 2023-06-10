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

function parse_synonyms(obj) --> Vec<String>
	-- body[1].meta.syns
	local first_meaning = obj[1].meta.syns
	-- expect list of string
	local ls = {}
	for key, value in pairs(first_meaning) do
		ls[key] = value
	end


	-- local s1 = obj.body
	-- if s1 == nil then
	-- 	for key, value in pairs(obj) do
	-- 		vim.notify('obj has '..key, vim.log.levels.DEBUG)
	-- 	end
	-- end
  --
	-- local s2 = s1[0]
	-- if s2 == nil then
	-- 	for key, value in pairs(s1) do
	-- 		vim.notify('s1 has '..key, vim.log.levels.DEBUG)
	-- 	end
	-- end
  --
	-- local s3 = s2.meta
	-- if s3 == nil then
	-- 	for key, value in pairs(s2) do
	-- 		vim.notify('s2 has '..key, vim.log.levels.DEBUG)
	-- 	end
	-- end

	return nil
end

-- Input is a list of suggestions if it decodes to a list of primitive json string.
-- input = {"word", "ward"}
function verify_list_of_suggestions(obj) -- is_list_of_words, obj
	-- for key, value in pairs(obj) do
	-- 	vim.notify('verify_list_of_suggestions: '..key, vim.log.levels.DEBUG)
	-- end

	-- if obj.body == nil then
	-- 	return false, nil
	-- end
  --
	-- local first = obj.body[0]
  --
	-- if not (type(first) == 'string')
  --
	-- if not (type(obj.body[0]) == "string") then
	-- 	return false, obj
	-- end

	return true, obj
end

-- Repeat calling json.decode on nested json string.
function decode_response_body(response_str) -- Vec<String> | Model
	-- body[1].meta.syns
	return {{meta = {syns = {{"air", "pair"}}}}, {meta = {syns = {{"ear", "panda"}}}}}
	-- -- body[1]
	-- return {"ward", "wird"}

	-- local decode_ok, obj = pcall(vim.json.decode, response_str)
  --
	-- if decode_ok then
	-- 	-- Continue decoding if obj[0] is not a primitive json string.
	-- 	vim.notify('expect type table', vim.log.levels.INFO)
	-- 	vim.notify(type(obj), vim.log.levels.INFO)
  --
	-- 	local first = obj[0]
	-- end
end

function test()

	local ss = get_dictionaryapi('hello')
	local ok, str = pcall(vim.json.encode, ss)
	vim.notify(str, vim.log.levels.DEBUG)
	vim.notify('expect above encode ok', vim.log.levels.DEBUG)

	local success, obj = pcall(vim.json.decode, str)
	if success then
		vim.notify('decode success', vim.log.levels.DEBUG)
	else
		vim.notify('decode failed', vim.log.levels.DEBUG)
	end

	vim.notify(type(obj), vim.log.levels.DEBUG)

	for key, value in pairs(obj) do
		print(key)
	end

	-- local ok, decoded = pcall(vim.json.decode, response.body)
	-- local decoded = vim.json.decode(response.body)
	-- if not (ok and decoded) then
	-- 	vim.notify('failed decoding response body', vim.log.levels.ERROR)
	-- 	return
	-- end
	-- return ok, response.body, decoded
	-- return ok, decoded

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
		return false, nil
	end
	return true, response
end

M._picker_contents = function(word)
	local ok, response = get_dictionaryapi(word)
	if not ok then
		return "[ network error ]", {""}
	end

	-- plenary.curl returns a table containing the key "body" whose value is a json string.
	-- Here we json.encode response so that the whole thing is a json string.
	local encode_ok, response_str = pcall(vim.json.encode, response)
	if not encode_ok then
		vim.notify('internal error', vim.log.levels.ERROR)
	end

	local body_as_obj = decode_response_body(response_str)

	-- The API responds with body in one of the following formats.
	--
	-- - A Model;
	local is_model, synonyms = parse_synonyms(body_as_obj)
	if is_model then
		return "[ synonyms for `"..word.."` ]", synonyms
	end
	-- - A list of primitive json string.
	local is_list_of_suggestions, suggestions = verify_list_of_suggestions(body_as_obj)
	if is_list_of_suggestions then
		return "[ couldn't find `"..word.."` ]", suggestions
	end

	vim.notify('unexpected response', vim.log.levels.ERROR)
	return "", {""}
end

M._staging_picker = function(word, opts)
	local actions = require('telescope.actions')
	local action_state = require('telescope.actions.state')
	-- local contents = M._picker_contents(word)
	local picker_prompt_title, contents = M._picker_contents(word)

	if not contents then
		return
	end

	require('telescope.pickers').new(opts, {
		layout_strategy = 'cursor',
		layout_config = { width = 0.27, height = 0.55 },
		-- prompt_title = '[ synonyms for `'.. word ..'` ]',
		prompt_title = picker_prompt_title,
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

M.test = test

return M
