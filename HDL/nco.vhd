-- NCO --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;

entity nco is
	generic(
		BIT_WIDTH_PHASE : integer := 16;
		BIT_WIDTH_SIGOUT : integer := 18
	);

	port (clk, res_n : in std_logic;
		freq : in std_logic_vector(BIT_WIDTH_PHASE-1 downto 0);
		sin_out : out std_logic_vector(BIT_WIDTH_SIGOUT-1 downto 0);
		cos_out : out std_logic_vector(BIT_WIDTH_SIGOUT-1 downto 0)
	);
end nco;

architecture rtl of nco is
	
	signal phase : std_logic_vector(BIT_WIDTH_PHASE-1 downto 0);
	signal sin_upper : std_logic_vector(BIT_WIDTH_SIGOUT/2-1 downto 0);
	signal sin_lower : std_logic_vector(BIT_WIDTH_SIGOUT/2-1 downto 0);
	signal cos_upper : std_logic_vector(BIT_WIDTH_SIGOUT/2-1 downto 0);
	signal cos_lower : std_logic_vector(BIT_WIDTH_SIGOUT/2-1 downto 0);
	
	-- 三角関数テーブル(ROM)の宣言 --
	component sin_rom_upper
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (BIT_WIDTH_PHASE/2-1 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (BIT_WIDTH_SIGOUT/2-1 DOWNTO 0)
	);
	end component;
	
	component sin_rom_lower
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (BIT_WIDTH_PHASE/2-1 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (BIT_WIDTH_SIGOUT/2-1 DOWNTO 0)
	);
	end component;
	
	component cos_rom_upper
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (BIT_WIDTH_PHASE/2-1 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (BIT_WIDTH_SIGOUT/2-1 DOWNTO 0)
	);
	end component;
	
	component cos_rom_lower
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (BIT_WIDTH_PHASE/2-1 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (BIT_WIDTH_SIGOUT/2-1 DOWNTO 0)
	);
	end component;

begin
	-- 位相アキュムレータ --
	process(res_n, clk) begin
		if(res_n = '0') then
			phase <= (others => '0');
		elsif(clk'event and clk='1') then
			phase <= phase + freq;
		end if;
	end process;
	
	-- 三角関数テーブル(ROM) --
	rom0 : sin_rom_upper
		port map(
			address => phase(BIT_WIDTH_PHASE-1 downto BIT_WIDTH_PHASE/2),
			clock => clk,
			q => sin_upper
		);

	rom1 : sin_rom_lower
		port map(
			address => phase(BIT_WIDTH_PHASE/2-1 downto 0),
			clock => clk,
			q => sin_lower
		);

	rom2 : cos_rom_upper
		port map(
			address => phase(BIT_WIDTH_PHASE-1 downto BIT_WIDTH_PHASE/2),
			clock => clk,
			q => cos_upper
		);

	rom3 : cos_rom_lower
		port map(
			address => phase(BIT_WIDTH_PHASE/2-1 downto 0),
			clock => clk,
			q => cos_lower
		);
	
	-- 位相から出力値を算出 --
	sin_out <= sin_upper * cos_lower + cos_upper * sin_lower;
	cos_out <= cos_upper * cos_lower - sin_upper * sin_lower;

end rtl;