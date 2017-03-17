library ieee;
use ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture behaviour of testbench is

  component xx is
    port ( );
  end component;

begin

  XY : xx
    port map ( );

end behaviour;
