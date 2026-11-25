vim9script

# ---------------------------------------------------------------
# Lazy initialization.  conda itself is only invoked when the
# environment lists on disk cannot provide the answer.
# ---------------------------------------------------------------

def EnvName(prefix: string): string
    return prefix ==# g:conda_base_prefix ? "base" : fnamemodify(prefix, ":t")
enddef

def BasePrefix(): string
    if $CONDA_EXE !=# ''
        var dir = fnamemodify(fnamemodify($CONDA_EXE, ":h"), ":h")
        if isdirectory(dir)
            return dir
        endif
    endif
    return ""
enddef

def EnvsPathDirs(): list<string>
    if $CONDA_ENVS_PATH ==# ''
        return []
    endif
    return split($CONDA_ENVS_PATH, has('win32') ? ';' : ':')
                \->filter((_, d) => d !=# '')
                \->mapnew((_, d) => expand(d))
enddef

def CondaRcFiles(base: string): list<string>
    return [$CONDARC, expand("~/.condarc"), expand("~/.config/conda/.condarc"),
                \ base .. "/.condarc"]
enddef

def EnvDirsFromCondaRc(base: string): list<string>
    var dirs: list<string> = []
    for file in CondaRcFiles(base)
        if file ==# '' || !filereadable(file)
            continue
        endif
        var in_block = false
        for line in readfile(file)
            if line =~# '^\s*envs_dirs\s*:'
                in_block = true
            elseif !in_block || line =~# '^\s*$' || line =~# '^\s*#'
                continue
            elseif line =~# '^\s*-\s*'
                var dir = substitute(line, '^\s*-\s*', '', '')
                dir = substitute(dir, '\s*#.*$', '', '')
                dir = substitute(dir, '^["'']', '', '')
                dir = substitute(dir, '["'']$', '', '')
                dir = substitute(dir, '\s*$', '', '')
                add(dirs, expand(dir))
            elseif line =~# '^\S'
                break
            endif
        endfor
    endfor
    return dirs
enddef

def EnvsDirs(base: string): list<string>
    var dirs: list<string> = has('win32')
                \ ? [base .. "\\envs", expand("~/.conda/envs")]
                \ : [base .. "/envs", expand("~/.conda/envs"),
                \    expand("~/.local/share/conda/envs")]
    return dirs + EnvsPathDirs() + EnvDirsFromCondaRc(base)
enddef

def PrefixesFromFiles(base: string): list<string>
    var listed: list<string> = []
    var registry = expand("~/.conda/environments.txt")
    if filereadable(registry)
        listed = readfile(registry)
    endif
    for dir in EnvsDirs(base)
        if isdirectory(dir)
            listed += glob(dir .. "/*", 1, 1)
        endif
    endfor

    var prefixes: list<string> = [base]
    var seen: dict<number> = {}
    seen[base] = 1
    for entry in listed
        var prefix = substitute(entry, '[/\\]\+$', '', '')
        if prefix !=# '' && !has_key(seen, prefix) && isdirectory(prefix)
            seen[prefix] = 1
            add(prefixes, prefix)
        endif
    endfor
    return prefixes
enddef

def SetCurrentEnv()
    if !exists('g:conda_current_env')
        g:conda_current_env = $CONDA_DEFAULT_ENV ==# '' ? "base" : $CONDA_DEFAULT_ENV
    endif
    if !exists('g:conda_current_prefix')
        if $CONDA_PREFIX !=# ''
            g:conda_current_prefix = $CONDA_PREFIX
        elseif g:conda_current_env ==# "base"
            g:conda_current_prefix = g:conda_base_prefix
        elseif has('win32')
            g:conda_current_prefix = g:conda_base_prefix .. "\\envs\\" .. g:conda_current_env
        else
            g:conda_current_prefix = g:conda_base_prefix .. "/envs/" .. g:conda_current_env
        endif
    endif
enddef

def InitFromConda()
    g:conda_info = json_decode(system('conda info --json'))
    g:conda_info_from_conda = true
    g:conda_base_prefix = g:conda_info["conda_prefix"]
    g:conda_prefixes = g:conda_info["envs"]
    g:conda_envs = g:conda_prefixes->mapnew((_, p) => EnvName(p))
    SetCurrentEnv()
enddef

def Init()
    if exists('g:conda_base_prefix') && exists('g:conda_envs')
        return
    endif
    var base = BasePrefix()
    if base ==# ''
        # Without a base prefix the PATH cannot be maintained; ask conda.
        InitFromConda()
        return
    endif
    # Synthesized from the files: good enough for listing and completion,
    # not a guarantee that the environments are usable.
    var prefixes = PrefixesFromFiles(base)
    g:conda_info = {"conda_prefix": base, "envs": prefixes}
    g:conda_base_prefix = base
    g:conda_prefixes = prefixes
    g:conda_envs = prefixes->mapnew((_, p) => EnvName(p))
    SetCurrentEnv()
enddef


export def SetEnvVariablesWin(env: string, prefix: string)
    # This should be the only function of the plugin that kinda depends on the
    # OS
    # This is how Windows installs Miniconda: many folders!
    # I expect this to be uniformed to other OS:s in the future
    # This is 'base'
    # C:\Users\yt75534\Miniconda3;
    # C:\Users\yt75534\Miniconda3\Library\mingw-w64\bin;
    # C:\Users\yt75534\Miniconda3\Library\usr\bin;
    # C:\Users\yt75534\Miniconda3\Library\bin;
    # C:\Users\yt75534\Miniconda3\Scripts;
    # C:\Users\yt75534\Miniconda3\bin;

    # This is 'myenv'
    # C:\Users\yt75534\Miniconda3\envs\myenv;
    # C:\Users\yt75534\Miniconda3\envs\myenv\Library\mingw-w64\bin;
    # C:\Users\yt75534\Miniconda3\envs\myenv\Library\usr\bin;
    # C:\Users\yt75534\Miniconda3\envs\myenv\Library\bin;
    # C:\Users\yt75534\Miniconda3\envs\myenv\Scripts;
    # C:\Users\yt75534\Miniconda3\envs\myenv\bin;
    #
    # Then, you have the following that shall be always present
    # C:\Users\yt75534\Miniconda3\condabin;
    #
    # 1) Set environment variables -------------------------------------
    g:conda_current_env = env

    $CONDA_DEFAULT_ENV = env
    $CONDA_PROMPT_MODIFIER = $"({env})"
    $CONDA_PREFIX = prefix

    # Remove old paths
    var path_lst = split($PATH, ';')
    var path_lst_cleaned = path_lst
                \->filter('stridx(v:val, g:conda_current_prefix) != 0')

    # Add new paths
    var path1 = prefix .. "\\Library\\mingw-w64\\bin"
    var path2 = prefix .. "\\Library\\usr\\bin"
    var path3 = prefix .. "\\Library\\bin"
    var path4 = prefix .. "\\Scripts"
    var path5 = prefix .. "\\bin"
    var path6 = "" # This is /condabin for conda command
    # Check if /condabin disappeared
    if index(path_lst_cleaned, g:conda_base_prefix .. "\\condabin") == -1
        path6 = g:conda_base_prefix .. "\\condabin"
    endif
    var conda_paths = [prefix, path1, path2, path3, path4, path5, path6]
    path_lst = conda_paths + path_lst_cleaned
    $PATH = join(path_lst, ';')
    $CONDA_PYTHON_EXE = prefix .. "\\python.exe"

    # 2) Set Vim options ----------------------------------------------
    # var py_ver_dot = system('python --version')
    var py_ver_dot = system($CONDA_PYTHON_EXE .. ' --version')
                \->matchstr('\d\+.\d\+') # e.g. 3.11
    var py_ver_nodot = substitute(py_ver_dot, '\.', '', 'g') # e.g.  311
    &pythonthreehome =  prefix
    &pythonthreedll = prefix .. $"\\python{py_ver_nodot}.dll"


    # 3) Set vim internal sys.path ------------------------------------
    # Remove previous env paths
    # TODO: Not sure if
    # 'C:\Users\yt75534\AppData\Roaming\Python\Python310\site-packages',
    # shall be actually removed.
    g:python_sys_path = py3eval('sys.path')
    g:python_sys_path_cleaned = g:python_sys_path
                \->filter('stridx(v:val, g:conda_current_prefix) != 0')

    # Define new paths
    var sys_path1 = prefix .. $"\\python{py_ver_nodot}.zip"
    var sys_path2 = prefix .. "\\DLLs"
    var sys_path3 = prefix .. "\\lib"
    var sys_path4 = prefix .. "\\lib\\site-packages"
    var sys_path5 = prefix .. "\\lib\\site-packages\\win32"
    var sys_path6 = prefix .. "\\lib\\site-packages\\win32\\lib"
    var sys_path7 = prefix .. "\\lib\\site-packages\\Pythonwin"
    var sys_paths = [prefix, sys_path1, sys_path2, sys_path3,
                \ sys_path4, sys_path5, sys_path6, sys_path7]
    g:python_sys_path = sys_paths + g:python_sys_path_cleaned

    # Add paths to sys.path
    python3 import vim
    python3 sys.path = vim.eval("g:python_sys_path")

    # Refresh variables
    g:conda_current_prefix = prefix

    if exists('#User#CondaEnvActivated')
        doautocmd User CondaEnvActivated
    endif
enddef

export def SetEnvVariables(env: string, prefix: string)

    # 1) Set environment variables ----------------------------
    g:conda_current_env = env

    $CONDA_DEFAULT_ENV = env
    $CONDA_PROMPT_MODIFIER = $"({env})"
    $CONDA_PREFIX = prefix

    # Remove old path (g:conda_current_prefix)
    var path_lst = split($PATH, ':')
    # The following filtering may not be needed because for MacOSX and Linux
    # conda creates only ONE folder and not 200000 like in Windows.
    # You could simply cherry-pick
    #
    #   var old_path = g:conda_current_prefix .. "/bin"
    #   remove(path_lst, index(path_lst, old_path))
    #
    # and use path_lst = [new_path] + path_lst_cleaned
    var path_lst_cleaned = path_lst
                \->filter('stridx(v:val, g:conda_current_prefix) != 0')

    # Add new path (prefix)
    var new_path = prefix .. "/bin"
    # Conda's python on top in case of multiple python installations
    path_lst = [new_path] + path_lst_cleaned
    $PATH = join(path_lst, ':')
    $CONDA_PYTHON_EXE = prefix .. "/bin/python"


    # Refresh variables
    g:conda_current_prefix = prefix
    if exists('#User#CondaEnvActivated')
        doautocmd User CondaEnvActivated
    endif
enddef

def PrefixMap(): dict<string>
    var prefixes: dict<string> = {}
    for prefix in g:conda_prefixes
        prefixes[EnvName(prefix)] = prefix
    endfor
    return prefixes
enddef

def CondaActivateUser(env: string)
    var prefixes = PrefixMap()
    if !has_key(prefixes, env) && !exists('g:conda_info_from_conda')
        # The file based guess was wrong; let conda settle it, once.
        InitFromConda()
        prefixes = PrefixMap()
    endif

    if !has_key(prefixes, env)
        echo $"{env} environment not found."
    elseif has('win32')
        SetEnvVariablesWin(env, prefixes[env])
    else
        SetEnvVariables(env, prefixes[env])
    endif
enddef

def CondaActivatePopupCallback(id: number, env_idx: number)
    # Callback of the popup menu.
    var target_prefix = g:conda_prefixes[env_idx - 1]
    var target_env = EnvName(target_prefix)
    if has('win32')
        SetEnvVariablesWin(target_env, target_prefix)
    else
        SetEnvVariables(target_env, target_prefix)
    endif
enddef


def CondaActivatePopup()
    # Actual popup menu
    popup_menu(g:conda_envs,
        {'title': " envs ",
            'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
            'callback': CondaActivatePopupCallback,
        })
enddef


export def CondaActivate(...env: list<string>)
    Init()
    if empty(env)
        CondaActivatePopup()
    else
        CondaActivateUser(env[0])
    endif
enddef

export def CondaComplete(arglead: string, cmdline: string, cursorPos: number):
            \ list<string>
    # This is used in "command -preview=..." in the plugin file.
    Init()
    return g:conda_envs->filter((_, val) => val =~ $'^{arglead}')
enddef
