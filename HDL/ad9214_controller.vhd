-- AD9214 Controller --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ad9214_cont is
	port (
		clk : in std_logic;
		res_n : in std_logic;
		adc_bus : in std_logic_vector(9 downto 0);
		ovr_rng : in std_logic;
		pwr_on : out std_logic;
		adc_result : out std_logic_vector(9 downto 0)
	);
end ad9214_cont;

architecture rtl of ad9214_cont is

	signal data_reg : std_logic_vector(9 downto 0);
	
begin
	
	process(clk, res_n) begin
		if(res_n = '0') then
			data_reg <= (others => '0');
		elsif(clk'event and clk='0') then
			-- adc data capture at clock falling edge --
			data_reg <= adc_bus;
		end if;
	end process;
	
	adc_result <= data_reg;
	pwr_on <= '0';
	
	
end rtl;
		