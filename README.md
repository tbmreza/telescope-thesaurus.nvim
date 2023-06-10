# Neovim Telescope Thesaurus

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

Bind the lookup command to a keymapping, e.g.:

```lua
vim.keymap.set('n', '<localleader>k', '<cmd>Telescope thesaurus lookup<CR>')
```

Enjoy!

[Neovim]: https://github.com/neovim/neovim
[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
