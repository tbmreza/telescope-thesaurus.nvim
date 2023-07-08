# Neovim Telescope Naming Assistant

## Demo

[gif]

## Features

Devices and techniques that I sometimes use when reasoning about a naming choice when writing code or otherwise:
- Thesaurus & dictionary
- Contracting a word in several ways
- Spellchecking

[paragraph about spellchecking that respects casing in code]

## Install
- (Optional) Set `$DICTIONARYAPI_KEY`.
    - Sign up for a developer account at Merriam-Webster's website.
    - Have "Collegiate Thesaurus" as one of your requested features.
    - Check if nvim reads the env variable correctly with `:echo ?? DICTIONARYAPI_KEY`.
-   ```lua
    -- For example, using packer:
    use {
      'tbmreza/telescope-naming-assistant.nvim',
      requires = { 'nvim-telescope/telescope.nvim' }
    }
    ```

## License

[follows telescope's]

> Browse synonyms from thesaurus.com as a [telescope.nvim] extension.

## Install

This fork's preferred backend requires an account at Merriam-Webster's website with thesaurus API key.
1. Sign up
1. Have "Collegiate Thesaurus" as one of your requested features.
1. This plugin reads the environment variable `$DICTIONARYAPI_KEY`; check if nvim reads that correctly with `:echo ?? DICTIONARYAPI_KEY`.

## Warning

- (-) There is a 1000 requests/day limit.
- (-) The free tier may not exist anymore one day.

Alternatively, the parent repo's original method is fetching from thesaurus.com, internally scraping the website front-end.

<details>
<summary>For example with <a href="https://github.com/wbthomason/packer.nvim">packer.nvim</a></summary>

```lua
use {
  'rafi/telescope-thesaurus.nvim',
  requires = { 'nvim-telescope/telescope.nvim' }
}
```

</details>

## Usage

- In normal mode, over a word: `:Telescope thesaurus lookup`
- Query word manually: `:Telescope thesaurus query word=hello`

`:Telescope thesaurus test
prints debug json string

Bind the lookup command to a keymapping, e.g.:

```lua
vim.keymap.set('n', '<localleader>k', '<cmd>Telescope thesaurus lookup<CR>')
```

Enjoy!

[Neovim]: https://github.com/neovim/neovim
[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
