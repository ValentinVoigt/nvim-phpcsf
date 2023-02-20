# nvim-phpcsf

## What is nvim-phpcsf?
`nvim-phpcsf` is a simple nvim plugin wrapper for both phpcs and phpcbf. The PHP_CodeSniffer's output is populated using the telescope picker. Telescope helps to navigate through phpcs errors and warnings and preview.


## Installation
Install [telescope](https://github.com/nvim-telescope/telescope.nvim) and [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer).
```
-- vim-plug
Plug 'ValentinVoigt/nvim-phpcsf'

-- vim-packer
use({ "ValentinVoigt/nvim-phpcsf" })
```


## Running manually
To run sniffer
```
:lua require'phpcs'.cs()
```

To run beautifier
```
:lua require'phpcs'.cbf()
```

## Configuration
To run PHP_CodeBeautifier after save (It is recommended to run this after the buffer has been written BufWritePost)
```
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    pattern = "*.php",
    callback = function()
        require'phpcs'.cs()
    end,
})
```

## Thanks
[@thePrimeagen](https://github.com/theprimeagen)
[@tjDevries](https://github.com/tjDevries)
[@ValentinVoigt](https://github.com/ValentinVoigt)
