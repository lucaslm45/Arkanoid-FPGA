-- Alunos: Gustavo Henrique Zeni
-- 		   Lucas de Lima da Silva

-- Professor: Carlos Raimundo Erig Lima

library ieee;
use ieee.std_logic_1164.all;

entity image_generator is

	generic(
	
		Va: integer := 96;
		Vb: integer := 144;
		Vc: integer := 784;
		Vd: integer := 800;
		Ha: integer := 2;
		Hb: integer := 35;
		Hc: integer := 515;
		Hd: integer := 525;
		PHsize: integer := 100;
		PVsize: integer := 2;
		BHsize: integer := 50;
		BVsize: integer := 4;
		BallSize: integer := 6);
	
	port(
		pixel_clk 		  : in std_logic;
		paddle_clk		  : in std_logic;
		ball_clk			  : in std_logic;
		reset				  : in std_logic;
		Hactive, Vactive : in std_logic;
		Hsync, Vsync     : in std_logic;
		dena		 		  : in std_logic;
		direction_switch : in std_logic_vector(1 downto 0);
		start_game		  : in std_logic;
		R,G,B				  : out std_logic_vector(3 downto 0));
		
end image_generator;


architecture image_generator_arch of image_generator is

	--Contadores de pixel

	signal row_counter : integer range 0 to Vc;
	signal col_counter : integer range 0 to Hc;
	
	signal limSup : integer := 0;
	signal limInf : integer := 480 - BallSize;
	signal limLeft : integer := 0;
	signal limRight : integer := 640 - BallSize;

	--Posição da raquete
	
	signal paddle1_pos_x	 : integer range 0 to Hc;
	signal paddle1_pos_y	 : integer range 0 to Vc;

	signal paddle1_XInicial  : integer := 280;
	signal paddle1_YInicial  : integer := 420;

	--Posições dos blocos

	signal distanciaBlock : integer := BHsize*2 + 2;
	signal bloco1_pos_x	 : integer range 0 to Hc := 150;
	signal bloco2_pos_x	 : integer range 0 to Hc := bloco1_pos_x + distanciaBlock * 1;
	signal bloco3_pos_x	 : integer range 0 to Hc := bloco1_pos_x + distanciaBlock * 2;
	signal bloco4_pos_x	 : integer range 0 to Hc := bloco1_pos_x + distanciaBlock * 3;
	signal bloco5_pos_x	 : integer range 0 to Hc := bloco1_pos_x + distanciaBlock * 4;
	signal bloco6_pos_x	 : integer range 0 to Hc := bloco1_pos_x + distanciaBlock * 5;

	signal bloco1_pos_y	 : integer range 0 to Vc := BVsize;
	signal bloco2_pos_y	 : integer range 0 to Vc := bloco1_pos_y;
	signal bloco3_pos_y	 : integer range 0 to Vc := bloco1_pos_y;
	signal bloco4_pos_y	 : integer range 0 to Vc := bloco1_pos_y;
	signal bloco5_pos_y	 : integer range 0 to Vc := bloco1_pos_y;
	signal bloco6_pos_y	 : integer range 0 to Vc := bloco1_pos_y;

	signal bloco1   	   : std_logic := '1';
	signal bloco2   	   : std_logic := '1';
	signal bloco3   	   : std_logic := '1';
	signal bloco4   	   : std_logic := '1';
	signal bloco5   	   : std_logic := '1';
	signal bloco6   	   : std_logic := '1';

	signal FimDeJogo	   : std_logic := '0';

	--Posição e direção da bola
	
	signal Ball_pos_x		 : integer range 0 to Hc;
	signal Ball_pos_y		 : integer range 0 to Vc;

	signal Ball_pos_x_inicial :integer := 280;
	signal Ball_pos_y_inicial :integer := 240;
	signal Ball_direction : integer range 0 to 3; -- Diagonais
	
	--Estados do jogo
	type state_type is (S0, S1);
	signal state: state_type := S0;
	signal move: std_logic := '0';

	--"Enum" Direções
	--Diagonal direita baixo
	signal DiagDireitaBaixo : integer := 0; --Diagonal direita para baixo
	signal DiagEsquerdaBaixo : integer := 1; --Diagonal esquerda baixo
	signal DiagEsquerdaCima : integer := 2; --Diagonal esquerda cima
	signal DiagDireitaCima : integer := 3; --Diagonal direita cima
	
begin
	
	--Contadores de pixel pra representar a imagem-----------
	
	process(pixel_clk, Hactive, Vactive, Hsync, Vsync)
	
	begin
	
		if(reset = '0') then
		
			row_counter <= 0;
			
		elsif(Vsync = '0') then
		
			row_counter <= 0;
			
		elsif(Hsync'event and Hsync = '1') then
					
			if(Vactive = '1') then
			
				row_counter <= row_counter + 1;
				
			end if;
			
		end if;
		
		if(reset = '0') then
			
			col_counter <= 0;
			
		elsif(Hsync = '0') then
			
			col_counter <= 0;
			
		elsif(pixel_clk'event and pixel_clk = '1') then
		
			if(Hactive = '1') then
				
				col_counter <= col_counter + 1;
				
			end if;
			
		end if;
		
	end process;
	
	---Movimento da raquete--------------------------------
	
	process(paddle_clk, reset, direction_switch)
	
	begin
	
		if(reset = '0') then
			paddle1_pos_X <= paddle1_XInicial;
			paddle1_pos_y <= paddle1_YInicial;
			
		elsif(paddle_clk'event and paddle_clk = '1') then
		
			paddle1_pos_y <= paddle1_YInicial;
			
			if(direction_switch(0) = '1') then
				if(paddle1_pos_x = Hc - Hb) then
					paddle1_pos_x <= 0;
				else paddle1_pos_x <= paddle1_pos_x + 1;
				end if;
			end if;
			
			if(direction_switch(1) = '1') then
				if(paddle1_pos_x = 0) then
					paddle1_pos_x <= Hc - Hb;
				else paddle1_pos_x <= paddle1_pos_x - 1;
				end if;
			end if;
		end if;
		
	end process;
	
	-- Controle de colisao dos blocos
	process(ball_clk, reset)
	
	begin
		FimDeJogo <= '0';
		
		if(reset = '0') then
			bloco1 <= '1';
			bloco2 <= '1';
			bloco3 <= '1';
			bloco4 <= '1';
			bloco5 <= '1';
			bloco6 <= '1';

			-- Fim de jogo
			elsif (bloco1 = '0' and bloco2 = '0' and bloco3 = '0' and bloco4 = '0' and bloco5 = '0' and bloco6 = '0') then
				bloco1 <= '1';
				bloco2 <= '1';
				bloco3 <= '1';
				bloco4 <= '1';
				bloco5 <= '1';
				bloco6 <= '1';
				FimDeJogo <= '1';
			
		elsif(ball_clk'event and ball_clk = '1') then
			if(Ball_pos_y - BallSize >= bloco1_pos_y - BVsize and
				Ball_pos_y - BallSize <= bloco1_pos_y + BVsize) and
				(Ball_pos_x + BallSize >= bloco1_pos_x - BHsize and
				Ball_pos_x - BallSize <= bloco1_pos_x + BHsize) then
											
					bloco1 <= '0';
			end if;
			if(Ball_pos_y - BallSize >= bloco2_pos_y - BVsize and
				Ball_pos_y - BallSize <= bloco2_pos_y + BVsize) and
				(Ball_pos_x + BallSize >= bloco2_pos_x - BHsize and
				Ball_pos_x - BallSize <= bloco2_pos_x + BHsize) then
											
					bloco2 <= '0';
			end if;
			if(Ball_pos_y - BallSize >= bloco3_pos_y - BVsize and
				Ball_pos_y - BallSize <= bloco3_pos_y + BVsize) and
				(Ball_pos_x + BallSize >= bloco3_pos_x - BHsize and
				Ball_pos_x - BallSize <= bloco3_pos_x + BHsize) then
											
					bloco3 <= '0';
			end if;
			if(Ball_pos_y - BallSize >= bloco4_pos_y - BVsize and
				Ball_pos_y - BallSize <= bloco4_pos_y + BVsize) and
				(Ball_pos_x + BallSize >= bloco4_pos_x - BHsize and
				Ball_pos_x - BallSize <= bloco4_pos_x + BHsize) then
											
					bloco4 <= '0';
			end if;
			if(Ball_pos_y - BallSize >= bloco5_pos_y - BVsize and
				Ball_pos_y - BallSize <= bloco5_pos_y + BVsize) and
				(Ball_pos_x + BallSize >= bloco5_pos_x - BHsize and
				Ball_pos_x - BallSize <= bloco5_pos_x + BHsize) then
											
					bloco5 <= '0';
			end if;
			if(Ball_pos_y - BallSize >= bloco6_pos_y - BVsize and
				Ball_pos_y - BallSize <= bloco6_pos_y + BVsize) and
				(Ball_pos_x + BallSize >= bloco6_pos_x - BHsize and
				Ball_pos_x - BallSize <= bloco6_pos_x + BHsize) then
											
					bloco6 <= '0';
			end if;
		end if;
		
	end process;

	---Posição e direção da bola-----------
	
	process(ball_clk, reset, Ball_direction, move)
	
	begin
	
		if(reset = '0' or move = '0' or FimDeJogo = '1') then
			Ball_pos_x <= Ball_pos_x_inicial;
			Ball_pos_y <= Ball_pos_y_inicial;

			if(Ball_direction = DiagDireitaBaixo) then
				Ball_direction <= DiagDireitaCima;
				else
					Ball_direction <= Ball_direction + 1;
					
			end if;
		
		elsif(ball_clk'event and ball_clk = '1') then
			
			case Ball_direction is
			
				--Direções, 4 no total, todas diagonais
				
				when DiagDireitaCima => Ball_pos_x <= Ball_pos_x + 1; --Diagonal direita baixo 0
					Ball_pos_y <= Ball_pos_y - 1;
				when DiagEsquerdaCima => Ball_pos_x <= Ball_pos_x - 1; --Diagonal esquerda baixo 1
					Ball_pos_y <= Ball_pos_y - 1;
				when DiagEsquerdaBaixo => Ball_pos_x <= Ball_pos_x - 1; --Diagonal esquerda cima 2
					Ball_pos_y <= Ball_pos_y + 1;
				when DiagDireitaBaixo => Ball_pos_x <= Ball_pos_x + 1; --Diagonal direita cima 3 
					Ball_pos_y <= Ball_pos_y + 1;
			end case;
			
			--Colisão com os limites da tela
			if(Ball_pos_y = limSup) then
				
				if(Ball_direction = DiagDireitaCima) then
					Ball_direction <= DiagDireitaBaixo;
				elsif(Ball_direction = DiagEsquerdaCima) then
					Ball_direction <= DiagEsquerdaBaixo;
				end if;
			end if;
			
			if(Ball_pos_y = limInf) then
				
				if(Ball_direction = DiagEsquerdaBaixo) then
					Ball_direction <= DiagEsquerdaCima;
				elsif(Ball_direction = DiagDireitaBaixo) then
					Ball_direction <= DiagDireitaCima;
				end if;
			end if;
			
			if(Ball_pos_x = limLeft) then
				
				if(Ball_direction = DiagEsquerdaBaixo) then
					Ball_direction <= DiagDireitaBaixo;
				elsif(Ball_direction = DiagEsquerdaCima) then
					Ball_direction <= DiagDireitaCima;
				end if;
			end if;
			
			if(Ball_pos_x = limRight) then
				
				if(Ball_direction = DiagDireitaBaixo) then
					Ball_direction <= DiagEsquerdaBaixo;
				elsif(Ball_direction = DiagDireitaCima) then
					Ball_direction <= DiagEsquerdaCima;
				end if;
			end if;
			
			--Colisão com a raquete
			if(Ball_pos_y + BallSize >= paddle1_pos_y - PVsize and
				Ball_pos_y + BallSize <= paddle1_pos_y + PVsize) and
				(Ball_pos_x + BallSize >= paddle1_pos_x - PHsize and
					Ball_pos_x - BallSize <= paddle1_pos_x + PHsize) then

					if(Ball_direction = DiagEsquerdaBaixo) then
						Ball_direction <= DiagEsquerdaCima;
						elsif(Ball_direction = DiagDireitaBaixo) then
							Ball_direction <= DiagDireitaCima;
					end if;
			end if;
			-- Colisão com o bloco
			if(bloco1 = '1') then

				if(Ball_pos_y - BallSize >= bloco1_pos_y - BVsize and
					Ball_pos_y - BallSize <= bloco1_pos_y + BVsize) and
					(Ball_pos_x + BallSize >= bloco1_pos_x - BHsize and
					Ball_pos_x - BallSize <= bloco1_pos_x + BHsize) then
												
							if(Ball_direction = DiagEsquerdaCima) then
								Ball_direction <= DiagEsquerdaBaixo;
								elsif(Ball_direction = DiagDireitaCima) then
									Ball_direction <= DiagDireitaBaixo;
						end if;
				end if;
			end if;
			-- Colisão com o bloco
			if(bloco2 = '1') then

				if(Ball_pos_y - BallSize >= bloco2_pos_y - BVsize and
					Ball_pos_y - BallSize <= bloco2_pos_y + BVsize) and
					(Ball_pos_x + BallSize >= bloco2_pos_x - BHsize and
					Ball_pos_x - BallSize <= bloco2_pos_x + BHsize) then
												
						if(Ball_direction = DiagEsquerdaCima) then
							Ball_direction <= DiagEsquerdaBaixo;
							elsif(Ball_direction = DiagDireitaCima) then
								Ball_direction <= DiagDireitaBaixo;
						end if;
				end if;
			end if;
			if(bloco3 = '1') then

				if(Ball_pos_y - BallSize >= bloco3_pos_y - BVsize and
					Ball_pos_y - BallSize <= bloco3_pos_y + BVsize) and
					(Ball_pos_x + BallSize >= bloco3_pos_x - BHsize and
					Ball_pos_x - BallSize <= bloco3_pos_x + BHsize) then
												
							if(Ball_direction = DiagEsquerdaCima) then
								Ball_direction <= DiagEsquerdaBaixo;
								elsif(Ball_direction = DiagDireitaCima) then
									Ball_direction <= DiagDireitaBaixo;
							end if;
				end if;
			end if;
			if(bloco4 = '1') then

				if(Ball_pos_y - BallSize >= bloco3_pos_y - BVsize and
					Ball_pos_y - BallSize <= bloco3_pos_y + BVsize) and
					(Ball_pos_x + BallSize >= bloco3_pos_x - BHsize and
					Ball_pos_x - BallSize <= bloco3_pos_x + BHsize) then
												
							if(Ball_direction = DiagEsquerdaCima) then
								Ball_direction <= DiagEsquerdaBaixo;
								elsif(Ball_direction = DiagDireitaCima) then
									Ball_direction <= DiagDireitaBaixo;
							end if;
				end if;
			end if;
			if(bloco5 = '1') then

				if(Ball_pos_y - BallSize >= bloco3_pos_y - BVsize and
					Ball_pos_y - BallSize <= bloco3_pos_y + BVsize) and
					(Ball_pos_x + BallSize >= bloco3_pos_x - BHsize and
					Ball_pos_x - BallSize <= bloco3_pos_x + BHsize) then
												
							if(Ball_direction = DiagEsquerdaCima) then
								Ball_direction <= DiagEsquerdaBaixo;
								elsif(Ball_direction = DiagDireitaCima) then
									Ball_direction <= DiagDireitaBaixo;
							end if;
				end if;
			end if;
			if(bloco6 = '1') then

				if(Ball_pos_y - BallSize >= bloco3_pos_y - BVsize and
					Ball_pos_y - BallSize <= bloco3_pos_y + BVsize) and
					(Ball_pos_x + BallSize >= bloco3_pos_x - BHsize and
					Ball_pos_x - BallSize <= bloco3_pos_x + BHsize) then
												
						if(Ball_direction = DiagEsquerdaCima) then
							Ball_direction <= DiagEsquerdaBaixo;
							elsif(Ball_direction = DiagDireitaCima) then
								Ball_direction <= DiagDireitaBaixo;
						end if;
				end if;
			end if;
		end if;
	end process;
	
	---Máquina de estado do jogo-----------------
	process(pixel_clk, reset, Ball_pos_y)
	begin
	
		if(reset = '0' or FimDeJogo = '1') then
			State <= S0;
		
			elsif((Ball_pos_y > paddle1_pos_y + PVsize and
				Ball_pos_y <= limInf) and
				move = '1') then
					State <= S0;

			elsif(pixel_clk'event and pixel_clk = '1') then
				case state is
					when S0 =>
						if(start_game = '0') then
							State <= S1;
						end if;
					when S1 =>
							State <= S1;
				end case;
		end if;
	end process;
	
	process(State)
	begin
	case State is
		when S0 => move <= '0';
		when S1 => move <= '1';
	end case;
	end process;
	
	---Gerador de imagem--------------------
	
	process(paddle1_pos_x, paddle1_pos_y, dena, row_counter, col_counter)
	
	begin
		
		--Sinal que habilita que os dados sejam mostrados na tela
		if(dena = '1') then
		
				 --Detecção da raquete
			 if((paddle1_pos_x <= col_counter + PHsize) and
				(paddle1_pos_x + PHsize >= col_counter) and
				(paddle1_pos_y <= row_counter + PVsize) and
				(paddle1_pos_y + PVsize >= row_counter)) or
				
				--Detecção dos bloco
				(bloco1 = '1' and
				(bloco1_pos_x <= col_counter + BHsize) and
				(bloco1_pos_x + BHsize >= col_counter) and
				(bloco1_pos_y <= row_counter + BVsize) and
				(bloco1_pos_y + BVsize >= row_counter)) or

				(bloco2 = '1' and
				(bloco2_pos_x <= col_counter + BHsize) and
				(bloco2_pos_x + BHsize >= col_counter) and
				(bloco2_pos_y <= row_counter + BVsize) and
				(bloco2_pos_y + BVsize >= row_counter)) or

				(bloco3 = '1' and
				(bloco3_pos_x <= col_counter + BHsize) and
				(bloco3_pos_x + BHsize >= col_counter) and
				(bloco3_pos_y <= row_counter + BVsize) and
				(bloco3_pos_y + BVsize >= row_counter)) or

				(bloco4 = '1' and
				(bloco4_pos_x <= col_counter + BHsize) and
				(bloco4_pos_x + BHsize >= col_counter) and
				(bloco4_pos_y <= row_counter + BVsize) and
				(bloco4_pos_y + BVsize >= row_counter)) or

				(bloco5 = '1' and
				(bloco5_pos_x <= col_counter + BHsize) and
				(bloco5_pos_x + BHsize >= col_counter) and
				(bloco5_pos_y <= row_counter + BVsize) and
				(bloco5_pos_y + BVsize >= row_counter)) or

				(bloco6 = '1' and
				(bloco6_pos_x <= col_counter + BHsize) and
				(bloco6_pos_x + BHsize >= col_counter) and
				(bloco6_pos_y <= row_counter + BVsize) and
				(bloco6_pos_y + BVsize >= row_counter)) or

				 -- Detecção de bola
				((Ball_pos_x <= col_counter + BallSize) and
				(Ball_pos_x + BallSize >= col_counter) and
				(Ball_pos_y <= row_counter + BallSize) and
				(Ball_pos_y + BallSize >= row_counter))	then
				
					-- Raquete e cor da bola
					
					R <= "1111";
					G <= "1111";
					B <= "1111";
				
			else
				
					-- Cor do fundo
			
					R <= "0000";
					G <= "0000";
					B <= "0000";
				
			end if;
			
		else
		
			-- Se dena = 0, nenhuma cor precisa ser mostrada
		
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
			
		end if;
		
	end process;

end image_generator_arch;
			

	
