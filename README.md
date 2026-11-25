<p align="center">
<img src="/LookingFor.svg" width="60%" height="60%">
</p>

# Conda-activate
Activate Conda virtual environments in Vim.

<p align="center">
<img src="/Conda.gif" width="60%" height="60%">
</p>

## Introduction
*Conda-activate* picks the inheritance of
[vim-conda](https://github.com/cjrh/vim-conda) by providing the same features
in a Vim9 fashion.  It further accommodates changes that `conda` experienced
throughout the years.


*Conda-activate* sets various environment variables such as
`$CONDA_DEFAULT_ENV`,
 `$CONDA_PREFIX`, `$PATH`, etc.

This fork of [ubaldot/vim-conda-activate](https://github.com/ubaldot/vim-conda-activate)
is tested on **Linux** with **Conda 24.11.3** and **Vim 9.2**.
The original plugin was tested on Conda 23.3.1 only; the Windows code path
is still untested.


## Requirements
You need *conda* and *Vim9*.<br>
Vim's Python interface is not used.

> [!NOTE]
> The plugin does nothing at startup.  On first use the environment list is
> read from `~/.conda/environments.txt`, the `envs_dirs` of `.condarc` and
> `$CONDA_ENVS_PATH`, and the usual `envs` directories, and `g:conda_info` is
> synthesized from it (an approximate list: entries are only checked for
> existence, not usability).
> `conda info --json` runs only when `:CondaActivate` cannot find the
> requested environment, or when `$CONDA_EXE` is unknown.
> Vim can therefore be started from any shell, including the *base*
> environment or one where `conda` has not been initialized.


## Usage
This plugin has one command `CondaActivate` that takes one (optional) argument:
```
:CondaActivate # Show a popup menu
:CondaActivate myenv # Activate myenv without popup menu
```

It further exposes an *autocommand-event* named `CondaEnvActivated` that
you can use to perform other actions just after you activated a virtual
environment.
Here is a simple example on how to use it:
```
autocmd! User CondaEnvActivated :echom $"{$CONDA_DEFAULT_ENV} activated."
```

## Credits
Thanks to [vim-conda](https://github.com/cjrh/vim-conda) that paved the way.
I would have never done this plugin without reading (and learning)
from [vim-conda](https://github.com/cjrh/vim-conda) source code.


## Contributing
Feel free to send a PR if have any improvement ideas.<br>
For more info check `:h condaactivate.txt`.


## License
BSD-3 Clause.
