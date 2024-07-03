library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CIC_DEFEAT is
port
	(
		m2        : in std_logic;
		cic_reset : out std_logic
	);
end CIC_DEFEAT;

architecture logic of CIC_DEFEAT is

	signal counter : std_logic_vector(7 downto 0);

begin

	cic_reset <= '0' when counter(7 downto 4) = "1111" else
	             '1';

	process( m2 )
	begin
		if( falling_edge(m2) ) then
			counter <= std_logic_vector( unsigned(counter) + 1 );
		end if;
		
	end process;
	
end logic;
			
			
			
			
			
			
			
			
			
			
			