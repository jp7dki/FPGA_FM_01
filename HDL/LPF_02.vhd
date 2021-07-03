--------------------------------------
-- ポリフェーズフィルタ 
-- パイプライン化してタップ数を増やす
--------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity lpf_02 is
	port (
		clk, conv_start, res_n : in std_logic;
		clk_out : out std_logic;
		in_data : in std_logic_vector(35 downto 0);
		out_data : out std_logic_vector(35 downto 0)
	);
end lpf_02;

architecture rtl of lpf_02 is

	type buf is array (0 to 3) of std_logic_vector(56 downto 0);
	type coef is array (0 to 3, 0 to 31) of std_logic_vector(31 downto 0);
	
	constant coefs : coef := (
		(X"00000000",X"FFEE0DC4",X"FFE8EA28",X"FFE359DF",X"FFDD33CD",X"FFD652C8",X"FFCE9757",X"FFC5E961",X"FFBC39C0",X"FFB183BE",X"FFA5CE65",X"FF992DA3",X"FF8BC32D",X"FF7DBF2B",X"FF6F6099",X"FF60F562",X"FF52DA29",X"FF4579C4",X"FF394C67",X"FF2ED680",X"FF26A73F",X"FF2156E0",X"FF1F84A3",X"FF21D492",X"FF28ED07",X"FF35740E",X"FF480C9E",X"FF6153C0",X"FF81DDA1",X"FFAA32B2",X"FFDACCC6",X"00141458"),
		(X"00565DEF",X"00A1E7B5",X"00F6D74D",X"015537F8",X"01BCF905",X"022DEC9E",X"02A7C701",X"032A1E16",X"03B4697C",X"04460300",X"04DE278D",X"057BF884",X"061E7D88",X"06C4A6AF",X"076D4F17",X"08173FD9",X"08C1334B",X"0969D887",X"0A0FD72F",X"0AB1D35D",X"0B4E71B5",X"0BE45B83",X"0C7242DE",X"0CF6E6BA",X"0D7116E0",X"0DDFB7B5",X"0E41C5D1",X"0E96593E",X"0EDCA871",X"0F140ADD",X"0F3BFB18",X"0F54189B"),
		(X"0F5C28F6",X"0F54189B",X"0F3BFB18",X"0F140ADD",X"0EDCA871",X"0E96593E",X"0E41C5D1",X"0DDFB7B5",X"0D7116E0",X"0CF6E6BA",X"0C7242DE",X"0BE45B83",X"0B4E71B5",X"0AB1D35D",X"0A0FD72F",X"0969D887",X"08C1334B",X"08173FD9",X"076D4F17",X"06C4A6AF",X"061E7D88",X"057BF884",X"04DE278D",X"04460300",X"03B4697C",X"032A1E16",X"02A7C701",X"022DEC9E",X"01BCF905",X"015537F8",X"00F6D74D",X"00A1E7B5"),
		(X"00565DEF",X"00141458",X"FFDACCC6",X"FFAA32B2",X"FF81DDA1",X"FF6153C0",X"FF480C9E",X"FF35740E",X"FF28ED07",X"FF21D492",X"FF1F84A3",X"FF2156E0",X"FF26A73F",X"FF2ED680",X"FF394C67",X"FF4579C4",X"FF52DA29",X"FF60F562",X"FF6F6099",X"FF7DBF2B",X"FF8BC32D",X"FF992DA3",X"FFA5CE65",X"FFB183BE",X"FFBC39C0",X"FFC5E961",X"FFCE9757",X"FFD652C8",X"FFDD33CD",X"FFE359DF",X"FFE8EA28",X"FFEE0DC4"));
		
	-- signals
	signal conv_start_reg : std_logic;
	signal process_start : std_logic;
	signal process_end : std_logic;
	signal process_run : std_logic;
	signal bufs : buf;
	signal data_count : std_logic_vector(4 downto 0);
	signal data_count_reg : std_logic_vector(4 downto 0);
	signal div_clk : std_logic;
	signal out_data_internal : std_logic_vector(35 downto 0);
	
begin
	
	-- conversion start detect
	process(clk, res_n) begin
		if(res_n = '0') then 
			conv_start_reg <= '0';
		elsif(clk'event and clk='1') then
			conv_start_reg <= conv_start;
		end if;
	end process;
	
	process_start <= '1' when ((conv_start = '1') and (conv_start_reg = '0')) else '0';
	
	-- fir process control
	process(clk, res_n) begin
		if(res_n = '0') then
			process_run <= '0';
			data_count <= "00000";
			data_count_reg <= "00000";
					
			for i in 0 to 3 loop
				bufs(i) <= (others => '0');
			end loop;
			 
		elsif(clk'event and clk='1') then
			if((conv_start = '1') and (conv_start_reg = '0')) then
				
				if(data_count = "00000") then
				
					bufs(0) <=  (coefs(0,0)(31) xor in_data(35)) &
									(coefs(0,0)(31) xor in_data(35)) &
									(coefs(0,0)(31) xor in_data(35)) &
									(coefs(0,0)(31) xor in_data(35)) &
									(coefs(0,0)(31) xor in_data(35)) &
									(coefs(0,0)(31) xor in_data(35)) &
									(coefs(0,0)(31) xor in_data(35)) &
									(signed(coefs(0, 0)) * signed(in_data(35 downto 18)));
					for i in 0 to 2 loop
						bufs(i+1) <=  bufs(i) + 
									((coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(signed(coefs(i, CONV_INTEGER(data_count))) * signed(in_data(35 downto 18))));
					end loop;
				else
					for i in 0 to 3 loop
						bufs(i) <= bufs(i) + 
									((coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(coefs(i,CONV_INTEGER(data_count))(31) xor in_data(35)) &
									(signed(coefs(i, CONV_INTEGER(data_count))) * signed(in_data(35 downto 18))));
					end loop;
				end if;
				data_count <= data_count + "00001";
				data_count_reg <= data_count;
			end if;
		end if;
	end process;		
	
	process(clk, res_n) begin
		if(res_n = '0') then
			out_data_internal <= (others => '0');
		elsif(clk'event and clk='1') then
			if(data_count="00000") then
				out_data_internal <= bufs(3)(45 downto 10);
			end if;
		end if;
	end process;
	
	clk_out <= div_clk;
	div_clk <= '1' when (data_count = "00000") else '0';
	out_data <= out_data_internal;
	
	
end rtl;