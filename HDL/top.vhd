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

entity top is
	port (
		clk48 : in std_logic;
		adc_or : in std_logic;
		adc_data : in std_logic_vector(9 downto 0);
		pwr_out : out std_logic;
		enc_out : out std_logic;
		dac_out : out std_logic
	);
end top;

architecture rtl of top is

	constant ONE : std_logic_vector(35 downto 0) := (others => '1');
	constant PHASE_PI : std_logic_vector(35 downto 0) := X"3FFFFFFFF";
	constant PHASE_MPI : std_logic_vector(35 downto 0) := X"C00000001";

	---------------------------------------
	-- internal signal
	---------------------------------------
	signal clk664 : std_logic;
	
	-- reset
	signal res_n : std_logic := '0';
	signal por_count : std_logic_vector(7 downto 0) := X"00";
	
	signal adc_result : std_logic_vector(9 downto 0);
	
--	signal tune_freq : std_logic_vector(15 downto 0) := X"3E13";		-- 82.5MHz:NHK-FM (nagoya)
--	signal tune_freq : std_logic_vector(15 downto 0) := X"26F1";		-- 76.5MHz:FM ichinomiya
	signal tune_freq : std_logic_vector(15 downto 0) := X"52E4";		-- 87.9MHz:FM transmittor
--	signal tune_freq : std_logic_vector(15 downto 0) := X"0001";		-- test
	signal sin_out : std_logic_vector(17 downto 0);
	signal cos_out : std_logic_vector(17 downto 0);
	
	signal adc_result_internal : std_logic_vector(17 downto 0);	
	
	signal mixer_q_out : std_logic_vector(35 downto 0);
	signal mixer_i_out : std_logic_vector(35 downto 0);
	
	signal cic_q_out : std_logic_vector(35 downto 0);
	signal cic_i_out : std_logic_vector(35 downto 0);
	signal cic_clk_q : std_logic;
	signal cic_clk_i : std_logic;
	
	signal lpf_clk_q : std_logic;
	signal lpf_clk_i : std_logic;
	signal lpf_q_out : std_logic_vector(35 downto 0);
	signal lpf_i_out : std_logic_vector(35 downto 0);
	
	signal abs_result : std_logic_vector(35 downto 0);
	signal phase_result : std_logic_vector(35 downto 0);
	signal done : std_logic;
	
	signal phase_result_reg : std_logic_vector(35 downto 0);
	signal fm_result : std_logic_vector(35 downto 0);
	signal debug : std_logic_vector(1 downto 0);
	
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
	-- AD9214 Controller
	---------------------------------------
	component ad9214_cont
	port (
		clk : in std_logic;
		res_n : in std_logic;
		adc_bus : in std_logic_vector(9 downto 0);
		ovr_rng : in std_logic;
		pwr_on : out std_logic;
		adc_result : out std_logic_vector(9 downto 0)
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
	-- Mixer
	---------------------------------------
	component mixer
	generic(
		INPUT_BIT_WIDTH : integer;
		OUTPUT_BIT_WIDTH : integer
	);
	port(
		input_x : in std_logic_vector(INPUT_BIT_WIDTH-1 downto 0);
		input_y : in std_logic_vector(INPUT_BIT_WIDTH-1 downto 0);
		output : out std_logic_vector(OUTPUT_BIT_WIDTH-1 downto 0)
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
	component lpf_01
	port (
		clk, res_n : in std_logic;
		clk_out : out std_logic;
		in_data : in std_logic_vector(35 downto 0);
		out_data : out std_logic_vector(35 downto 0)
	);
	end component;
	
	---------------------------------------
	-- CORDIC
	---------------------------------------
	component cordic
	port(
		clk, res_n : in std_logic;
		q_in, i_in : in std_logic_vector(35 downto 0);
		conv_start : in std_logic;
		abs_out : out std_logic_vector(35 downto 0);
		phase_out : out std_logic_vector(35 downto 0);
		done : out std_logic
	);
	end component;
	
	---------------------------------------
	-- DAC
	---------------------------------------
	component dsm_dac
	generic(
		BIT_WIDTH : integer
	);
	port(
		clk : in std_logic;
		res_n : in std_logic;
		in_data : in std_logic_vector(BIT_WIDTH-1 downto 0);
		out_data : out std_logic
	);
	end component;

begin

	enc_out <= clk664;

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
	-- AD9214 Controller
	---------------------------------------
	ad9214_cont0 : ad9214_cont
	port map(
		clk => clk664,
		res_n => res_n,
		adc_bus => adc_data,
		ovr_rng => adc_or,
		pwr_on => pwr_out,
		adc_result => adc_result
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
	
	-- adc_result_internal <= adc_result(9) & adc_result(9) & adc_result(9) & adc_result(9) & adc_result(9) & adc_result(9) & adc_result(9) & adc_result(9) & adc_result;
	adc_result_internal <= adc_result(8 downto 0) & "000000000";
	
	---------------------------------------
	-- Mixer
	---------------------------------------
	mixer_q : mixer
	generic map (
		INPUT_BIT_WIDTH => 18,
		OUTPUT_BIT_WIDTH => 36
	)
	port map(
		input_x => sin_out,
		input_y => adc_result_internal,
		output => mixer_q_out
	);
	
	mixer_i : mixer
	generic map (
		INPUT_BIT_WIDTH => 18,
		OUTPUT_BIT_WIDTH => 36
	)
	port map(
		input_x => cos_out,
		input_y => adc_result_internal,
		output => mixer_i_out
	);
	
	---------------------------------------
	-- Mixer
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
	
	cic_i : cic
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
		clk_out => cic_clk_i,
		in_data => mixer_i_out,
		out_data => cic_i_out
	);
	
	---------------------------------------
	-- FIR Filter (Poly-Phase Filter)
	---------------------------------------
	lpf_q : lpf_01
	port map(
		clk => cic_clk_q,
		res_n => res_n,
		clk_out => lpf_clk_q,
		in_data => cic_q_out,
		out_data => lpf_q_out
	);
	
	lpf_i : lpf_01
	port map(
		clk => cic_clk_i,
		res_n => res_n,
		clk_out => lpf_clk_i,
		in_data => cic_i_out,
		out_data => lpf_i_out
	);
	
	---------------------------------------
	-- CORDIC
	---------------------------------------
	cordic0 : cordic
	port map(
		clk => clk664,
		res_n => res_n,
		q_in => lpf_q_out,
		i_in => lpf_i_out,
		conv_start => lpf_clk_q,
		abs_out => abs_result,
		phase_out => phase_result,
		done => done
	);
	
	---------------------------------------
	-- FM demodulator
	---------------------------------------
	process(done, res_n) begin
		if(res_n = '0') then
			phase_result_reg <= (others => '0');
			fm_result <= (others => '0');
			debug <= (others => '0');
		elsif(done'event and done = '1') then
			if ((((phase_result + (phase_result_reg xor ONE) + 1) + PHASE_MPI) and X"800000000") = X"000000000") then
				fm_result <= phase_result + (phase_result_reg xor ONE) + 1 + PHASE_MPI + PHASe_MPI;
				debug <= "01";
			elsif((((phase_result + (phase_result_reg xor ONE) + 1) + PHASE_PI) and X"800000000") /= X"000000000") then
				fm_result <= phase_result + (phase_result_reg xor ONE) + 1 + PHASE_PI + PHASE_PI;
				debug <= "10";
			else
				fm_result <= phase_result + (phase_result_reg xor ONE) + 1;
				debug <= "00";
			end if;
			phase_result_reg <= phase_result;
		end if;
	end process;
	
	---------------------------------------
	-- DAC +
	---------------------------------------
	dac0 : dsm_dac
	generic map(
		BIT_WIDTH => 36
	)
	port map(
		clk => clk664,
		res_n => res_n,
		in_data => fm_result,
		out_data => dac_out
	);
	
	
end rtl;
