-- Unidad de redondeo de un solo digito
--   ENTRADAS
--       Ci_53_0 mantisa de entrada. Es el resultado de la operacion que se realizÃ³ y hay que redondear
--       d_10_0  redondea solo 1 digito decimal
--       Si signo de la mantisa de entrada
--	     rounding_mode modo de redondeo (RTE, RTA, RTZ, RTN o RTP)

--   SALIDAS
--	     Co mantisa redondeada de salida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rounding_unit_one is
  port (Ci            : IN std_logic_vector (53 downto 0);		-- mantisa de entrada
        d             : IN std_logic_vector (10 downto 0);		-- digitos decimales a redondear
        Si            : IN std_logic;					        -- signo de la mantisa
	    rounding_mode : IN std_logic_vector(2 downto 0);		-- modo de redondeo
	    Co            : OUT std_logic_vector(53 downto 0)		-- resultado
        );
end entity rounding_unit_one;

architecture behavior of rounding_unit_one is

component data_shifter
  port(P          : in  std_logic_vector(54 downto 0);  	--input
       d          : in  std_logic_vector(3 downto 0);   	-- position
       Ctmp       : out std_logic_vector(53 downto 0);  	--output
	   r_asterisk : out std_logic;							-- bit r*
	   s_asterisk : out std_logic);							-- bit s* sticky bit
end component;

-- d_10_0 es la cantidad de digitos decimales a desplazar a la derecha
-- Se indexa una LUT con d_10_0 para calcular la cantidad de bits, desp, a desplazar
  signal W_P : std_logic_vector(108 downto 0);
  signal W_Ctmp : std_logic_vector(53 downto 0);
  signal W_r_asterisk : std_logic;
  signal W_s_asterisk : std_logic;
  signal W_Wc : std_logic_vector(54 downto 0);
  signal bypass_mux1_ctrl : std_logic;
  signal bypass_mux2_ctrl : std_logic;
  signal dmay16_mux1_ctrl : std_logic;
  signal result_mux_ctrl : std_logic;
  signal W_mux1_out : std_logic_vector(53 downto 0);
  signal W_mux2_out : std_logic_vector(53 downto 0);
  signal W_mux16 : std_logic_vector(53 downto 0);
  
begin  
-- logica de ByPass
--  process(d_10_0)
--  begin
--     --d>16_MUX1_Ctrl = d > 16
--     if unsigned(d_10_0) > 16 then
--         dmay16_mux1_ctrl <= '1';
--     else
--         dmay16_mux1_ctrl <= '0';
--     end if;
     
--     --ByPass_MUX1_Ctrl = d == 0
--     if d_10_0 = "0000000000" then
--         bypass_mux1_ctrl <= '1';
--     else
--         bypass_mux1_ctrl <= '0';
--     end if;
     
--     --ByPass_MUX2_Ctrl = (d > 0) & (d <= 16) = not(d>16 MUX1_Ctrl or ByPass_MUX1_Ctrl)
--     if (unsigned(d_10_0) > 0) and (unsigned(d_10_0) <= 16) then
--         bypass_mux2_ctrl <= '1';
--     else
--         bypass_mux2_ctrl <= '0';
--     end if;
--  end process;
  
  -- logica de modo de redondeo
  -- MODOS 
  -- roundingmode       modo        resultado
  --     000            RTZ            Ctmp
  --     100            RTE          Ctmp + 1
  --     101            RTP          Ctmp + 1
  --     110            RTN          Ctmp + 1
  --     111            RTA          Ctmp + 1
  
 process(W_r_asterisk, W_s_asterisk, W_Ctmp(0), bypass_mux2_ctrl, Si, rounding_mode)
 begin
    if rounding_mode(2) = '1' then  -- modos que incrementan Ctmp si se dan las otras condiciones
        if ((W_r_asterisk = '1') and ((W_s_asterisk = '1') or (W_Ctmp(0) = '1'))) or   --RTE
           ((Si = '0') and (W_s_asterisk = '1' or W_r_asterisk = '1')) or                   --RTP
           ((Si = '1') and (W_s_asterisk = '1' or W_r_asterisk = '1')) or                   --RTN
           (W_r_asterisk = '1') then                                                        --RTA
               result_mux_ctrl <= '1';
        else                                                                                --RTZ
               result_mux_ctrl <= '0';
        end if;
    else                                                                                    --RTZ
        result_mux_ctrl <= '0';                     
    end if;
 end process;
 
 -- MUX de bypass 1
-- W_mux1_out <= Ci when bypass_mux1_ctrl = '1' else
--               "00" & x"0000000000000";
               
-- MUX de bypass 2
-- W_mux2_out <= W_Ctmp when bypass_mux2_ctrl = '1' else
--               W_mux1_out;
               
-- MUX X>16
-- W_mux16 <= W_Ctmp when dmay16_mux1_ctrl = '0' else
--            "00" & x"0000000000000";
            
-- MUX de resultado
 Co <= (W_Ctmp + 1) when result_mux_ctrl = '1' else
            W_Ctmp;
            
 -- LUT generador de Wc = 1/Wd
--  process(d_10_0)
--  begin
--   case d_10_0(3 downto 0) is
--        when "0001" => W_Wc <= "110" & x"6666666666667";     --x"0066666666666667";
--        when "0010" => W_Wc <= "101" & x"1eb851eb851ec";     --x"0051eb851eb851ec";
--        when "0011" => W_Wc <= "100" & x"189374bc6a7f0";     --x"004189374bc6a7f0";
--        when "0100" => W_Wc <= "110" & x"8db8bac710cb3";     --x"0068db8bac710cb3";
--        when "0101" => W_Wc <= "101" & x"3e2d6238da3c3";     --x"0053e2d6238da3c3";
--        when "0110" => W_Wc <= "100" & x"31bde82d7b635";     --x"00431bde82d7b635";
--        when "0111" => W_Wc <= "110" & x"b5fca6af2bd22";     --x"006b5fca6af2bd22";
--        when "1000" => W_Wc <= "101" & x"5e63b88c230e8";     --x"0055e63b88c230e8";
--        when "1001" => W_Wc <= "100" & x"4b82fa09b5a53";     --x"0044b82fa09b5a53";
--        when "1010" => W_Wc <= "110" & x"df37f675ef6eb";     --x"006df37f675ef6eb";
--        when "1011" => W_Wc <= "101" & x"7f5ff85e59256";     --x"0057f5ff85e59256";
--        when "1100" => W_Wc <= "100" & x"65e6604b7a845";     --x"00465e6604b7a845";
--        when "1101" => W_Wc <= "111" & x"09709a125da08";     --x"00709709a125da08";
--        when "1110" => W_Wc <= "101" & x"a126e1a84ae6d";     --x"005a126e1a84ae6d";
--        when "1111" => W_Wc <= "100" & x"80ebe7b9d5857";     --x"00480ebe7b9d5857";
--        when others => W_Wc <= "000" & x"0000000000000";     --x"0000000000000000";
--   end case;        
--  end process;

-- siempre se redondea un dígito, entonces el multiplicador W_Wc siempre es 1/10
W_Wc <= "110" & x"6666666666667";

-- multiplicacion de mantisa por 1/Wd  
--  W_P <= Ci_53_0&"000"&x"0000000000000" when d_10_0 ="0000" else
--         Ci_53_0 * W_Wc ;
   W_P <= Ci * W_Wc;
 
 
-- redondeo y generacion de r* y s* 
 extraccion: data_shifter 
 port map(
       P => W_P(108 downto 54),
       d => d(3 downto 0),
       Ctmp => W_Ctmp,
	   r_asterisk => W_r_asterisk,
	   s_asterisk => W_s_asterisk
 );
 
 
  
end architecture behavior;