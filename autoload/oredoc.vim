let s:save_cpo = &cpo
set cpo&vim

let s:V       = vital#of('oredoc')
let s:Process = s:V.import('Process')

let g:oredoc#hostname = get(g:, 'oredoc#hostname', 'localhost')
let g:oredoc#port     = get(g:, 'oredoc#port', 9200)
let g:oredoc#index    = get(g:, 'oredoc#index', 'oredoc')
let g:oredoc#curlopt  = get(g:, 'oredoc#curlopt', '')
let g:oredoc#timeout  = get(g:, 'oredoc#timeout', 3000)

let g:oredoc#errorformat = get(g:, 'oredoc#errorformat', join([
    \ "%f\t%.%#L%l: %m",
    \ "%f\t%m",
    \ ], ','))

function! oredoc#query(q) abort
  return {
      \ 'from': 0, 'size': 100,
      \ 'fields': ['path'],
      \ 'highlight': {
      \   'order': 'score',
      \   'fields': {
      \     'body': {'number_of_fragments': 3, 'fragment_size': 50}
      \   }
      \ },
      \ 'query': {
      \   'simple_query_string': {
      \     'default_operator': 'and',
      \     'fields': ['body'],
      \     'query': a:q
      \   }
      \ }}
endfunction

function! oredoc#url() abort
  return printf('http://%s:%d/%s/_search',
      \ g:oredoc#hostname,
      \ g:oredoc#port,
      \ g:oredoc#index)
endfunction

function! oredoc#request(q) abort
  let url = oredoc#url()
  let q   = json_encode(oredoc#query(a:q))
  let command = "curl -s "

  if g:oredoc#curlopt != ''
    let command .= printf('%s ', g:oredoc#curlopt)
  endif

  let command .= printf("-XGET %s -d '%s' ", url, q)

  return json_decode(s:Process.system(command, {
      \ 'timeout': g:oredoc#timeout
      \ }))
endfunction

function! oredoc#search(q) abort
  " TODO: executable('curl')

  let resp = oredoc#request(a:q)
  if resp.hits.total > 0
    let result = []
    for hit in resp.hits.hits
      let path = hit.fields.path[0]
      for hl in hit.highlight.body
        call add(result, path . "\t" . hl)
      endfor
    endfor

    let ef = &g:errorformat
    let &g:errorformat = g:oredoc#errorformat
    cgetexpr result
    copen
    let &g:errorformat = ef
  else
    echo printf('Not found for "%s"', a:q)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
