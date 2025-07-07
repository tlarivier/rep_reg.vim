# rep_reg.vim - The Enlightened Way

> *"Simplicity is the ultimate sophistication."* - Leonardo da Vinci

Edit Vim registers in dedicated buffers.

## Philosophy

This plugin follows the **Vim way**:
- No bloat, no complexity, no enterprise features
- Just register editing in buffers - nothing more, nothing less

## Features

- Edit any Vim register in a dedicated buffer
- Preserve register types (character-wise, line-wise, block-wise)
- Clean buffer names: `[Register clipboard]`, `[Register a]`
- Native Vim error codes (E1234, E1235, E1236)
- Zero global state pollution

## Quick Start

```vim
" Edit register 'a'
:EditRegister a

" Edit clipboard
:EditRegister +

```

## Commands

- `:EditRegister {reg}` - Edit register in buffer  
- `:RepRegList` - Show all register buffers

## Installation

```bash
# Copy to your Vim pack directory
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/tlarivier/rep_reg.vim.git
```

## Configuration

**Optional configuration:**

```vim
" Disable default 'gr' mappings if you prefer your own
let g:rep_reg_no_default_mappings = 1

" Custom mapping prefix (default: 'gr')
let g:rep_reg_map_prefix = '<leader>r'
```

## Mappings

**Default mappings (prefix: `gr`):**

- `gra` - Edit register 'a'
- `grb` - Edit register 'b'  
- `gr"` - Edit unnamed register
- `gr+` - Edit clipboard
- `grl` - List register buffers

## Usage

```vim
" Edit a register
:EditRegister a

" Save changes
<C-S> or :RegSave

" List all register buffers
:RepRegList
```

