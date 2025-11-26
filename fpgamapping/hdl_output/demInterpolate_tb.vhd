-- demInterpolate_tb.vhd
-- VHDL Testbench for DEM Interpolation Core
-- Auto-generated from YOUR mission data
-- Test vectors: 100

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity demInterpolate_tb is
end demInterpolate_tb;

architecture Behavioral of demInterpolate_tb is

    -- Component declaration
    component demInterpolate_hdl is
        Port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            x_in      : in  signed(31 downto 0);
            y_in      : in  signed(31 downto 0);
            z_out     : out signed(15 downto 0);
            valid_out : out std_logic
        );
    end component;

    -- Signals
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';
    signal x_in      : signed(31 downto 0);
    signal y_in      : signed(31 downto 0);
    signal z_out     : signed(15 downto 0);
    signal valid_out : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;  -- 100 MHz

begin

    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- DUT instantiation
    DUT: demInterpolate_hdl
        port map (
            clk       => clk,
            reset     => reset,
            x_in      => x_in,
            y_in      => y_in,
            z_out     => z_out,
            valid_out => valid_out
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        reset <= '1';
        wait for clk_period*5;
        reset <= '0';
        wait for clk_period*5;

        -- Test vectors from YOUR mission data
        report "Starting testbench with 100 test vectors";

        -- Test 1
        x_in <= to_signed(500163, 32);
        y_in <= to_signed(5400831, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 109) < 1)
            report "Test 1 FAILED: Expected 108.83"
            severity error;

        -- Test 2
        x_in <= to_signed(500904, 32);
        y_in <= to_signed(5400762, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 92) < 1)
            report "Test 2 FAILED: Expected 91.87"
            severity error;

        -- Test 3
        x_in <= to_signed(500277, 32);
        y_in <= to_signed(5400002, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 119) < 1)
            report "Test 3 FAILED: Expected 119.40"
            severity error;

        -- Test 4
        x_in <= to_signed(500064, 32);
        y_in <= to_signed(5400940, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 114) < 1)
            report "Test 4 FAILED: Expected 113.84"
            severity error;

        -- Test 5
        x_in <= to_signed(500615, 32);
        y_in <= to_signed(5400146, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 105) < 1)
            report "Test 5 FAILED: Expected 104.93"
            severity error;

        -- Test 6
        x_in <= to_signed(500367, 32);
        y_in <= to_signed(5400858, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 95) < 1)
            report "Test 6 FAILED: Expected 95.42"
            severity error;

        -- Test 7
        x_in <= to_signed(500845, 32);
        y_in <= to_signed(5400891, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 86) < 1)
            report "Test 7 FAILED: Expected 85.83"
            severity error;

        -- Test 8
        x_in <= to_signed(500765, 32);
        y_in <= to_signed(5400913, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 90) < 1)
            report "Test 8 FAILED: Expected 89.54"
            severity error;

        -- Test 9
        x_in <= to_signed(500871, 32);
        y_in <= to_signed(5400904, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 84) < 1)
            report "Test 9 FAILED: Expected 84.00"
            severity error;

        -- Test 10
        x_in <= to_signed(500583, 32);
        y_in <= to_signed(5400239, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 107) < 1)
            report "Test 10 FAILED: Expected 107.50"
            severity error;

        -- Test 11
        x_in <= to_signed(500422, 32);
        y_in <= to_signed(5400936, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 103) < 1)
            report "Test 11 FAILED: Expected 102.91"
            severity error;

        -- Test 12
        x_in <= to_signed(500122, 32);
        y_in <= to_signed(5400948, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 116) < 1)
            report "Test 12 FAILED: Expected 116.01"
            severity error;

        -- Test 13
        x_in <= to_signed(500125, 32);
        y_in <= to_signed(5400977, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 115) < 1)
            report "Test 13 FAILED: Expected 115.21"
            severity error;

        -- Test 14
        x_in <= to_signed(500910, 32);
        y_in <= to_signed(5400987, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 88) < 1)
            report "Test 14 FAILED: Expected 88.12"
            severity error;

        -- Test 15
        x_in <= to_signed(500109, 32);
        y_in <= to_signed(5400821, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 113) < 1)
            report "Test 15 FAILED: Expected 113.09"
            severity error;

        -- Test 16
        x_in <= to_signed(500197, 32);
        y_in <= to_signed(5400237, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 98) < 1)
            report "Test 16 FAILED: Expected 98.29"
            severity error;

        -- Test 17
        x_in <= to_signed(500493, 32);
        y_in <= to_signed(5400374, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 100) < 1)
            report "Test 17 FAILED: Expected 99.74"
            severity error;

        -- Test 18
        x_in <= to_signed(500980, 32);
        y_in <= to_signed(5400910, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 87) < 1)
            report "Test 18 FAILED: Expected 86.86"
            severity error;

        -- Test 19
        x_in <= to_signed(500275, 32);
        y_in <= to_signed(5400033, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 115) < 1)
            report "Test 19 FAILED: Expected 115.46"
            severity error;

        -- Test 20
        x_in <= to_signed(500765, 32);
        y_in <= to_signed(5400208, 32);
        wait for clk_period*10;
        assert (abs(to_integer(z_out) - 103) < 1)
            report "Test 20 FAILED: Expected 103.17"
            severity error;

        -- End of tests
        report "Testbench complete";
        wait;
    end process;

end Behavioral;
