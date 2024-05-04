--NES MMC1 mapper implementation.
--Copyright 2013 David Senabre Albujer
--Free-open source implementation.
--
--Tested succesfully in on Xilinx XC9572 CPLD and SNROM PCB
--
--website:
--www.consolasparasiempre.net
--
--    This file is part of MMC1 mapper implementation.
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shift_reg is
    generic( N: integer := 4);
    port ( sIn : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           pOut: out STD_LOGIC_VECTOR (N-1 downto 0));
end shift_reg;

architecture arch of shift_reg is

signal reg_next, reg : STD_LOGIC_VECTOR( N-1 downto 0 );

begin

   process( clk, rst )
   begin
      if (clk'event and clk = '1') then
         if (rst = '0') then
            reg <= (others => '0');
         else
            reg <= reg_next;
         end if;
      end if;
   end process;
   
   reg_next <= sIn & reg(N-1 downto 1);
   
   pOut <= reg;

end arch;

