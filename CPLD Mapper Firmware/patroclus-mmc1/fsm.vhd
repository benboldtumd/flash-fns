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

entity fsm is
    Port ( sRst : in  STD_LOGIC;
           clk  : in  STD_LOGIC;
           reg_e : out  STD_LOGIC);
end fsm;

architecture arch of fsm is

   type mmc1_state is (s0, s1, s2, s3, s4);

   signal state, state_next : mmc1_state;

begin

   seq : process( clk, sRst )
   begin
      if (clk'event and clk = '1') then
         if (sRst = '0') then
            state <= s0;
         else
            state <= state_next;
         end if;
      end if;
   
   end process;
   
   comb : process( state )
   begin
      reg_e <= '0';
      case state is
         when s0 =>
            state_next <= s1;
         when s1 =>
            state_next <= s2;
         when s2 =>
            state_next <= s3;
         when s3 =>
            state_next <= s4;
         when s4 =>
            reg_e <= '1';
            state_next <= s0;
         when others =>
            state_next <= state;
      end case;
   end process;

end arch;

