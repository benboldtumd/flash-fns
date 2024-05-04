--NES MMC1 mapper implementation.
--Copyright 2013 David Senabre Albujer
--Free-open source implementation.
--
--Tested succesfully in on Xilinx XC9572 CPLD and SNROM PCB
--
--website:
--www.consolasparasiempre.net
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

--MMC1 Pinout:
--              .---\/---.
--PRG A14 (r) - |01    24| - +5V
--PRG A15 (r) - |02    23| - M2
--PRG A16 (r) - |03    22| - PRG A13 (s)
--PRG A17 (r) - |04    21| - PRG A14 (n)
--PRG /CE (r) - |05    20| - PRG /CE (n)
--WRAM CE (w) - |06    19| - PRG D7 (s)
--CHR A12 (r) - |07    18| - PRG D0 (s)
--CHR A13 (r) - |08    17| - PRG R/W
--CHR A14 (r) - |09    16| - CIRAM A10 (n)
--CHR A15 (r) - |10    15| - CHR A12 (n)
--CHR A16 (r) - |11    14| - CHR A11 (s)
--        GND - |12    13| - CHR A10 (s)
--              `--------'

-- Kid Icarus and Metroid are a SNROM cartirdge.
-- SNROM PCB uses most significant bit of chr_a_out to enable WRAM.

entity mmc1 is
    Port ( pgr_d     : in  STD_LOGIC_VECTOR (1 downto 0);
           pgr_ce_in : in  STD_LOGIC;                       -- also called /ROMSEL
           pgr_rw    : in  STD_LOGIC;
           m2        : in  STD_LOGIC;
           pgr_a_in  : in  STD_LOGIC_VECTOR (1 downto 0);
           chr_a_in  : in  STD_LOGIC_VECTOR (2 downto 0);
           ciram     : out  STD_LOGIC;
           pgr_a_out : out  STD_LOGIC_VECTOR (3 downto 0);
           chr_a_out : out  STD_LOGIC_VECTOR (4 downto 0);
           pgr_ce_out: out  STD_LOGIC;
           wram_ce   : out  STD_LOGIC
-- DEBUG SIGNALS
--           clk_dbg   : out  std_logic;
--           data_dbg  : out  STD_LOGIC_VECTOR(3 downto 0);
--           reg0_dbg  : out  STD_LOGIC_VECTOR(4 downto 0)
           );
end mmc1;

architecture arch of mmc1 is
  
   signal regs_e: STD_LOGIC;
   signal reg0_e: STD_LOGIC;
   signal reg1_e: STD_LOGIC;
   signal reg2_e: STD_LOGIC;
   signal reg3_e: STD_LOGIC;
   
   signal rClk :  STD_LOGIC;   
   signal shOut:  STD_LOGIC_VECTOR(3 downto 0);
   
   signal rPIn:   STD_LOGIC_VECTOR(4 downto 0);
   signal r0Out:  STD_LOGIC_VECTOR(4 downto 0);
   signal r1Out:  STD_LOGIC_VECTOR(4 downto 0);
   signal r2Out:  STD_LOGIC_VECTOR(4 downto 0);
   signal r3Out:  STD_LOGIC_VECTOR(4 downto 0);

   -- NOTE.
   -- register 0 ($8000-$9FFF) must start with bits set, rather tan reset, why?
   -- Because bit 2 must be set, for last ROM slot ($C000-$FFFF) to be fixed to
   -- last PGR ROM bank, required for games with interrupt vectors in the last
   -- bank to boot.
   -- The rest of register 0 bits can be initially set without harm.
   
   -- This behaviour is implemented by a generic INIT in std_reg.
   -- In Xilinx enviroment, you can also set the start-up state using attribute

   --attribute INIT : string;
   --attribute INIT of shOut : signal is "S";

   -- or use, in ucf file:
   
   -- INST r0 INIT=S;
      
begin

   -- control (state machine)
   fsm: entity work.fsm(arch)
      port map(   sRst=>"not"(pgr_d(1)),  -- bit D7 resets sequence
                  clk=>rClk,
                  reg_e=>regs_e );
                     -- shift register
   sh0 : entity work.shift_reg(arch)
      generic map( 4 )
      port map(   sIn=>pgr_d(0), 
                  clk=>rClk, 
                  rst=>"not"( pgr_d(1) ), 
                  pOut=>shOut);
   -- control reg
   r0 : entity work.std_reg(arch)
      generic map( 5, '1' )
      port map(   pIn=>rPIn,
                  clk=>rClk, 
                  en=>reg0_e,
                  rst=>'1', 
                  pOut=>r0Out);
   -- chr rom 1
   r1 : entity work.std_reg(arch)
      generic map( 5 )
      port map(   pIn=>rPIn,
                  clk=>rClk, 
                  en=>reg1_e,
                  rst=>'1', 
                  pOut=>r1Out);
   -- chr rom 2
   r2 : entity work.std_reg(arch)
      generic map( 5 )
      port map(   pIn=>rPIn,
                  clk=>rClk, 
                  en=>reg2_e,
                  rst=>'1', 
                  pOut=>r2Out);   
   -- pgr rom
   r3 : entity work.std_reg(arch)
      generic map( 5 )
      port map(   pIn=>rPIn,
                  clk=>rClk, 
                  en=>reg3_e,
                  rst=>'1', 
                  pOut=>r3Out);

   -- registers input
   rPIn <= pgr_d(0) & shOut;
   
   -- internal clock
   -- when writing, ROMSEL asserted and M2 is high (bus is stable)
   rClk <=  '1' when (m2='0' and pgr_ce_in='0' and pgr_rw='0') else
            '0';
   -- Be careful: the following does NOT work, unless m2 is internally delayed
   -- by at least 100ns. Althoug this can be easily be accomplished, this is a
   -- device-dependent solution, and not an elegant approach.
   --rClk <=  '1' when (m2='1' and pgr_ce_in='0' and pgr_rw='0') else
   --         '0';
   
   -- mmc1 register address decoding
   reg0_e <= '0' when (pgr_a_in = "00" and regs_e = '1' ) else
             '1';     
   reg1_e <= '0' when (pgr_a_in = "01" and regs_e = '1' ) else
             '1';     
   reg2_e <= '0' when (pgr_a_in = "10" and regs_e = '1' ) else
             '1';     
   reg3_e <= '0' when (pgr_a_in = "11" and regs_e = '1' ) else
             '1';     

   -- PGR ROM bank selection
   -- only 16 kb bank size is implemented
   -- NOTE:
   -- if reg 0: bit 2 = 0, $C000 is swappable. 
   -- if A14 = 1, address is inside $C000 bank, so, mapper provides selection
   pgr_a_out <= r3Out(3 downto 0)   when (r0Out(2) /= pgr_a_in(1)) else -- mapper provides bank selection
                "0000"              when (pgr_a_in(1) = '0') else       -- access first slot (when fixed) 0x8000
                "1111";             --when (pgr_a_in(1) = '1')          -- access second slot (when fixed) 0xC000
                
   -- CHR ROM bank selection
   -- NOTE:
   -- reg 0 bit 4 = 1, selects 4kb banks
   -- chr_a_in(2) is PPU A12. Selects 4kb bank.
   -- in 8kb mode, last bit of reg 2 is ignored, and replaced with current PPU A12.
   chr_a_out <= r1Out   when (r0Out(4) = '1' and chr_a_in(2)='0') else  -- first 4Kb
                r2Out   when (r0Out(4) = '1' and chr_a_in(2)='1') else  -- second 4Kb
                r1Out(4 downto 1) & chr_a_in(2);                        -- 8Kb slot
                
   -- mirroring
   -- NOTE:
   -- in vertical mirroring, PPU A10 is connected to CIRAM A10 (internal VRAM A10).
   ciram <= chr_a_in(0) when r0Out(1 downto 0) = "10" else  -- vertical mirroring
            chr_a_in(1) when r0Out(1 downto 0) = "11" else  -- horizontal mirroring
            '0'         when r0Out(1 downto 0) = "00" else  -- no mirroring, nametable 0
            '1';--      when r0Out(1 downto 0) = "01" else  -- no mirroring, nametable 1
                
   -- pgr /ce logic
   pgr_ce_out <= pgr_ce_in when pgr_rw = '1' else
                 '1';
   
   -- wram /ce logic
   -- NOTE:
   -- pgr_ce_in (/ROMSEL) is asserted when inside $8000-$FFFF, so it must be 1 below $8000
   wram_ce <=  '0' when (r3Out(4) = '1') else                        -- WRAM disabled?
               '1' when (m2 = '1' and pgr_ce_in = '1' and pgr_a_in = "11") else   -- enable WRAM 0x6000-0x7FFF (a13-14 = "11")
               '0';
   -- always enabled WRAM MMC1 version
--   wram_ce <=  '1' when (m2 = '1' and pgr_ce_in = '1' and pgr_a_in = "11") else   -- enable WRAM 0x6000-0x7FFF (a13-14 = "11")
--               '0';


   -- DEBUG SIGNALS
   --clk_dbg <= rClk;   
   --data_dbg <= shOut;
   --reg0_dbg <= r3Out;

end arch;

