-- Alunos: Gustavo Henrique Zeni
-- 		   Lucas de Lima da Silva

-- Professor: Carlos Raimundo Erig Lima

library ieee;
use ieee.std_logic_1164.all;

entity VGA is

	generic(
	
		div:integer := 2;
		div_paddle : integer := 415000;
		
		div_ball1 : integer := 415000;
		div_ball2 : integer := 370000;
		div_ball3 : integer := 310000;
		div_ball4 : integer := 250000;
	
		Ha: integer := 96;
		Hb: integer := 144;
		Hc: integer := 784;
		Hd: integer := 800;
		Va: integer := 2;
		Vb: integer := 35;
		Vc: integer := 515;
		Vd: integer := 525;
		
		paddlesizeH: integer := 60;
		paddlesizeV: integer := 2;
		blocosizeH: integer := 35;
		blocosizeV: integer := 4);

	port(
			clk : in std_logic;
			reset: in std_logic;
			
			Hsync, Vsync : buffer std_logic;
			direction_switch: in std_logic_vector(1 downto 0);
			start_game		: in std_logic;
			
			ball_speed : in std_logic_vector(1 downto 0);
			
			R, G, B 		 : out std_logic_vector(3 downto 0);
			leds	 		 : out std_logic_vector(9 downto 0));

end VGA;



architecture VGA_arch of VGA is

	signal pixel_clk: std_logic;
	signal Hactive, Vactive, dena : std_logic;
	signal paddle_clk, ball_clk, ball_clk1, ball_clk2, ball_clk3, ball_clk4: std_logic;
	signal aVa: integer := Va;
	signal aVb: integer := Vb;
	signal aVc: integer := Vc;
	signal aVd: integer := Vd;
	signal aHa: integer := Ha;
	signal aHb: integer := Hb;
	signal aHc: integer := Hc;
	signal aHd: integer := Hd;
	signal aPHsize: integer := paddlesizeH;
	signal aPVsize: integer := paddlesizeV;
	signal aBHsize: integer := blocosizeH;
	signal aBVsize: integer := blocosizeV;
	signal aBallSize: integer := 6;
	component div_gen is
		
		generic( div 	 : integer:= 2);
		
		port( 	clk_in, reset : in std_logic;
				clk_out: out std_logic);
	
	end component div_gen;
	
	component sync_generator is
	
		generic(
	
		Va: integer := aVa;
		Vb: integer := aVb;
		Vc: integer := aVc;
		Vd: integer := aVd;
		Ha: integer := aHa;
		Hb: integer := aHb;
		Hc: integer := aHc;
		Hd: integer := aHd);
		
	port(
		pixel_clk: in std_logic;
		reset		: in std_logic;
		Hsync, Vsync: buffer std_logic;
		Hactive, Vactive: buffer std_logic;
		dena : out std_logic);
		
	end component sync_generator;
	
	component image_generator is
	
	generic(
	
		Va: integer := aVa;
		Vb: integer := aVb;
		Vc: integer := aVc;
		Vd: integer := aVd;
		Ha: integer := aHa;
		Hb: integer := aHb;
		Hc: integer := aHc;
		Hd: integer := aHd;
		PVsize: integer := aPVsize;
		PHsize: integer := aPHsize;

		BVsize: integer := aBVsize;
		BHsize: integer := aBHsize;
		BallSize: integer := aBallSize);
	
	port(
		pixel_clk		: in std_logic;
		paddle_clk		: in std_logic;
		ball_clk     	        : in std_logic;
		reset	     	        : in std_logic;
		Hactive, Vactive 	: in std_logic;
		Hsync, Vsync      	: in std_logic;
		dena		 	: in std_logic;
		direction_switch        : in std_logic_vector(1 downto 0);
		start_game		: in std_logic;
		R,G,B		        : out std_logic_vector(3 downto 0));
		
	end component image_generator;
	
	--Atribuição de pinos
	attribute chip_pin : string;
	
	attribute chip_pin of clk	       : signal is "N14";
	attribute chip_pin of reset	       : signal is "B12";
	
	attribute chip_pin of direction_switch : signal is "B14,C10";
	attribute chip_pin of start_game       : signal is "B8";
	
	
	attribute chip_pin of Hsync	       : signal is "N3";
	attribute chip_pin of Vsync	       : signal is "n1";
	
	attribute chip_pin of R		       : signal is "AA1, V1, Y2, Y1";
	attribute chip_pin of G		       : signal is "W1, T2, R2, R1";
	attribute chip_pin of B		       : signal is "P1, T1, P4, N2";
	
	attribute chip_pin of ball_speed   : signal is "A14,A13";
	attribute chip_pin of leds		   : signal is "A8,A9,A10,B10,D13,C13,E14,D14,A11,B11";

begin

	U0: div_gen
	 
		generic map (div => div)
		port map		(clk_in => clk, reset => reset, clk_out => pixel_clk);
		
	u1: sync_generator
	
		generic map(Ha => Ha,
						Hb => Hb,
						Hc => Hc,
						Hd => Hd,
						Va => Va,
						Vb => Vb,
						Vc => Vc,
						Vd => Vd)
						
		port map(pixel_clk => pixel_clk,
					reset	=> reset,
					Hsync	=> Hsync,
					Vsync	=> Vsync,
					Hactive	=> Hactive,
					Vactive	=> Vactive,
					dena 	=> dena);
					
	u2: image_generator
	
		generic map(Ha => Ha,
						Hb => Hb,
						Hc => Hc,
						Hd => Hd,
						Va => Va,
						Vb => Vb,
						Vc => Vc,
						Vd => Vd,
						PVsize => paddlesizeV,
						PHsize => paddlesizeH,
						BVsize => blocosizeV,
						BHsize => blocosizeH)
		
		port map(pixel_clk	=> pixel_clk,
					paddle_clk	=> paddle_clk,
					ball_clk	=> ball_clk,
					reset		=> reset,
					Hactive		=> Hactive,
					Vactive 	=> Vactive,
					Hsync		=> Hsync,
					Vsync		=> Vsync,
					dena		=> dena,
					direction_switch=> direction_switch,
					start_game	=> start_game,
					R		=> R,
					G		=> G,
					B		=> B);
					
	u3: div_gen
		generic map (div => div_paddle)
		port map		(clk_in => clk, reset => reset, clk_out => paddle_clk);
	
	u5: div_gen
		generic map (div => div_ball1)
		port map		(clk_in => clk, reset => reset, clk_out => ball_clk1);
	
	u6: div_gen
		generic map (div => div_ball2)
		port map		(clk_in => clk, reset => reset, clk_out => ball_clk2);
		
	u7: div_gen
		generic map (div => div_ball3)
		port map		(clk_in => clk, reset => reset, clk_out => ball_clk3);
		
	u8: div_gen
		generic map (div => div_ball4)
		port map		(clk_in => clk, reset => reset, clk_out => ball_clk4);
	
	--Multiplexador pra escolher a velocidade da bola
	process(ball_speed)
	begin
		
		case ball_speed is
			when "00" => ball_clk <= ball_clk1;
			when "01" => ball_clk <= ball_clk2;
			when "10" => ball_clk <= ball_clk3;
			when others => ball_clk <= ball_clk4;
		end case;
	end process;

	-- Apagar os leds ao iniciar o jogo
	process(start_game, reset)
	begin
		leds <= "0000000000";
	end process;
					
					
end VGA_arch;
