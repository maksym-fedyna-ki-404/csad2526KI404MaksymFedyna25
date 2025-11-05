----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    06:48:51 10/23/2025 
-- Design Name: 
-- Module Name:    uart_tx - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_tx is
	generic (
		CLK_FREQ  : natural := 50_000_000;
		BAUD_RATE : natural := 9600
	);
	port (
		i_clk      : in  std_logic;
		i_reset    : in  std_logic;
		i_start_tx : in  std_logic;
		i_data     : in  std_logic_vector(7 downto 0);
		o_tx_pin   : out  std_logic := '1';
		o_busy     : out std_logic := '0'
	);
end entity uart_tx;

architecture Behavioral of uart_tx is
	constant C_BAUD_DIV : natural := (CLK_FREQ / BAUD_RATE) - 1;
	signal r_baud_counter : natural range 0 to C_BAUD_DIV := 0;
	signal r_baud_tick    : std_logic := '0';
	
	type T_FSM_STATE is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
	signal r_fsm_state : T_FSM_STATE := IDLE;
	
	signal r_data_reg  : std_logic_vector(7 downto 0) := (others => '0');
	signal r_bit_count : natural range 0 to 7 := 0;
begin
	
	process(i_clk, i_reset)
	begin
		if (i_reset = '1') then
			r_baud_counter <= 0;
			r_baud_tick    <= '0';
		elsif (rising_edge(i_clk)) then
			r_baud_tick <= '0';
			if (r_baud_counter = C_BAUD_DIV) then
				r_baud_counter <= 0;
				r_baud_tick    <= '1';
			elsif (r_fsm_state /= IDLE) then
				r_baud_counter <= r_baud_counter + 1;
			else
				r_baud_counter <= 0;
			end if;
		end if;
	end process;
	
	process(i_clk, i_reset)
	begin
		if (i_reset = '1') then
			r_fsm_state <= IDLE;
			o_tx_pin    <= '1';
			o_busy      <= '0';
			r_bit_count <= 0;
		elsif (rising_edge(i_clk)) then
		
			case r_fsm_state is
				when IDLE => 
					o_tx_pin <= '1';
					o_busy   <= '0';
					r_bit_count <= 0;
					
					if (i_start_tx = '1') then
						r_data_reg  <= i_data;
						r_fsm_state <= START_BIT;
						o_busy      <= '1';
					end if;
					
				when START_BIT => 
					o_tx_pin <= r_data_reg(r_bit_count);
					if (r_baud_tick = '1') then
						if (r_bit_count = 7) then
							r_bit_count <= 0;
							r_fsm_state <= STOP_BIT;
						else
							r_bit_count <= r_bit_count + 1;
						end if;
					end if;
					
				when STOP_BIT => 
					o_tx_pin <= '1';
					if (r_baud_tick = '1') then
						r_fsm_state <= IDLE;
						o_busy      <= '0';
					end if;
					
				end case;
			end if;
		end process;
	
end architecture Behavioral;

