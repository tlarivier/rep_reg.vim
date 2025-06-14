# rep\_reg.vim

Edit Vim registers (`"a`, `"b`, etc.) as editable scratch buffers.

## Features

- Open registers with `:EditRegister a` or `gra`
- Edit and save directly to the register
- Configurable key mappings
- pure vim / Neovim support

## Installation

Vim’s built-in package support:

```sh
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/.../rep_reg.vim
````

Then generate the help tags once:

```vim
:helptags ~/.vim/pack/plugins/start/rep_reg.vim/doc
```

You’re done !

> On Neovim: Use `~/.config/nvim/pack/...` instead of `~/.vim/pack/...`

## Configuration

| Option                      | Default     | Description                            |
| --------------------------- | ----------- | -------------------------------------- |
| `g:rep_reg_map_prefix`      | `'gr'`      | Mapping prefix for `gr{char}` bindings |
| `g:rep_reg_enable_mappings` | `1`         | Set to `0` to disable default mappings |
| `g:rep_reg_split`           | `'vertical'`| Split style: `'horizontal'`, `'tab'`   |

## Usage

```vim
:EditRegister a
```

Or press `gra` to edit register `"a"`

## License

Vim license – same spirit as the editor itself.
