-- CORDIC --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

entity cordic is
	port(
		clk, res_n : in std_logic;
		q_in, i_in : in std_logic_vector(35 downto 0);
		conv_start : in std_logic;
		abs_out : out std_logic_vector(35 downto 0);
		phase_out : out std_logic_vector(35 downto 0);
		done : out std_logic
	);
end cordic;

architecture rtl of cordic is

	type t_coef is array (0 to 15) of std_logic_vector(35	downto 0); 
	
	constant coef : t_coef :=
		(36X"100000000", 36X"972028ED", 36X"4FD9C2DB", 36X"28888EA1", 36X"145D7E18", 36X"A2FBF0B", 36X"517B0F3", 
		 36X"28BE2A9", 36X"145F29A", 36X"A2F976", 36X"517CC0", 36X"28BE61", 36X"145F30", 36X"A2F98", 36X"517CC", 36X"28BE6");
	constant allone : std_logic_vector(35 downto 0) := (others => '1');
	constant PHASE_PI : std_logic_vector(35 downto 0) := X"3FFFFFFFF";
	constant PHASE_MPI : std_logic_vector(35 downto 0) := X"C00000001";
	
	signal process_count : std_logic_vector(3 downto 0);
	signal process_run : std_logic;
	signal z,x,y : std_logic_vector(35 downto 0);
	signal quad_num : std_logic_vector(1 downto 0);
	signal conv_start_reg : std_logic;
	
begin
	process(clk, res_n) begin
		if(res_n = '0') then
			conv_start_reg <= '0';
		elsif(clk'event and clk = '1') then
			conv_start_reg <= conv_start;
		end if;
	end process;

	process(clk, res_n) begin
		if(res_n = '0') then
			process_count <= (others => '0');
			process_run <= '0';
			z <= (others => '0');
			x <= (others => '0');
			y <= (others => '0');
			quad_num <= "00";
			done <= '0';
		elsif(clk'event and clk = '1') then
			if((process_run = '0') and (conv_start = '1') and (conv_start_reg = '0')) then
				process_run <= '1';
				z <= (others => '0');
				-- 象限の判定 --
				if (q_in(35)='0' and i_in(35)='0') then
					-- 第一象限 --
					x <= q_in;
					y <= i_in;
					quad_num <= "00";
				elsif (q_in(35)='1' and i_in(35)='0') then
					-- 第二象限 --
					x <= (q_in xor allone) + 1;
					y <= i_in;
					quad_num <= "01";
				elsif (q_in(35)='1' and i_in(35)='1') then
					-- 第三象限 --
					x <= (q_in xor allone) + 1;
					y <= (i_in xor allone) + 1;
					quad_num <= "10";
				else
					-- 第四象限 --
					x <= q_in;
					y <= (i_in xor allone) + 1;
					quad_num <= "11";
				end if;
				done <= '0';
			elsif(process_run = '1') then
				if(y(35) = '0') then
					x <= x + to_stdlogicvector((to_bitvector(y) sra conv_integer(process_count)));
					y <= y + (to_stdlogicvector((to_bitvector(x) sra conv_integer(process_count))) xor allone) + 1;
					z <= z + coef(conv_integer(process_count));
				else
					x <= x + (to_stdlogicvector((to_bitvector(y) sra conv_integer(process_count))) xor allone) + 1;
					y <= y + to_stdlogicvector((to_bitvector(x) sra conv_integer(process_count)));
					z <= z + (coef(conv_integer(process_count)) xor allone) + 1;
				end if;
				
				if(process_count = "1111") then
					process_run <= '0';
					abs_out <= x;
					if(quad_num="00") then
						phase_out <= z;
					elsif(quad_num="01") then
						phase_out <= PHASE_PI + (z xor allone) + 1;
					elsif(quad_num="10") then
						phase_out <= PHASE_MPI + z;
					else
						phase_out <= (z xor allone) + 1;
					end if;
					done <= '1';
				end if;
				process_count <= process_count + 1;
			end if;
		end if;
	
	end process;
	
end rtl;