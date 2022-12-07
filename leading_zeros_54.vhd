--Circuito contador de ceros binarios en un argumento de 54 bits

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity leading_zeros_54 is
    Port ( A_in         : in  std_logic_vector (53 downto 0);
           num_zeros_54 : out  std_logic_vector (5 downto 0);
           Q_out        : out std_logic);
end leading_zeros_54;

architecture Behavioral of leading_zeros_54 is
    component leading_zeros_32 
        Port ( A            : in  std_logic_vector (31 downto 0);
               num_zeros_32 : out  std_logic_vector (4 downto 0);
               Q_ou         : out std_logic);
    end component;	

	signal QH, QL  : std_logic;
	signal zeros_H : std_logic_vector (4 downto 0);
	signal zeros_L : std_logic_vector (4 downto 0);
	signal A64     : std_logic_vector (63 downto 0);

begin
    A64 <= A_in&"0000000000";

highp: leading_zeros_32 
    Port map(A => A64(63 downto 32),
	         num_zeros_32 => zeros_H,
			 Q_ou => QH);

lowp: leading_zeros_32 
    Port map(A => A64(31 downto 0),
	         num_zeros_32 => zeros_L,
			 Q_ou => QL);

    num_zeros_54(5) <= QH;
	num_zeros_54(4 downto 0) <= zeros_H when QH='1' else
	                            zeros_L;
    Q_out <= QH and QL; 

end Behavioral;

