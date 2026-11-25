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

This plugin has been tested on **Conda 23.3.1** and it work-ish on such a release.
Work-ish means that there could be some use-cases where it performs poorly.


## Requirements
You need *conda* and *Vim9*.<br>
Vim's Python interface is not used.

> [!NOTE]
> Vim may be started from any shell, including the *base* environment or one
> where `conda` has not been initialized. In that case the plugin starts on
> the `base` environment, which is also listed as `base` by
> `:CondaActivate`.


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
