let s:save_cpo = &cpo
set cpo&vim

let s:V    = vital#of('oredoc')
let s:Http = s:V.import('Web.HTTP')

let g:oredoc#hostname = get(g:, 'oredoc#hostname', 'localhost')
let g:oredoc#port     = get(g:, 'oredoc#port', 9200)
let g:oredoc#index    = get(g:, 'oredoc#index', 'oredoc')

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

function! oredoc#search(q) abort
  let url = oredoc#url()
  let resp = json_decode(s:Http.request('GET', url, {
      \ 'data': json_encode(oredoc#query(a:q))
      \ }).content)
  if resp.hits.total > 0
    let result = []
    for hit in resp.hits.hits
      let path = hit.fields.path[0]
      for hl in hit.highlight.body
        call add(result, path . "\t" . hl)
      endfor
    endfor

    let ef = &g:errorformat
    let &g:errorformat = "%f\t%.%#L%l: %m"
    cgetexpr result
    copen
    let &g:errorformat = ef
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
