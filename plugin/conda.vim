vim9script noclear

# Activate conda environments inside Vim.
# Maintainer:	Ubaldo Tiberi
# License: BSD3-Clause.

if !has('vim9script') ||  v:version < 900
    # Needs Vim version 9.0 and above
    echo "You need at least Vim 9.0"
    finish
endif

if exists('g:conda_loaded')
    finish
endif
g:conda_loaded = true

# Initialize Conda info.
if !exists('g:conda_info')
    g:conda_info = json_decode(system('conda info --json'))
endif

if !exists('g:conda_base_prefix')
    g:conda_base_prefix = g:conda_info["conda_prefix"]
    # This syntax appear to work both on Windows and Linux/OSX.
    # This should be where conda command is located.
    $CONDA_PREFIX = g:conda_base_prefix
endif

if !exists('g:conda_current_env')
    # Vim may be started from a shell where conda has not been initialized;
    # in that case there is no $CONDA_DEFAULT_ENV and we are on base.
    g:conda_current_env = $CONDA_DEFAULT_ENV ==# "" ? "base" : $CONDA_DEFAULT_ENV
endif

if !exists('g:conda_current_prefix')
    # Rely on g:conda_base_prefix rather than $CONDA_PREFIX, which may be unset.
    if g:conda_current_env ==# "base"
        g:conda_current_prefix = g:conda_base_prefix
    elseif has('win32')
        g:conda_current_prefix = g:conda_base_prefix .. "\\envs\\" .. g:conda_current_env
    else
        g:conda_current_prefix = g:conda_base_prefix .. "/envs/" .. g:conda_current_env
    endif
endif

if !exists('g:conda_prefixes') && !exists('g:conda_envs')
    g:conda_prefixes = g:conda_info["envs"]
    g:conda_envs = []
    for env in g:conda_prefixes
        # The base prefix is normally named after the install (Anaconda3,
        # Miniconda3, ...); expose it as "base" so that `:CondaActivate base`
        # works the same as $CONDA_DEFAULT_ENV does.
        add(g:conda_envs, env ==# g:conda_base_prefix ? "base" : fnamemodify(env, ":t"))
    endfor
endif

# ---------------------------------------------------
# Init
import autoload "../lib/condafuncs.vim"

if has('win32')
    condafuncs.SetEnvVariablesWin(g:conda_current_env, g:conda_current_prefix)
else
    condafuncs.SetEnvVariables(g:conda_current_env, g:conda_current_prefix)
endif

# --------------------------------------------------------
# API
if !exists(":CondaActivate")
    command -nargs=? -complete=customlist,condafuncs.CondaComplete
                \ CondaActivate call <SID>condafuncs.CondaActivate(<f-args>)
endif
