-- Delta Sigma Digital to Analog Converter --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity dsm_dac is
	generic(
		BIT_WIDTH : integer := 36
	);
	
	port(
		clk : in std_logic;
		res_n : in std_logic;
		in_data : in std_logic_vector(BIT_WIDTH-1 downto 0);
		out_data : out std_logic
	);
end dsm_dac;

architecture rtl of dsm_dac is

	constant zero : std_logic_vector(BIT_WIDTH-1 downto 0) := (others => '0');
	signal in_data_offset : std_logic_vector(BIT_WIDTH-1 downto 0);
	signal add_signal : std_logic_vector(BIT_WIDTH downto 0);
	signal dsm_reg : std_logic_vector(BIT_WIDTH downto 0);
	signal out_reg : std_logic;

begin
	in_data_offset <= in_data + X"7FFFFFFFF";
	add_signal <= (dsm_reg(BIT_WIDTH-1 downto 0)) + ("0" & in_data_offset(BIT_WIDTH-1  downto 0));
	out_data <= out_reg;

	process (clk, res_n) begin
		if (res_n = '0') then
			dsm_reg <= (others => '0');
			out_reg <= '0';
		elsif(clk'event and clk='1') then
			dsm_reg <= add_signal(BIT_WIDTH downto 0);
			out_reg <= add_signal(BIT_WIDTH);
		end if;
	end process;

end rtl;