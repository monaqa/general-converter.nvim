function! general_converter#operator(type)
  call luaeval('require("general_converter")._op(_A[1])', [a:type])
endfunction
