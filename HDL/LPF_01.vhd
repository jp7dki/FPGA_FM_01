-- ポリフェーズフィルタ --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity lpf_01 is
	port (
		clk, conv_start, res_n : in std_logic;
		clk_out : out std_logic;
		in_data : in std_logic_vector(35 downto 0);
		out_data : out std_logic_vector(35 downto 0)
	);
end lpf_01;

architecture rtl of lpf_01 is
	
	type buf is array (0 to 31) of std_logic_vector(35 downto 0);
	type coef_type is array (0 to 31) of std_logic_vector(31 downto 0);
	
	constant coefs : coef_type := (X"022185FE",X"026C004F",X"033FFC6C",X"0497A1E0",X"0666A3C0",X"089AC162",X"0B1C94B0",X"0DD0A481",X"1098ADB7",X"13551310",X"15E66145",X"182ED41B",X"1A13C8AC",X"1B7F0A27",X"1C5FE822",X"1CAC0831",X"1C5FE822",X"1B7F0A27",X"1A13C8AC",X"182ED41B",X"15E66145",X"13551310",X"1098ADB7",X"0DD0A481",X"0B1C94B0",X"089AC162",X"0666A3C0",X"0497A1E0",X"033FFC6C",X"026C004F",X"022185FE",X"00000000");

	signal data_count : std_logic_vector(4 downto 0);
	signal data_count_reg : std_logic_vector(4 downto 0);
	signal div_clk : std_logic;
	signal div_clk_reg : std_logic;
	signal coef : std_logic_vector(31 downto 0);
	signal coefs_reg1 : std_logic_vector(31 downto 0);
	signal coefs_reg2 : std_logic_vector(31 downto 0);
	signal in_data_reg : std_logic_vector(35 downto 0);
	signal bufs : buf;
	signal out_data_internal : std_logic_vector(35 downto 0);
	signal conv_start_reg : std_logic;
	signal process_end : std_logic;
	
	component lpf_01_coefficient
	port(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	end component;

begin

	process(clk, res_n) begin
		if(res_n='0') then
			data_count <= (others => '0');
			data_count_reg <= (others => '0');
			in_data_reg <= (others => '0');
			conv_start_reg <= '0';
			for i in 0 to 31 loop
				bufs(i) <= (others => '0');
			end loop;
			coefs_reg1 <= (others => '0');
			coefs_reg2 <= (others => '0');
			
		elsif(clk'event and clk='1') then
			if((conv_start = '1') and (conv_start_reg = '0')) then
				data_count <= data_count + "00001";
				data_count_reg <= data_count;
				in_data_reg <= in_data;
--				bufs(conv_integer(data_count_reg)) <= signed(coef(31 downto 14)) * signed(in_data_reg(35 downto 18));
				bufs(conv_integer(data_count_reg)) <= signed(coefs(CONV_INTEGER(data_count))(31 downto 14)) * signed(in_data_reg(35 downto 18));
			end if;
			conv_start_reg <= conv_start;
			coefs_reg1 <= coefs(CONV_INTEGER(data_count));
			coefs_reg2 <= coefs(CONV_INTEGER(data_count));
		end if;	
	end process;
		
	process(clk, res_n) begin
		if(res_n = '0') then
			out_data_internal <= (others => '0');
			div_clk_reg <= '0';
		elsif(clk'event and clk='1') then
			if(data_count = "00000") then
				out_data_internal <= bufs(0)+bufs(1)+bufs(2)+bufs(3)+bufs(4)+bufs(5)+bufs(6)+bufs(7)+bufs(8)+bufs(9)+bufs(10)+bufs(11)+bufs(12)+bufs(13)+bufs(14)+bufs(15)+bufs(16)+bufs(17)+bufs(18)+bufs(19)+bufs(20)+bufs(21)+bufs(22)+bufs(23)+bufs(24)+bufs(25)+bufs(26)+bufs(27)+bufs(28)+bufs(29)+bufs(30)+bufs(31);
			end if;
			div_clk_reg <= div_clk;
		end if;
	end process;
	
--	process(div_clk) begin
--		if(div_clk'event and div_clk='0') then
--			out_data_internal <= bufs(0)+bufs(1)+bufs(2)+bufs(3)+bufs(4)+bufs(5)+bufs(6)+bufs(7)+bufs(8)+bufs(9)+bufs(10)+bufs(11)+bufs(12)+bufs(13)+bufs(14)+bufs(15)+bufs(16)+bufs(17)+bufs(18)+bufs(19)+bufs(20)+bufs(21)+bufs(22)+bufs(23)+bufs(24)+bufs(25)+bufs(26)+bufs(27)+bufs(28)+bufs(29)+bufs(30)+bufs(31);
--		end if;
--	end process;
	
	clk_out <= div_clk;
	div_clk <= '1' when (data_count = "00000") else '0';
	out_data <= out_data_internal;
	
	coef_01 : lpf_01_coefficient
	port map(
		address => data_count,
		clock => clk,
		q => coef
	);
	

end rtl;