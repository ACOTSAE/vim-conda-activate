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

# Nothing is initialized at startup.  On first use the environment lists are
# read from disk; conda itself is only queried when an activation cannot be
# resolved from those lists.
import autoload "../lib/condafuncs.vim"

# --------------------------------------------------------
# API
if !exists(":CondaActivate")
    command -nargs=? -complete=customlist,condafuncs.CondaComplete
                \ CondaActivate call <SID>condafuncs.CondaActivate(<f-args>)
endif
