
package direction_pkg;
  typedef enum logic [0:0] {
    PF   = 1'b0,
    CMAC = 1'b1
  } direction_t;

  function automatic bit is_pf(logic direction);
    return (direction == PF);
  endfunction

  function automatic bit is_cmac(logic direction);
    return (direction == CMAC);
  endfunction
endpackage: direction_pkg
