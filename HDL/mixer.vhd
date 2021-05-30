-- ---------------------------------------
-- mixier.vhd
-- SDR 01 signal mixer
-- 
-- ---------------------------------------
-- 2021/05/xx  _7dki  Release
--
-- ---------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity mixer is
	generic(
		INPUT_BIT_WIDTH : integer := 18;
		OUTPUT_BIT_WIDTH : integer := 36
	);
	port(
		input_x : in std_logic_vector(INPUT_BIT_WIDTH-1 downto 0);
		input_y : in std_logic_vector(INPUT_BIT_WIDTH-1 downto 0);
		output : out std_logic_vector(OUTPUT_BIT_WIDTH-1 downto 0)
	);
end mixer;

architecture rtl of mixer is
begin
	output <= signed(input_x) * signed(input_y);

end rtl;