" vim:set ts=8 sts=2 sw=2 tw=0 et:

scriptencoding utf-8

let s:pattern0 = [
      \ '┌(┌　^ o^)┐　',
      \ '┌(　┐^ o^)┐　',
      \ '　┐ ┐^ o^)┐　',
      \ '三┌(┌　^ o^)　',
      \ '　┌(┌　^ o^)┐',
      \]
let s:pattern_index = 0
let s:position = 0

function! g:Homoo()
  let width = winwidth('.') / 2
  let spacer = repeat('　', width)
  let whole = spacer.s:pattern0[s:pattern_index].spacer
  let start = strwidth(whole) - width * 2 - s:position * 2
  let last = start + width * 2
  let retval = matchstr(whole, '\%>'.start.'v.*\%<'.last.'v')

  " Update pattern and position for next frame.
  let s:pattern_index += 1
  if s:pattern_index >= len(s:pattern0)
    let s:pattern_index = 0
    let s:position += 1
    if s:position >= winwidth('.') / 2 + 8
      let s:position = 0
    endif
  endif

  return retval
endfunction

set statusline=%{g:Homoo()}
