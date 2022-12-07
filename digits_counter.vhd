--Circuito contador de digitos decimales en una mantisa en BID

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity digits_counter is
    Port ( A : in  std_logic_vector (53 downto 0);
           Qa : out std_logic_vector (4 downto 0));
end digits_counter;

architecture Behavioral of digits_counter is

    component leading_zeros_54 
        Port ( A_in          : in  std_logic_vector (53 downto 0);
               num_zeros_54  : out  std_logic_vector (5 downto 0);
               Q_out         : out std_logic);
    end component;	

    signal first_one : std_logic_vector (5 downto 0);	
    signal digits : std_logic_vector(4 downto 0);
    signal pow_of_ten : std_logic_vector(53 downto 0);
    signal sal_aux : std_logic_vector(53 downto 0);
    signal cant_zeros : std_logic_vector(5 downto 0);
    signal QH : std_logic;


begin

zeros: leading_zeros_54 
    Port map(A_in => A,
	         num_zeros_54 => cant_zeros,
			 Q_out => QH	
	);
	first_one <= 63 - cant_zeros;

-- Se indexa una LUT con first_one para calcular el numero de digitos decimales en la señal digits
-- para las potencias 2**n + 1 hay ambiguedad que se resuelve mas abajo
  LUT_num_digits:process(first_one)
  begin
   case first_one is
        when "000000" => digits <= "00001";  
        when "000001" => digits <= "00001";  
        when "000010" => digits <= "00001";  
        when "000011" => digits <= "00001";  
        when "000100" => digits <= "00010";  
        when "000101" => digits <= "00010";  
        when "000110" => digits <= "00010";  
        when "000111" => digits <= "00011";  
        when "001000" => digits <= "00011";  
        when "001001" => digits <= "00011";  
        when "001010" => digits <= "00100";  
        when "001011" => digits <= "00100";  
        when "001100" => digits <= "00100";  
        when "001101" => digits <= "00100";  
        when "001110" => digits <= "00101";  
        when "001111" => digits <= "00101";  
        when "010000" => digits <= "00101";  
        when "010001" => digits <= "00110";  
        when "010010" => digits <= "00110";  
        when "010011" => digits <= "00110";  
        when "010100" => digits <= "00111";  
        when "010101" => digits <= "00111";  
        when "010110" => digits <= "00111";  
        when "010111" => digits <= "00111";  
        when "011000" => digits <= "01000";  
        when "011001" => digits <= "01000";  
        when "011010" => digits <= "01000";  
        when "011011" => digits <= "01001";  
        when "011100" => digits <= "01001";  
        when "011101" => digits <= "01001";  
        when "011110" => digits <= "01010";  
        when "011111" => digits <= "01010";  
        when "100000" => digits <= "01010";  
        when "100001" => digits <= "01010";  
        when "100010" => digits <= "01011";  
        when "100011" => digits <= "01011";  
        when "100100" => digits <= "01011";  
        when "100101" => digits <= "01100";  
        when "100110" => digits <= "01100";  
        when "100111" => digits <= "01100";  
        when "101000" => digits <= "01101";  
        when "101001" => digits <= "01101";  
        when "101010" => digits <= "01101";  
        when "101011" => digits <= "01101";  
        when "101100" => digits <= "01110";  
        when "101101" => digits <= "01110";  
        when "101110" => digits <= "01110";  
        when "101111" => digits <= "01111";  
        when "110000" => digits <= "01111";  
        when "110001" => digits <= "01111";  
        when "110010" => digits <= "10000";  
        when "110011" => digits <= "10000";  
        when "110100" => digits <= "10000";  
        when "110101" => digits <= "10000";  
        when "110110" => digits <= "10001";  
        when "110111" => digits <= "10001";  
        when "111000" => digits <= "10001";  
        when "111001" => digits <= "10010";  
        when "111010" => digits <= "10010";  
        when "111011" => digits <= "10010";  
        when "111100" => digits <= "10011";  
        when "111101" => digits <= "10011";  
        when "111110" => digits <= "10011";  
        when "111111" => digits <= "10011";  
        when others => digits <= "00000";
   end case;        
  end process;


-- Se indexa una LUT con digits para calcular 10**digits en la señal pow_of_ten
-- para las potencias 2**n + 1 hay ambiguedad que se resuelve mas abajo
  LUT_pow_of_ten:process(digits)
  begin
   case digits is
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

  -- si A<10**n el numero tiene n digitos, sino tiene n+1 digitos
  comparate:process(digits, A, pow_of_ten)
  variable Qaux : std_logic_vector(4 downto 0);
  begin
     if A<pow_of_ten then
        Qaux := digits;
     else
        Qaux := digits+1;
     end if;
     Qa <= Qaux;
  end process;

  

end Behavioral;

