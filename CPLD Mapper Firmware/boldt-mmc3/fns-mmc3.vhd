library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FNS_MMC3 is
port
	(
		-- Inputs from Famicom Network System:
		m2           : in std_logic;
		m2_delayed   : in std_logic;
		cpu_RW       : in std_logic;
		cpu_A0       : in std_logic;
		cpu_A13      : in std_logic;
		cpu_A14      : in std_logic;
		romsel_N     : in std_logic;
		
		cpu_data_bus : in std_logic_vector(7 downto 0);
		
		-- Outputs to PRG ROM and RAM:
		prg_ram_CS_N    : out std_logic;
		prg_ram_OE_N    : out std_logic;
		prg_ram_address : out std_logic_vector(14 downto 13);
		
		prg_rom_OE_N    : out std_logic;
		prg_rom_WE_N    : out std_logic;
		prg_rom_address : out std_logic_vector(18 downto 14)
	);
end FNS_MMC3;

architecture logic of FNS_MMC3 is

	signal reg_select            : std_logic_vector(2 downto 0) := "111";
	signal bank_mode             : std_logic                    := '1';
	signal R6                    : std_logic_vector(4 downto 0) := "11111";
	signal R7                    : std_logic_vector(4 downto 0) := "11111";
	signal prg_ram_write_protect : std_logic                    := '1';
	
begin

	process( m2, cpu_RW, cpu_A0, cpu_A13, cpu_A14, romsel_N, cpu_data_bus )
	
	variable fc_address : std_logic_vector(4 downto 0);
	
	begin
		fc_address := cpu_RW & romsel_N & cpu_A14 & cpu_A13 & cpu_A0;
		
		
		-- Active PRG Bank Decoding (not clocked):
		
		-- CPU is accessing $8000-9FFF (or $0000-1FFF):
		if( cpu_A14 = '0' AND cpu_a13 = '0' ) then
			if( bank_mode = '0' ) then  -- In PRG bank mode 0, use R6.
				prg_rom_address <= R6;
			else  -- In PRG bank mode 1, use the next-to-last fixed bank.
				prg_rom_address <= "11110";
			end if;
		-- CPU is accessing $A000-BFFF (or $2000-3FFF):
		elsif( cpu_A14 = '0' AND cpu_a13 = '1' ) then
			prg_rom_address <= R7;  -- Both bank modes use R7 for this region.
		-- CPU is accessing $C000-DFFF (or $4000-5FFF):
		elsif( cpu_A14 = '1' AND cpu_a13 = '0' ) then
			if( bank_mode = '0' ) then  -- In PRG bank mode 0, use the next-to-last fixed bank.
				prg_rom_address <= "11110";
			else  -- In PRG bank mode 1, use R6.
				prg_rom_address <= R6;
			end if;
		-- CPU is accessing $E000-FFFF (or $6000-7FFF):
		else
			prg_rom_address <= "11111";  -- Both bank modes use the last bank for this region.
		end if;
		
		
		-- Active PRG-RAM Control Signal Decoding:
		-- If the CPU is reading or writing in the range $6000-7FFF:
		if(	m2 = '1' AND
				m2_delayed = '1' AND  -- AND'ing M2 with delayed M2 delays only the rising edge of the resulting M2.
				romsel_n = '1' AND
				cpu_A14 = '1' AND
				cpu_A13 = '1' ) then
				
			if( cpu_RW = '0' AND prg_ram_write_protect = '1' ) then  -- CPU is attempting to write when write protection is active.
				prg_ram_OE_N <= '1';  -- Disable /OE.  Don't allow the write.
			else
				prg_ram_OE_N <= '0';  -- Enable /OE.  Allow all reads, and allow writes when write protection is not active.
			end if;
		else  -- CPU is outside the range $6000-7FFF.
			prg_ram_OE_N <= '1';  -- Disable /OE.
		end if;
		
		prg_ram_CS_N <= NOT(cpu_RW);
		
		
		-- Manage register writes on the falling edge of M2:
		
		if( falling_edge(m2) ) then  -- Writes are accepted from the 6502 at the falling edge of M2.
			case fc_address is
			
				-- CPU wrote to $8000 (MMC3 Bank Select Register):
				when "00000" =>
					reg_select <= cpu_data_bus(2 downto 0);
					bank_mode <= cpu_data_bus(6);
				
				-- CPU wrote to $8001 (MMC3 Bank Data Register):
				when "00001" =>
					if( reg_select = "110" ) then
						R6 <= cpu_data_bus(4 downto 0);
					elsif( reg_select = "111" ) then
						R7 <= cpu_data_bus(4 downto 0);
					-- else ignore writes to CHR registers R0..R5.
					end if;
				
				-- CPU wrote to $A001 (MMC3 PRG-RAM Register):
				when "00010" =>
					prg_ram_address <= cpu_data_bus(1 downto 0);
					prg_ram_write_protect <= cpu_data_bus(6);
				-- CPU wrote some place else.
				when others =>
					null;  -- No effect.
			end case;
		end if;
		
	end process;
	
end logic;
		
		
		
		
		