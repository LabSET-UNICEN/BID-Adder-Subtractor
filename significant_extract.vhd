-- Unidad de extraccion de mantisa, bit de redondeo (r*) y bit pegajoso (s*)
-- ENTRADAS:
--   P es la parte util del resultado de la multiplicacion
--   d es la cantidad de digitos decimales a desplazar a derecha sobre P

-- SALIDAS:
--   Ctmp es la mantisa resultante luego del redondeo. Contiene '0' adelante
--   r* es indicador de resto = 0.5
--   s* es indicador de que al menos algun bit restante del resto es '1'

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_shifter is
  port (P          : in  std_logic_vector(54 downto 0);  	--input
        d          : in  std_logic_vector(3 downto 0);   	-- position
        Ctmp       : out std_logic_vector(53 downto 0);  	--output
		r_asterisk : out std_logic;							-- bit r*
		s_asterisk : out std_logic							-- bit s* sticky bit
        );
end entity data_shifter;

architecture behavior of data_shifter is
  signal desp  : std_logic_vector(5 downto 0);
  signal resto : std_logic_vector(53 downto 0);
  signal temp1 : std_logic_vector(108 downto 0);
  signal temp2 : std_logic_vector(108 downto 0);
begin

-- d es la cantidad de digitos decimales a desplazar a la derecha
-- Se indexa una LUT con d para calculad la cantidad de bits, desp, a desplazar
  process(d)
  begin
   case d is
        when "0000" => desp <= "000000";  --desplaza 0 bits
        when "0001" => desp <= "000100";  --desplaza 4 bits
        when "0010" => desp <= "000111";  --desplaza 7 bits
        when "0011" => desp <= "001010";  --desplaza 10 bits
        when "0100" => desp <= "001110";  --desplaza 14 bits
        when "0101" => desp <= "010001";  --desplaza 17 bits
        when "0110" => desp <= "010100";  --desplaza 20 bits
        when "0111" => desp <= "011000";  --desplaza 24 bits
        when "1000" => desp <= "011011";  --desplaza 27 bits
        when "1001" => desp <= "011110";  --desplaza 30 bits
        when "1010" => desp <= "100010";  --desplaza 34 bits
        when "1011" => desp <= "100101";  --desplaza 37 bits
        when "1100" => desp <= "101000";  --desplaza 40 bits
        when "1101" => desp <= "101100";  --desplaza 44 bits
        when "1110" => desp <= "101111";  --desplaza 47 bits
        when "1111" => desp <= "110010";  --desplaza 50 bits
        when others => desp <= "000000";
   end case;        
  end process;
  
-- desplaza desp bits a la derecha obteniendo Ctmp y resto
--  process(desp)
--  begin
     --temp1 <= P & x"0000000000000000";
     temp1 <= P(53 downto 0) & "000" & x"0000000000000";
     temp2 <= std_logic_vector(shift_right(unsigned(temp1), to_integer(unsigned(desp))));
     Ctmp <= temp2(108 downto 55);  
     resto <= temp2(53 downto 0); 
 --  end process;

-- calcula r*
   r_asterisk <= resto(53);
 
-- calcula s*   
   process (resto)
   begin
     if  unsigned(resto(52 downto 0)) = 0 then
        s_asterisk <= '0';
     else 
        s_asterisk <= '1';
     end if;
   end process;  
  
end architecture behavior;