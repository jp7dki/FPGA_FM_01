-- LPF tester --


-- ---------------------------------------
-- top.vhd
-- SDR 01 top module
-- 
-- ---------------------------------------
-- 2021/05/xx  _7dki  Release
--
-- ---------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity lpf_tester is
	port (
		clk48 : in std_logic;
		tune_freq : in std_logic_vector(15 downto 0);
		filt_out : out std_logic_vector(35 downto 0)
	);
end lpf_tester;

architecture rtl of lpf_tester is

	constant ONE : std_logic_vector(35 downto 0) := (others => '1');
	constant PHASE_PI : std_logic_vector(35 downto 0) := X"400000000";
	constant PHASE_MPI : std_logic_vector(35 downto 0) := X"C00000000";

	---------------------------------------
	-- internal signal
	---------------------------------------
	signal clk664 : std_logic;
	
	-- reset
	signal res_n : std_logic := '0';
	signal por_count : std_logic_vector(7 downto 0) := X"00";
	
	signal sin_out : std_logic_vector(17 downto 0);
	signal cos_out : std_logic_vector(17 downto 0);
	
	signal mixer_q_out : std_logic_vector(35 downto 0);
	signal mixer_i_out : std_logic_vector(35 downto 0);
	
	signal cic_q_out : std_logic_vector(35 downto 0);
	signal cic_clk_q : std_logic;
	
	signal lpf_clk_q : std_logic;
	signal lpf_q_out : std_logic_vector(35 downto 0);
	
	---------------------------------------
	-- PLL 
	---------------------------------------
	component pll
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC 
	);
	end component;
	
	---------------------------------------
	-- NCO
	---------------------------------------
	component nco
	generic(
		BIT_WIDTH_PHASE : integer;
		BIT_WIDTH_SIGOUT : integer
	);
	port (clk, res_n : in std_logic;
		freq : in std_logic_vector(BIT_WIDTH_PHASE-1 downto 0);
		sin_out : out std_logic_vector(BIT_WIDTH_SIGOUT-1 downto 0);
		cos_out : out std_logic_vector(BIT_WIDTH_SIGOUT-1 downto 0)
	);
	end component;
	
	---------------------------------------
	-- CIC Filter
	---------------------------------------
	component cic
	generic(
		INPUT_WIDTH : integer;
		OUTPUT_WIDTH : integer;
		REG_WIDTH : integer;
		TAP_NUM : integer;
		DECIM_RATE : integer
	);
	
	port (
		clk, res_n : in std_logic;
		clk_out : out std_logic;
		in_data : in std_logic_vector(INPUT_WIDTH-1 downto 0);
		out_data : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
	);
	end component;
	
	---------------------------------------
	-- FIR Filter (Poly-Phase Filter)
	---------------------------------------
	component lpf_02
	port (
		clk, conv_start, res_n : in std_logic;
		clk_out : out std_logic;
		in_data : in std_logic_vector(35 downto 0);
		out_data : out std_logic_vector(35 downto 0)
	);
	end component;
	
begin


	-- Power on Reset
	process(clk664) begin
		if(clk664'event and clk664='1') then
			if(por_count /= X"FF") then
				res_n <= '0';
				por_count <= por_count + X"01";
			else
				res_n <= '1';
				por_count <= por_count;
			end if;
		end if;
	end process;
	
	---------------------------------------
	-- PLL 
	---------------------------------------
	pll0 : pll
	port map(
		inclk0 => clk48,
		c0 => clk664
	);
	
	---------------------------------------
	-- NCO
	---------------------------------------
	nco0 : nco
	generic map(
		BIT_WIDTH_PHASE => 16,
		BIT_WIDTH_SIGOUT => 18
	)
	port map
	(
		clk => clk664,
		res_n => res_n,
		freq => tune_freq,
		sin_out => sin_out,
		cos_out => cos_out
	);
	
	mixer_q_out <= sin_out & 
						sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & 
						sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & 
						sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0) & sin_out(0);
	--mixer_q_out <= sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & 
	--					sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & 
	--					sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) & sin_out(17) &
	--					sin_out;
	
	---------------------------------------
	-- CIC Filter
	---------------------------------------
	cic_q : cic
	generic map(
		INPUT_WIDTH => 36,
		OUTPUT_WIDTH => 36,
		REG_WIDTH => 45,
		TAP_NUM => 4,
		DECIM_RATE => 2
	)
	port map(
		clk => clk664,
		res_n => res_n,
		clk_out => cic_clk_q,
		in_data => mixer_q_out,
		out_data => cic_q_out
	);
	
	---------------------------------------
	-- FIR Filter (Poly-Phase Filter)
	---------------------------------------
	lpf_q : lpf_02
	port map(
		clk => clk664,
		conv_start => cic_clk_q,
		res_n => res_n,
		clk_out => lpf_clk_q,
		in_data => cic_q_out,
		out_data => filt_out
	);
	
end rtl;
