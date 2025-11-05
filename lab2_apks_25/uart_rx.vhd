----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:45:52 11/02/2025 
-- Design Name: 
-- Module Name:    uart_rx - Behavioral 
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

entity uart_rx is
	generic (
		CLK_FREQ  : natural := 50_000_000;
		BAUD_RATE : natural := 9600
	);
	port (
		i_clk      : in  std_logic;
		i_reset    : in  std_logic;
		i_rx_pin   : in  std_logic;
	   o_data     : out  std_logic_vector(7 downto 0);
		o_data_ready    : out std_logic := '0'
	);
end entity uart_rx;

architecture Behavioral of uart_rx is
	type T_FSM_STATE is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
	signal r_fsm_state : T_FSM_STATE := IDLE;
	
	component baud_rate_generator is
		generic (
			CLK_FREQ  : natural;
			BAUD_RATE : natural
		);
		port (
			i_clk   : in std_logic;
			i_reset : in std_logic;
			o_tick  : out std_logic
		);
	end component baud_rate_generator;
	
	signal w_tick_16x : std_logic;
	
	signal r_sample_count : natural range 0 to 15 := 0;
	signal r_bit_count    : natural range 0 to 7 := 0;
	
	signal r_data_reg : std_logic_vector(7 downto 0) := (others => '0');
	signal r_rx_sync  : std_logic_vector(2 downto 0) := (others => '1');

begin
	U_BaudGen: baud_rate_generator
		generic map (
			CLK_FREQ  => CLK_FREQ,
			BAUD_RATE => BAUD_RATE
		)
		port map (
			i_clk   => i_clk,
			i_reset => i_reset,
			o_tick  => w_tick_16x
		);
		
	process(i_clk, i_reset)
	begin
		if (i_reset = '1') then
			r_rx_sync <= (others => '1');
		elsif (rising_edge(i_clk)) then
			r_rx_sync <= r_rx_sync(1 downto 0) & i_rx_pin;
		end if;
	end process;
	
	process(i_clk, i_reset)
		variable v_rx_pin : std_logic;
	begin
		if (i_reset = '1') then
			r_fsm_state    <= IDLE;
			r_sample_count <= 0;
			r_bit_count    <= 0;
			o_data_ready   <= '0';
		elsif (rising_edge(i_clk)) then
		
			v_rx_pin := r_rx_sync(1);
			if (r_rx_sync = "000") then v_rx_pin := '0';
			elsif (r_rx_sync = "111") then v_rx_pin := '1';
			end if;
			
			o_data_ready <= '0';
			
			case r_fsm_state is
				when IDLE =>
					r_sample_count <= 0;
					r_bit_count    <= 0;
					if (v_rx_pin = '0' and r_rx_sync(2) = '1') then
						r_fsm_state <= START_BIT;
					end if;
					
				when START_BIT => 
					if (w_tick_16x = '1') then
						if (r_sample_count = 7) then
							if (v_rx_pin = '0') then
								r_fsm_state    <= DATA_BITS;
								r_sample_count <= 0;
							else
								r_fsm_state <= IDLE;
							end if;
						else
							r_sample_count <= r_sample_count + 1;
						end if;
					end if;
				
				when DATA_BITS => 
					if (w_tick_16x = '1') then
						if (r_sample_count = 15) then
							r_sample_count <= 0;
							r_data_reg(r_bit_count) <= v_rx_pin;
							
							if (r_bit_count = 7) then
								r_fsm_state <= STOP_BIT;
							else
								r_bit_count <= r_bit_count + 1;
							end if;
						else
							r_sample_count <= r_sample_count + 1;
						end if;
					end if;
				
				when STOP_BIT => 
					if (w_tick_16x = '1') then
						if (r_sample_count = 15) then
							if (v_rx_pin = '1') then
								o_data       <= r_data_reg;
								o_data_ready <= '1';
							end if;
							
							r_fsm_state <= IDLE;
						else
							r_sample_count <= r_sample_count + 1;
						end if;
					end if;
					
			end case;
		end if;
	end process;

end architecture Behavioral;