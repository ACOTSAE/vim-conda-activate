# Conda-activate

Activate Conda virtual environments in Vim.

<p align="center">
<img src="/Conda.gif" width="60%" height="60%">
</p>

## Introduction

This is a fork of
[ubaldot/vim-conda-activate](https://github.com/ubaldot/vim-conda-activate),
a Vim9 rewrite of [vim-conda](https://github.com/cjrh/vim-conda).

*Conda-activate* switches the virtual environment used inside Vim.  It keeps
`$CONDA_DEFAULT_ENV`, `$CONDA_PREFIX`, `$PATH` and the related `CONDA_*`
variables in sync with the selected environment, stacks environments like
`conda activate` does, and leaves conda like `conda deactivate`.

Compared with the original plugin this fork:

- does nothing at startup: conda is only touched the first time the plugin is
  used;
- builds the environment list from files (`~/.conda/environments.txt`, the
  `envs_dirs` of `.condarc`, `$CONDA_ENVS_PATH` and the usual `envs`
  directories) instead of running conda;
- runs `conda info --json` only as a fallback, when the requested environment
  is not in that list or `$CONDA_EXE` is unknown;
- does not touch Vim's embedded Python, which used to abort Vim on startup
  when its libpython differed from the environment's Python;
- works when Vim is started from the *base* environment or from a shell where
  conda has not been initialized.

Tested on **Linux** with **Conda 24.11.3** and **Vim 9.2**.
The Windows code path is untested.

## Requirements

You need *conda* and *Vim9*.
Vim's Python interface is not used.

> [!NOTE]
> The plugin does nothing at startup.  On first use the environment list is
> read from the files listed above and `g:conda_info` is synthesized from it
> (an approximate list: entries are only checked for existence, not
> usability).
> `conda info --json` runs only when `:CondaActivate` cannot find the
> requested environment, or when `$CONDA_EXE` is unknown.
> Vim can therefore be started from any shell, including the *base*
> environment or one where `conda` has not been initialized.

## Usage

The plugin provides two commands:

```
:CondaActivate        # Show a popup menu
:CondaActivate myenv  # Activate myenv without popup menu
:CondaDeactivate      # Leave the current environment (conda deactivate)
```

`:CondaActivate` stacks environments like `conda activate`: activating an
environment on top of another one records the previous prefix in
`$CONDA_PREFIX_<n>` and increments `$CONDA_SHLVL`.

`:CondaDeactivate` behaves like `conda deactivate`: it pops back to the
previous environment when environments were stacked, and otherwise leaves
conda entirely (the conda variables are unset and `$CONDA_SHLVL` is 0).
When no environment is active it does nothing.

It further exposes an *autocommand-event* named `CondaEnvActivated` that
you can use to perform other actions just after the environment changed.
Here is a simple example on how to use it:

```
autocmd! User CondaEnvActivated :echom $"{$CONDA_DEFAULT_ENV} activated."
```

## Acknowledgements

- [ubaldot/vim-conda-activate](https://github.com/ubaldot/vim-conda-activate)
  by Ubaldo Tiberi — the upstream project this fork is based on.
- [cjrh/vim-conda](https://github.com/cjrh/vim-conda) — the plugin whose
  features and ideas vim-conda-activate inherits.
- The [conda](https://github.com/conda/conda) project, whose CLI behaviour
  this plugin mirrors.

## Contributing

Feel free to send a PR if you have any improvement ideas.
For more information see `:h condaactivate.txt`.

## License

BSD-3-Clause.  See [LICENSE](LICENSE); copyright of the original work
belongs to its authors.
