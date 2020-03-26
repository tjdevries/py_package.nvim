
function! s:py_package_complete(A, L, P) abort
  return luaeval("require('py_package').command_complete(_A.A, _A.L, _A.P)", {
        \ "A": a:A,
        \ "L": a:L,
        \ "P": a:P
        \ })
endfunction

function! s:py_package_find_package(mod_name, modifiers) abort
  let filename = luaeval("require('py_package').find(_A)", a:mod_name)

  call execute(a:modifiers . ' new ' . filename)
endfunction

command! -complete=customlist,<SID>py_package_complete -nargs=1 PyPackcageFind call <SID>py_package_find_package(<q-args>, <q-mods>)

let s:custom_sink = { lines ->
                        \ fzf_preview#handler#handle_resource(
                          \ lines,
                          \ 0,
                          \ 0,
                          \ {x -> luaeval('require("py_package").transform_mod_name(_A)', x)})
                        \ }

function! s:fzf_preview_packages() abort
  let files = luaeval('require("py_package").list_possible_modules()')
  call fzf_preview#runner#fzf_run({
        \ 'prompt': 'Module Name',
        \ 'sink': s:custom_sink,
        \ 'source': files,
        \ })
endfunction

command! PyPackagePreview call <SID>fzf_preview_packages()
