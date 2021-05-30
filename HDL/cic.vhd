-- CIC filter --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity cic is
	generic(
		INPUT_WIDTH : integer := 18;
		OUTPUT_WIDTH : integer := 18;
		REG_WIDTH : integer := 46;
		TAP_NUM : integer := 4;
		DECIM_RATE : integer := 6   -- 128=2^7
	);
	
	port (
		clk, res_n : in std_logic;
		clk_out : out std_logic;
		in_data : in std_logic_vector(INPUT_WIDTH-1 downto 0);
		out_data : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
	);
end cic;

architecture rtl of cic is
	
	constant ZERO : std_logic_vector(REG_WIDTH-1 downto 0) := (others => '0');
	constant allone : std_logic_vector(REG_WIDTH-1 downto 0) := (others=>'1');

	type tap is array (0 to TAP_NUM-1) of std_logic_vector(REG_WIDTH-1 downto 0);
	
	-- 積分器用のレジスタ --
	signal int_tap : tap;
	
	-- 微分器用のレジスタ --
	signal diff_tap : tap;
	signal delay_tap : tap;

	signal in_data_internal : std_logic_vector(REG_WIDTH-1 downto 0);
	signal out_data_internal : std_logic_vector(REG_WIDTH-1 downto 0);
	signal clk_div : std_logic;
	signal clk_div_count : std_logic_vector(DECIM_RATE-1 downto 0);
	
begin
	
	-- 内部信号定義 --
	clk_div <= clk_div_count(DECIM_RATE-1);
	in_data_internal <= (REG_WIDTH-1 downto INPUT_WIDTH => in_data(INPUT_WIDTH-1)) & in_data;
	out_data <= out_data_internal(REG_WIDTH-1 downto REG_WIDTH-OUTPUT_WIDTH);
	clk_out <= clk_div;
	
	-- 積分器 --
	process(res_n, clk) begin
		if(res_n = '0') then
			for i in 0 to TAP_NUM-1 loop
				int_tap(i) <= (others => '0');
			end loop;
		elsif(clk'event and clk='1') then
			int_tap(0) <= in_data_internal + int_tap(0);
			
			for i in 1 to TAP_NUM-1 loop
				int_tap(i) <= int_tap(i-1) + int_tap(i);
			end loop;
		end if;
	end process;
	
	-- clock divider --
	process(res_n, clk) begin
		if(res_n = '0') then
			clk_div_count <= (others => '0');	
		elsif(clk'event and clk='1') then
			clk_div_count <= clk_div_count + 1;
		end if;
	end process;
	
	-- 微分器 --
	process(res_n, clk_div) begin
		if(res_n = '0') then
			for i in 0 to TAP_NUM-1 loop
				diff_tap(i) <= (others => '0');
				delay_tap(i) <= (others => '0');
			end loop;
		elsif(clk_div'event and clk_div='1') then
			delay_tap(0) <= int_tap(TAP_NUM-1);
			diff_tap(0) <= int_tap(TAP_NUM-1) + (delay_tap(0) xor allone) + 1;			
			for i in 1 to TAP_NUM-1 loop
				delay_tap(i) <= diff_tap(i-1);
				diff_tap(i) <= diff_tap(i-1) + (delay_tap(i) xor allone) + 1;	
			end loop;
		end if;
	end process;
	
	out_data_internal <= diff_tap(TAP_NUM-1);

end rtl;
