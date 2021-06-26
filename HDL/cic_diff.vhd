-- CIC 微分器 --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;

entity cic_diff is
	generic(
		TAP_NUM : integer := 4;
		BIT_W : integer := 46
	);
	
	port(
		clk, res_n : in std_logic;
		in_data : in std_logic_vector(BIT_W-1 downto 0);
		out_data : out std_logic_vector(BIT_W-1 downto 0)
	);
end cic_diff;

architecture rtl of cic_diff is
	
	constant allone : std_logic_vector(BIT_W-1 downto 0) := (others=>'1');
	
	type tap is array (0 to TAP_NUM) of std_logic_vector(BIT_W-1 downto 0);
	
	signal taps : tap;
	signal delay_taps : tap;
	
begin
	process(res_n, clk) begin
		if(clk'event and clk='1') then
			if(res_n = '0') then
				for i in 0 to TAP_NUM loop
					taps(i) <= (others => '0');
					delay_taps(i) <= (others => '0');
				end loop;
			else 
				delay_taps(0) <= in_data;
				taps(0) <= in_data + (delay_taps(0) xor allone) + 1;
				
				for i in 1 to TAP_NUM loop
					delay_taps(i) <= taps(i-1);
					taps(i) <= taps(i-1) + (delay_taps(i) xor allone) + 1;	
				end loop;
			end if;
		end if;
	end process;
	
	out_data <= taps(TAP_NUM-1);
end rtl;
