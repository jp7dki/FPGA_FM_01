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
		(X"004E3DF0",X"000763D8",X"0005BFB5",X"00028FCB",X"FFFDB6F9",X"FFF708E3",X"FFEE6B76",X"FFE3B6D6",X"FFD6DD44",X"FFC7C57A",X"FFB67A0F",X"FFA30104",X"FF8D8A43",X"FF763B28",X"FF5D5FAC",X"FF42FE33",X"FF27F7E8",X"FF0C789F",X"FEF12326",X"FED6A101",X"FEBDA18B",X"FEA6EB1B",X"FE9350FE",X"FE83B01F",X"FE78F5BC",X"FE74113D",X"FE75F979",X"FE7F9AB2",X"FE91E0A8",X"FEADA37F",X"FED3D022",X"FF050A0F"),
		(X"FF4207D5",X"FF8B563D",X"FFE15CF5",X"00446696",X"00B4933F",X"0131D8DC",X"01BC05B1",X"0252B6DF",X"02F55B89",X"03A33205",X"045B4B9E",X"051C8B27",X"05E5AFE0",X"06B53E77",X"0789ACB9",X"0861434A",X"093A2F42",X"0A128CF7",X"0AE864BC",X"0BB9B693",X"0C848339",X"0D46CBE1",X"0DFE9E2B",X"0EAA1C26",X"0F477DA2",X"0FD51CBF",X"10517A02",X"10BB3C82",X"11114590",X"1152A2A2",X"117E9C45",X"1194B943"),
		(X"1194B943",X"117E9C45",X"1152A2A2",X"11114590",X"10BB3C82",X"10517A02",X"0FD51CBF",X"0F477DA2",X"0EAA1C26",X"0DFE9E2B",X"0D46CBE1",X"0C848339",X"0BB9B693",X"0AE864BC",X"0A128CF7",X"093A2F42",X"0861434A",X"0789ACB9",X"06B53E77",X"05E5AFE0",X"051C8B27",X"045B4B9E",X"03A33205",X"02F55B89",X"0252B6DF",X"01BC05B1",X"0131D8DC",X"00B4933F",X"00446696",X"FFE15CF5",X"FF8B563D",X"FF4207D5"),
		(X"FF050A0F",X"FED3D022",X"FEADA37F",X"FE91E0A8",X"FE7F9AB2",X"FE75F979",X"FE74113D",X"FE78F5BC",X"FE83B01F",X"FE9350FE",X"FEA6EB1B",X"FEBDA18B",X"FED6A101",X"FEF12326",X"FF0C789F",X"FF27F7E8",X"FF42FE33",X"FF5D5FAC",X"FF763B28",X"FF8D8A43",X"FFA30104",X"FFB67A0F",X"FFC7C57A",X"FFD6DD44",X"FFE3B6D6",X"FFEE6B76",X"FFF708E3",X"FFFDB6F9",X"00028FCB",X"0005BFB5",X"000763D8",X"004E3DF0"));
		
	-- signals
	signal conv_start_reg : std_logic;
	signal process_start : std_logic;
	signal process_end : std_logic;
	signal process_run : std_logic;
	signal bufs : buf;
	signal data_count : std_logic_vector(4 downto 0);
	signal data_count_reg : std_logic_vector(4 downto 0);
	
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
	
	process_end <= '1' when ((data_count = "00000") and (data_count_reg = "11111")) else '0';
	 
	clk_out <= process_end;
	
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
			if(process_start = '1') then
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
			out_data <= (others => '0');
		elsif(clk'event and clk='1') then
			if(data_count = "00000") then
				out_data <= bufs(3)(49 downto 14);
			end if;
		end if;
	end process;
	
end rtl;