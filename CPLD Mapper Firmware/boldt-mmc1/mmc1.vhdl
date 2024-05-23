library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MMC1 is
port
	(
		-- Inputs from Famicom Network System:
		m2        : in std_logic;
		m2_100ns  : in std_logic;
		cpu_rw    : in std_logic;
		romsel_N  : in std_logic;
		cpu_A14   : in std_logic;
		cpu_A13   : in std_logic;		
		cpu_D7    : in std_logic;
		cpu_D0    : in std_logic;
		
		-- Outputs to PRG ROM and RAM:
		prg_ram_CS_N_shaped : out std_logic;
		prg_ram_OE_N        : out std_logic;
		prg_ram_address     : out std_logic_vector(14 downto 13);
		
		prg_rom_OE_N        : out std_logic;
		prg_rom_address     : out std_logic_vector(18 downto 14)
	);
end MMC1;

architecture logic of MMC1 is

	signal control_reg    : std_logic_vector(4 downto 0);  -- $8000-9FFF
	signal chr_bank_0_reg : std_logic_vector(4 downto 0);  -- $A000-BFFF
	signal chr_bank_1_reg : std_logic_vector(4 downto 0);  -- $C000-DFFF
	signal prg_bank_reg   : std_logic_vector(4 downto 0);  -- $E000-FFFF
	
	signal reg_shift         : std_logic_vector(3 downto 0);
	signal reg_bit_counter   : std_logic_vector(1 downto 0);
	signal reg_bit_commit    : std_logic;
	signal previous_read     : std_logic;

begin

	-- Handle PRG banking as concurrent/combinational logic:
	prg_rom_address <= ( 18 => '1',
								17 => prg_bank_reg(3),
								16 => prg_bank_reg(2),
								15 => prg_bank_reg(1),
								14 => cpu_A14,
								others => '1') 
									when ( control_reg(3) = '0' ) else  -- 32kByte Bank mode.
							 ( 18 => '1',
								17 => '0',
								16 => '0',
								15 => '0',
								14 => '0',
								others => '1')
									when ( control_reg(2) = '0' AND cpu_A14 = '0' ) else  -- 16kByte Bank mode, fix first bank at $8000-BFFF: CPU is accessing $8000-BFFF.
							 ( 18 => '1',
								17 => prg_bank_reg(3),
								16 => prg_bank_reg(2),
								15 => prg_bank_reg(1),
								14 => prg_bank_reg(0),
								others => '1')
									when ( control_reg(2) = '0' AND cpu_A14 = '1' ) else  -- 16kByte Bank mode, fix first bank at $8000-BFFF: CPU is accessing $C000-FFFF.
							 ( 18 => '1',
								17 => prg_bank_reg(3),
								16 => prg_bank_reg(2),
								15 => prg_bank_reg(1),
								14 => prg_bank_reg(0),
								others => '0')
									when ( control_reg(2) = '1' AND cpu_A14 = '0' ) else  -- 16kByte Bank mode, fix last bank at $C000-FFFF.: CPU is accessing $8000-BFFF.
							 ( 18 => '1',
								17 => '1',
								16 => '1',
								15 => '1',
								14 => '1',
								others => '1');  -- 16kByte Bank mode, fix last bank at $C000-FFFF.: CPU is accessing $C000-FFFF. 

	--  Handle PRG-ROM /OE:
	prg_rom_OE_N <= romsel_N when (cpu_rw = '1') else  -- Preventing bus conflict.
                   '1';
			
	-- Handle RAM /CS:
	prg_ram_CS_N_shaped <= '1' when (prg_bank_reg(4) = '1') else  -- WRAM is disabled.
			                 '0' when (m2 = '1' and m2_100ns = '1' and romsel_N = '1' and cpu_A14 = '1' and cpu_A13 = '1') else  -- CPU is accessing memory range 0x6000-0x7FFF (a13-14 = "11")
			                 '1';

	-- Handle CHR-RAM /OE pin:
	prg_ram_OE_N <= chr_bank_0_reg(4);
	
	-- Handle CHR-RAM Address Pins:
	prg_ram_address <= chr_bank_0_reg(3 downto 2);
	
		
	process( m2, cpu_rw, romsel_N, cpu_D7, cpu_D0 )
	begin
		if( falling_edge(m2) ) then
			if( cpu_rw = '1' ) then  -- Read cycle
				previous_read <= '1';
			else  -- write cycle
				
				if( previous_read = '1' AND romsel_N = '0' ) then
					previous_read <= '0';

					-- Handle the MMC1 register write:
					
					if( cpu_D7 = '1' ) then  -- Reset detected by CPU D7 = 1.
						reg_bit_counter <= "00";
						reg_bit_commit <= '0';
						control_reg(3 downto 2) <= "11";
						
					-- The last bit is being received:
					elsif( reg_bit_commit = '1' ) then
						reg_bit_counter <= "00";
						reg_bit_commit <= '0';
						
						if( cpu_A14 = '0' AND cpu_A13 = '0' ) then  -- $8000-9FFF
							control_reg <= cpu_D0 & reg_shift;
						elsif( cpu_A14 = '0' AND cpu_A13 = '1' ) then  -- $A000-BFFF
							chr_bank_0_reg <= cpu_D0 & reg_shift;
						elsif( cpu_A14 = '1' AND cpu_A13 = '0' ) then  -- $C000-DFFF
							chr_bank_1_reg <= cpu_D0 & reg_shift;
						elsif( cpu_A14 = '1' AND cpu_A13 = '1' ) then  -- $E000-FFFF
							prg_bank_reg <= cpu_D0 & reg_shift;
						end if;
						
					-- Accumulating Bits:
					elsif( reg_bit_counter = "00" ) then
						reg_shift(0) <= cpu_D0;
						reg_bit_counter <= "01";
					elsif( reg_bit_counter = "01" ) then
						reg_shift(1) <= cpu_D0;
						reg_bit_counter <= "10";
					elsif( reg_bit_counter = "10" ) then
						reg_shift(2) <= cpu_D0;
						reg_bit_counter <= "11";
					elsif( reg_bit_counter = "11" ) then
						reg_shift(3) <= cpu_D0;
						reg_bit_commit <= '1';
					end if;
					
				end if;
								
			end if;
		end if;
		
	end process;
	
end logic;
			
			
			
			
			
			
			
			
			
			
			