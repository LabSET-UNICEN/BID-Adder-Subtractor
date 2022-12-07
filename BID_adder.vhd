-- Sumador/restador DFP BID con redondeo
-- Implementa los casos III y II de TSEN de forma combinacional 
-- Usa multiplicadores de 54 bits

--   ENTRADAS
--       Ac mantisa del operando de entrada A
--       Bc mantisa del operando de entrada B
--       Asign signo del operando de entrada A
--       Bsign signo del operando de entrada B
--       Aexp exponente del operando de entrada A
--       Bexp exponente del operando de entrada B
--       Op operacion a realizar: suma o resta

--   SALIDAS
--	     Zc mantisa redondeada de salida
--       Zsign signo de salida
--       Zic exponente de salida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity BID_adder is
 port (B_Ac            : IN std_logic_vector (53 downto 0);		-- mantisa de entrada A
       B_Asign		   : IN std_logic;							-- signo de entrada A
       B_Aexp		   : IN std_logic_vector (9 downto 0);		-- exponente de entrada A

       B_Bc            : IN std_logic_vector (53 downto 0);		-- mantisa de entrada B
       B_Bsign		   : IN std_logic;							-- signo de entrada B
       B_Bexp          : IN std_logic_vector (9 downto 0);		-- exponente de entrada B

       B_Op			   : IN std_logic;							-- 0: suma - 1: resta
       B_round_mode    : IN std_logic_vector(2 downto 0);       -- modo de redondeo
       
       rst             : IN std_logic;                          -- reset de registros
       clk             : IN std_logic;                          -- clock
	   
        B_Zc           : OUT std_logic_vector (53 downto 0);	-- mantisa de salida
       B_Zc_sign	   : OUT std_logic;							-- signo de salida
       B_Zc_exp		   : OUT std_logic_vector (9 downto 0)		-- exponente de salida
      );
end entity BID_adder;


architecture behavior of BID_adder is

-- unidad de redondeo de 64 bits
   COMPONENT rounding_unit
   PORT(
       Ci            : IN std_logic_vector (53 downto 0);		-- mantisa de entrada
       d             : IN std_logic_vector (10 downto 0);		-- digitos decimales a redondear
       Si            : IN std_logic;						    -- signo de la mantisa
	   rounding_mode : IN std_logic_vector(2 downto 0);			-- modo de redondeo
	   Co            : OUT std_logic_vector(53 downto 0));		-- resultado
   END COMPONENT;	

-- unidad de desplazamiento bidireccional de 64 bits

-- unidad de redondeo especializada que redondeo solo un digito   
   COMPONENT rounding_unit_one
   PORT(
       Ci            : IN std_logic_vector (53 downto 0);		-- mantisa de entrada
       d             : IN std_logic_vector (10 downto 0);		-- digitos decimales a redondear
       Si            : IN std_logic;						    -- signo de la mantisa
	   rounding_mode : IN std_logic_vector(2 downto 0);			-- modo de redondeo
	   Co            : OUT std_logic_vector(53 downto 0));		-- resultado
   END COMPONENT;	
   
   COMPONENT digits_counter
   PORT ( 
       A                                  : in  std_logic_vector (53 downto 0);
       Qa                                 : out std_logic_vector (4 downto 0));
   END COMPONENT;


--outputs from rounder
	   SIGNAL rounder_output             : std_logic_vector(53 downto 0);
	   

-- operacion efectiva a realizar dentro del modulo (0=suma o 1=resta)
	   SIGNAL ope                        : std_logic;
	   
-- diferencia entre exponentes.
	   SIGNAL K                          : std_logic_vector (9 downto 0);
-- indicador de swaping
	   SIGNAL signo                      : std_logic;

-- señales de almacenamiento de AN y BN donde ANexp siempre es mayor que BNexp
       SIGNAL ANc                        : std_logic_vector(53 downto 0);
       SIGNAL ANc_aux                    : std_logic_vector(63 downto 0);
       SIGNAL BNc                        : std_logic_vector(53 downto 0);
       SIGNAL BNc_aux                    : std_logic_vector(53 downto 0);
       SIGNAL ANexp                      : std_logic_vector(9 downto 0);
       SIGNAL BNexp                      : std_logic_vector(9 downto 0);
       SIGNAL ANsign                     : std_logic;
       SIGNAL BNsign                     : std_logic;
       
       SIGNAL Ac                         : std_logic_vector(53 downto 0);
       SIGNAL Bc                         : std_logic_vector(53 downto 0);
       SIGNAL Aexp                       : std_logic_vector(9 downto 0);
       SIGNAL Bexp                       : std_logic_vector(9 downto 0);
       SIGNAL Asign                      : std_logic;
       SIGNAL Bsign                      : std_logic;
       
       SIGNAL Qa                         : std_logic_vector (4 downto 0);
       SIGNAL Qi                         : std_logic_vector (4 downto 0);
       SIGNAL gprima                     : std_logic_vector (4 downto 0);
       SIGNAL g                          : std_logic_vector (4 downto 0);
       SIGNAL g_plus_1                   : std_logic_vector (4 downto 0);
       SIGNAL kog                        : std_logic_vector (4 downto 0);
       
       SIGNAL ZIc                        : std_logic_vector(53 downto 0);
       SIGNAL ZI_neg                     : std_logic_vector(53 downto 0);       
       SIGNAL ZI_neg_alt                 : std_logic_vector(53 downto 0);       
       SIGNAL ZIc_alt                    : std_logic_vector(53 downto 0);
       SIGNAL ZI                         : std_logic_vector(54 downto 0);
       SIGNAL ZI_alt                     : std_logic_vector(54 downto 0);
       SIGNAL ZIc_noround                : std_logic_vector(53 downto 0);
       SIGNAL pow_of_ten                 : std_logic_vector(53 downto 0);
       SIGNAL pow_of_ten1                : std_logic_vector(53 downto 0);
       SIGNAL AN_aux                     : std_logic_vector(107 downto 0);
       SIGNAL AN_aux1                    : std_logic_vector(107 downto 0);
       SIGNAL ANaux                      : std_logic_vector(9 downto 0);
       SIGNAL op_B                       : std_logic_vector(53 downto 0);
       SIGNAL op_B_alt                   : std_logic_vector(53 downto 0);
       SIGNAL op_A                       : std_logic_vector(53 downto 0);
       SIGNAL op_A_alt                   : std_logic_vector(53 downto 0);       
       SIGNAL d3                         : std_logic_vector(10 downto 0);
       SIGNAL d_to_round                 : std_logic_vector(10 downto 0);
       SIGNAL d3_1                       : std_logic_vector(10 downto 0);
       SIGNAL d3_2                       : std_logic_vector(10 downto 0);
       SIGNAL d3_minus_1                 : std_logic_vector(10 downto 0);
       SIGNAL Zc                         : std_logic_vector(53 downto 0);
       SIGNAL Zc_sign                    : std_logic;
       SIGNAL Zc_exp	  	             : std_logic_vector (9 downto 0);
       SIGNAL flag_mayor                 : std_logic;
       SIGNAL flag_auxi                  : std_logic;
       SIGNAL flag_menor                 : std_logic;
       SIGNAL Op                         : std_logic;
       SIGNAL ne                         : std_logic;
       SIGNAL ne_alt                     : std_logic;
       SIGNAL sr                         : std_logic;
       SIGNAL sr_alt                     : std_logic;       
       SIGNAL round_mode                 : std_logic_vector (2 downto 0);
 
begin  
-- registro de entradas y salidas
-- ======================
   Acp: process (clk, rst)
   begin
      if rst='1' then
         Ac <= "00"&x"0000000000000";
      elsif (clk'event and clk='1') then
         Ac <= B_Ac;
      end if;   
   end process;
   
   RAsign: process (clk, rst)
   begin
      if rst='1' then
         Asign <= '0';
      elsif (clk'event and clk='1') then
         Asign <= B_Asign;
      end if;   
   end process;
   
   RAexp: process (clk, rst)
   begin
      if rst='1' then
         Aexp <= "0000000000";
      elsif (clk'event and clk='1') then
         Aexp <= B_Aexp;
      end if;   
   end process;
   
   Bcp: process (clk, rst)
   begin
      if rst='1' then
         Bc <= "00"&x"0000000000000";
      elsif (clk'event and clk='1') then
         Bc <= B_Bc;
      end if;   
   end process;
   
   RBsign: process (clk, rst)
   begin
      if rst='1' then
         Bsign <= '0';
      elsif (clk'event and clk='1') then
         Bsign <= B_Bsign;
      end if;   
   end process;
   
   RBexp: process (clk, rst)
   begin
      if rst='1' then
         Bexp <= "0000000000";
      elsif (clk'event and clk='1') then
         Bexp <= B_Bexp;
      end if;   
   end process;
   
   Zcp: process (clk, rst)
   begin
      if rst='1' then
         B_Zc <= "00"&x"0000000000000";
      elsif (clk'event and clk='1') then
         B_Zc <= Zc(53 downto 0);
      end if;   
   end process;
   
   Zsign: process (clk, rst)
   begin
      if rst='1' then
         B_Zc_sign <= '0';
      elsif (clk'event and clk='1') then
         B_Zc_sign <= Zc_sign;
      end if;   
   end process;
   
   Zexp: process (clk, rst)
   begin
      if rst='1' then
         B_Zc_exp <= "0000000000";
      elsif (clk'event and clk='1') then
         B_Zc_exp <= Zc_exp;
      end if;   
   end process;
   
   operation: process (clk, rst)
   begin
      if rst='1' then
         Op <= '0';
      elsif (clk'event and clk='1') then
         Op <= B_Op;
      end if;   
   end process;
   
   mode: process (clk, rst)
   begin
      if rst='1' then
         round_mode <= "000";
      elsif (clk'event and clk='1') then
         round_mode <= B_round_mode;
      end if;   
   end process;
-- ======================


-- calculo de operacion efectiva
-- ======================
   ope <= Op xor Asign xor Bsign;
-- ======================
   
-- Calcula la diferencia K entre los dos exponentes. K siempre mayor que 0
-- ======================
   absolute:process(Aexp, Bexp)
      variable Kaux : std_logic_vector (9 downto 0);
   begin
      Kaux := Aexp - Bexp;
      if Kaux(9) = '0' then
         K <= Kaux;
         signo <= '0';
      else 
         K <= not(Kaux)+1;
         signo <= '1';
      end if;
   end process;
-- ======================
   
-- Swaping de A y B en funcion de la señal signo 
-- de manera que ANexp sea mayor o igual a BNexp
-- ======================
   ANc <= Ac  when signo='0' else Bc;
   BNc <= Bc  when signo='0' else Ac;
   ANexp <= Aexp   when signo='0' else Bexp;
   BNexp <= Bexp   when signo='0' else Aexp;
   ANsign <= Asign when signo='0' else Bsign;
   BNsign <= Bsign when signo='0' else Asign;
-- ======================  

    
--Calculo de la cantidad de digitos decimales de ANc 
-- ======================
   contador: digits_counter port map(
             A  => ANc,
             Qa => Qa             
   );
-- ======================   


-- calculo de g y g+1
-- ======================   
   gprima <= 16-Qa; 
   g <= "00000" when k="00000" else gprima;  
   g_plus_1 <= g+1;   
-- ======================   


--   d3 = K - g
--   d3_prima = g - K
--   d3_minus_1 = d3 - 1
--   d3_plus_1 = d3_prima + 1
-- ======================
   d3_1 <= '0'&K;
   d3_2 <= "000000"&g;

   d3 <= d3_1-d3_2;
   d3_minus_1 <= d3-1;

-- ======================          
-- Calculo de la ruta principal
-- Se indexa una LUT con digits para calcular 10**digits en la señal pow_of_ten
-- para las potencias 2**n + 1 hay ambiguedad que se resuelve mas abajo
-- ======================
   Kog <= g when ("00000"&g) < K else K(4 downto 0); 
   LUT_pow_of_ten:process(Kog)
   begin
    case Kog is
        when "00000" => pow_of_ten <= "00" & x"0000000000001";  --x"0000000000000001";  
        when "00001" => pow_of_ten <= "00" & x"000000000000a";  --x"000000000000000a";  
        when "00010" => pow_of_ten <= "00" & x"0000000000064";  --x"0000000000000064";  
        when "00011" => pow_of_ten <= "00" & x"00000000003e8";  --x"00000000000003e8";  
        when "00100" => pow_of_ten <= "00" & x"0000000002710";  --x"0000000000002710";  
        when "00101" => pow_of_ten <= "00" & x"00000000186a0";  --x"00000000000186a0";  
        when "00110" => pow_of_ten <= "00" & x"00000000f4240";  --x"00000000000f4240";  
        when "00111" => pow_of_ten <= "00" & x"0000000989680";  --x"0000000000989680";  
        when "01000" => pow_of_ten <= "00" & x"0000005f5e100";  --x"0000000005f5e100";  
        when "01001" => pow_of_ten <= "00" & x"000003b9aca00";  --x"000000003b9aca00";  
        when "01010" => pow_of_ten <= "00" & x"00002540be400";  --x"00000002540be400";  
        when "01011" => pow_of_ten <= "00" & x"000174876e800";  --x"000000174876e800";  
        when "01100" => pow_of_ten <= "00" & x"000e8d4a51000";  --x"000000e8d4a51000";  
        when "01101" => pow_of_ten <= "00" & x"009184e72a000";  --x"000009184e72a000";  
        when "01110" => pow_of_ten <= "00" & x"05af3107a4000";  --x"00005af3107a4000";  
        when "01111" => pow_of_ten <= "00" & x"38d7ea4c68000";  --x"00038d7ea4c68000";  
        when "10000" => pow_of_ten <= "10" & x"386f26fc10000";  --x"0002386f26fc1000";  
--        when "10001" => pow_of_ten <= x"016345785d8a0000";  
--        when "10010" => pow_of_ten <= x"0de0b6b3a7640000";  
--        when "10011" => pow_of_ten <= x"8ac7230489e80000";  
        when others  => pow_of_ten <= "00" & x"0000000000000";
    end case;        
   end process;
-- ======================   
  
-- Genera el producto parcial ANc * 10**g que sera el operando 1 de la suma/resta
-- ======================
   AN_aux <= ANc * pow_of_ten;
   op_A <= AN_aux(53 downto 0);
-- ======================   


-- desplazamiento de BNc en d3 digitos
-- ======================   
   d_to_round  <= d3 when g < k else "00000000000";
   shift_BNc: rounding_unit port map(
            Ci => BNc,
            d => d_to_round,
            Si => BNsign, 
			rounding_mode => "000",
			Co => op_B
   );
-- ======================

--Suma o resta de op_A y op_B
-- ======================
  ZI <= ('0'&op_A) + ('0'&op_B) when ope='0' else
         ('0'&op_A) - ('0'&op_B) when ope='1' else
         (others => '0');
-- ======================     

-- ne not(CarryOut) and ope
   ne <= not(ZI(54)) and ope;

-- ZI_neg = NEG(ZI)
-- ======================
  ZI_neg <= (ZI(53 downto 0) xor ("00"&x"1111111111111"))+1;
-- ======================     
     
  ZIc <= ZI(53 downto 0) when ne='0' else ZI_neg;

  sr <= ne xor ANsign;

-- CALCULO  DE LA RUTA ALTERNATIVA (SI LA MANTISA RESULTANTE ES MENOR QUE 10**15)
-- =========================================================================================================

-- Se indexa una LUT con g+1 para calcular 10**g+1 en la señal pow_of_ten
-- para las potencias 2**n + 1 hay ambiguedad que se resuelve mas abajo
-- ======================
   LUT_pow_of_ten1:process(g_plus_1)
   begin
    case g_plus_1 is
        when "00000" => pow_of_ten1 <= "00" & x"0000000000001";  --x"0000000000000001";  
        when "00001" => pow_of_ten1 <= "00" & x"000000000000a";  --x"000000000000000a";  
        when "00010" => pow_of_ten1 <= "00" & x"0000000000064";  --x"0000000000000064";  
        when "00011" => pow_of_ten1 <= "00" & x"00000000003e8";  --x"00000000000003e8";  
        when "00100" => pow_of_ten1 <= "00" & x"0000000002710";  --x"0000000000002710";  
        when "00101" => pow_of_ten1 <= "00" & x"00000000186a0";  --x"00000000000186a0";  
        when "00110" => pow_of_ten1 <= "00" & x"00000000f4240";  --x"00000000000f4240";  
        when "00111" => pow_of_ten1 <= "00" & x"0000000989680";  --x"0000000000989680";  
        when "01000" => pow_of_ten1 <= "00" & x"0000005f5e100";  --x"0000000005f5e100";  
        when "01001" => pow_of_ten1 <= "00" & x"000003b9aca00";  --x"000000003b9aca00";  
        when "01010" => pow_of_ten1 <= "00" & x"00002540be400";  --x"00000002540be400";  
        when "01011" => pow_of_ten1 <= "00" & x"000174876e800";  --x"000000174876e800";  
        when "01100" => pow_of_ten1 <= "00" & x"000e8d4a51000";  --x"000000e8d4a51000";  
        when "01101" => pow_of_ten1 <= "00" & x"009184e72a000";  --x"000009184e72a000";  
        when "01110" => pow_of_ten1 <= "00" & x"05af3107a4000";  --x"00005af3107a4000";  
        when "01111" => pow_of_ten1 <= "00" & x"38d7ea4c68000";  --x"00038d7ea4c68000";  
        when "10000" => pow_of_ten1 <= "10" & x"386f26fc10000";  --x"0002386f26fc1000";  
--        when "10001" => pow_of_ten <= x"016345785d8a0000";  
--        when "10010" => pow_of_ten <= x"0de0b6b3a7640000";  
--        when "10011" => pow_of_ten <= x"8ac7230489e80000";  
        when others  => pow_of_ten1 <= "00" & x"0000000000000";
    end case;        
   end process;
-- ======================   
  
-- Genera el producto parcial ANc * 10**g que sera el operando 1 de la suma/resta
-- ======================
   AN_aux1 <= ANc * pow_of_ten1;
   op_A_alt <= AN_aux1(53 downto 0);
-- ======================   

-- desplazamiento de BNc en d3-1 digitos
-- ======================   
   Shift_BNc_minus_1: rounding_unit port map(
            Ci => BNc,
            d => d3_minus_1,
            Si => BNsign, 
			rounding_mode => "000",
			Co => op_B_alt
   );
-- ======================

--Suma o resta de op_A_alt y op_B_alt
-- ======================
  ZI_alt <= ('0'&op_A_alt) + ('0'&op_B_alt) when ope='0' else
         ('0'&op_A_alt) - ('0'&op_B_alt) when ope='1' else
         (others => '0');
-- ======================     

   ne_alt <= not(ZI_alt(54)) and ope;

-- ZI_neg = NEG(ZI)
-- ======================
  ZI_neg_alt <= (ZI_alt(53 downto 0) xor ("00"&x"1111111111111"))+1;
-- ======================     
     
  ZIc_alt <= ZI_alt(53 downto 0) when ne='0' else ZI_neg_alt;

  sr_alt <= ne xor ANsign;

-- =========================================================================================================
 

--calculo del signo del resultado Zc_sign
-- ======================
  Zc_sign <= sr;

-- ====================== 

 --Cuenta la cantidad de digitos decimales del resultado parcial ZIc
-- ======================
   contador2: digits_counter port map(
             A  => ZIc,
             Qa => Qi             
   );
-- ======================   

-- redondea el resultado en un digito para el caso de que sea mayor a 10**16
-- ======================   
   Round_ZIc_in_1: rounding_unit_one port map(
            Ci => ZIc,
            d => "00000000001",
            Si => Zc_sign, 
			rounding_mode => round_mode,
			Co => rounder_output
   );
-- ======================

-- Seleccion de mantisa y exponente de salida
-- en funcion de si ZIc es mayor 10**16 ó menor que 10**15 o esta en el medio

--genera los flags: flag_mayor y flag_menor donde
--   flag_mayor = ZIc > 10**16
--   flag_menor = ZIc <= 10**15
-- ======================
   flag_mayor <= '1' when ZIc >= "10"&x"386f26fc10000" else '0';
   flag_auxi  <= '1' when ZIc < "11"&x"8d7ea4c680000" else '0';
   flag_menor <= flag_auxi when (k /= "00000") else '0';
-- ======================

-- ZI_noround recibe ZIc o ZIc_alt segun ZIc < 10**15
   ZIc_noround <= ZIc_alt when flag_menor='1' else ZIc;

-- Zc recibe ZIc redondeado en 1  o  ZIc_noround segun ZIc > 10**16
   Zc <= rounder_output when flag_mayor='1' else ZIc_noround;


--genera el exponente Zc_exp
-- Zc_exp = ANexp-g+1      si flag_mayor
-- Zc_exp = ANexp-g-1      si flag_menor
-- Zc_exp = ANexp-g        other
-- ======================
   ANaux <= ANexp-("00000"&g_plus_1);
    
   process(flag_mayor, flag_menor)
   variable expaux : std_logic_vector(9 downto 0);
   begin
      if flag_mayor = '1' then
         expaux := ANaux+1; 
      else if flag_menor = '1' then
              expaux := ANaux-1;
           else
              expaux := ANaux;
           end if;
      end if;   
      Zc_exp <= expaux;
   end process; 
-- ======================
end architecture behavior;
