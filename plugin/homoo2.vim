" Author: MURAOKA Taro <koron.kaoriya@gmail.com>

scriptencoding utf-8

let s:COLUMNS = 80
let s:ROWS = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
let s:BLOCKS = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
let s:COLORS = [
      \ [ '#000000',  0 ],
      \ [ '#000080',  1 ],
      \ [ '#008000',  2 ],
      \ [ '#008080',  3 ],
      \ [ '#800000',  4 ],
      \ [ '#800080',  5 ],
      \ [ '#808000',  6 ],
      \ [ '#C0C0C0',  7 ],
      \ [ '#808080',  8 ],
      \ [ '#0000ff',  9 ],
      \ [ '#00ff00', 10 ],
      \ [ '#00ffff', 11 ],
      \ [ '#ff0000', 12 ],
      \ [ '#ff00ff', 13 ],
      \ [ '#ffff00', 14 ],
      \ [ '#ffffff', 15 ]
      \]

function! s:Game()
  let doc = s:GameOpen()
  call s:GameMain(doc)
  echo s:GameClose(doc)
endfunction

function! s:GameOpen()
  if !exists("g:homoo_display_statusline")
    let g:homoo_display_statusline = 0
  endif
  let s:lazyredraw_value = &lazyredraw
  let s:laststatus_value = &laststatus
  let s:cmdheight_value = &cmdheight
  let s:undolevels_value = &undolevels
  let s:list_value = &list
  enew
  set lazyredraw
  setlocal buftype=nofile noswapfile
  if g:homoo_display_statusline == 0
    set laststatus=0 cmdheight=1
  endif
  set undolevels=-1
  setlocal nolist
  " Initialize screen buffer
  "call s:ColorInit()
  let doc = s:GameDocNew()
  call s:GDocInit(doc)
  return doc
endfunction

function! s:GameDocNew()
  let doc = {}
  let doc.width = winwidth('.') - &foldcolumn
  let doc.backgroundBuffer = []
  let s = repeat(' ', doc.width)
  for i in s:ROWS
    call add(doc.backgroundBuffer, s)
  endfor
  let doc.screenBuffer = copy(doc.backgroundBuffer)
  return doc
endfunction

function! s:GameMain(doc)
  let running = 1
  while running
    call s:GameDraw(a:doc)
    execute 'sleep ' . a:doc.wait
    let a:doc.screenBuffer = copy(a:doc.backgroundBuffer)
    let running = s:GDocUpdate(a:doc, getchar(0))
  endwhile
endfunction

function! s:GameDraw(doc)
  let last = line('$')
  call append(last, a:doc.screenBuffer)
  silent execute "1,".last."d _"
  redraw
endfunction

function! s:GameClose(doc)
  call s:GDocFinal(a:doc)
  let &lazyredraw = s:lazyredraw_value
  let &laststatus = s:laststatus_value
  let &cmdheight = s:cmdheight_value
  let &undolevels = s:undolevels_value
  let &list = s:list_value
  return get(a:doc, 'title', 'GAME END')
endfunction

function! s:ColorInit()
  syntax clear
  let idx = 0
  while idx < len(s:BLOCKS)
    if idx < len(s:COLORS)
      let gcolor = s:COLORS[idx][0]
      let ccolor = s:COLORS[idx][1]
    else
      let gcolor = s:COLORS[0][0]
      let ccolor = s:COLORS[0][1]
    endif
    call s:ColorSet(idx, gcolor, ccolor)
    let idx = idx + 1
  endwhile
endfunction

function! s:ColorSet(idx, gcolor, ccolor)
  if type(a:idx) == 0
    let idx2 = a:idx
  else
    let idx2 = stridx(s:BLOCKS, a:idx)
  endif
  if idx2 < 0 || idx2 >= strlen(s:BLOCKS)
    return
  endif

  let target = s:BLOCKS[idx2]
  let name = 'gameBlock'.idx2
  let target = escape(target, '/\\*^$.~[]')
  execute 'syntax match '.name.' /'.target.'/'
  execute 'highlight '.name." guifg='".a:gcolor."'"
  execute 'highlight '.name." guibg='".a:gcolor."'"
  execute 'highlight '.name." ctermfg='".a:ccolor."'"
  execute 'highlight '.name." ctermbg='".a:ccolor."'"
endfunction

"===========================================================================
" GDoc functions.

function! s:GDocInit(doc)
  let a:doc.title = 'Homoo2'
  let a:doc.wait = '33m'
  let a:doc.agents = []
  let a:doc.random_seed = 123456
  for id in s:ROWS
    call add(a:doc.agents, s:HomooNew(a:doc, id))
  endfor
endfunction

function! s:GDocUpdate(doc, ev)
  " Check termination.
  if a:ev == 27
    return 0
  endif

  for agent in a:doc.agents
    call s:HomooDraw(a:doc, agent)
  endfor
  for agent in a:doc.agents
    call s:HomooUpdate(a:doc, agent)
  endfor

  return 1
endfunction

function! s:GDocFinal(doc)
  " Finalize game document (ex. save high score, etc).
endfunction

"===========================================================================
" Homoo functions.

let s:HOMOO_PATTERN = [
      \ '┌(┌  ^ o^)┐ﾎ ',
      \ '┌(  ┐^ o^)┐ﾓ ',
      \ '  ┐ ┐^ o^)┐ｫ ',
      \ '三┌(┌  ^ o^)  ',
      \ '  ┌(┌  ^ o^)┐',
      \]

function! s:HomooNew(doc, id)
  let homoo = {}
  let homoo.pindex = 0
  let homoo.pos = 0
  let homoo.line = a:id
  let homoo.speed = s:HomooRandom(a:doc, 10) * 5 + 55
  return homoo
endfunction

function! s:HomooDraw(doc, agent)
  let str = a:doc.screenBuffer[a:agent.line]

  let start = a:agent.pos * 2
  let end = start + 18
  let ptrn = s:HOMOO_PATTERN[a:agent.pindex]
  let str = substitute(str, '\%>'.start.'v.*\%<'.end.'v', ptrn, '')

  let a:doc.screenBuffer[a:agent.line] = str
endfunction

function! s:HomooUpdate(doc, agent)
  if s:HomooRandom(a:doc, 100) >= a:agent.speed
    return
  endif
  let a:agent.pindex += 1
  if a:agent.pindex >= len(s:HOMOO_PATTERN)
    let a:agent.pindex = 0
    let a:agent.pos += 1
    if a:agent.pos >= a:doc.width / 2 - 7
      let a:agent.pos = 0
      let a:agent.speed = s:HomooRandom(a:doc, 10) * 5 + 55
    endif
  endif
endfunction

function! s:HomooRandom(doc, max)
  let n = and((a:doc.random_seed * 214013 + 2531011) / 65536, 0x7fff)
  let a:doc.random_seed = n
  return n % a:max
endfunction

"===========================================================================
" Start the game.

function! HomooStart()
  call s:Game()
endfunction

call HomooStart()

" vim:set ts=8 sts=2 sw=2 tw=0 et:
