LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity mucodec is
    port (
        din     : IN std_logic_vector(2 downto 0);
        valid   : IN std_logic;
        clr     : IN std_logic;
        clk     : IN std_logic;
        dout    : OUT std_logic_vector(7 downto 0);
        dvalid  : OUT std_logic;
        error   : OUT std_logic);
end mucodec;

architecture Behavioral of mucodec is

    -- State enumeration
    type state_type is (St_RESET, St_ERROR, St_START, St_STOP);
    signal state, next_state : state_type := St_RESET;

    -- Internal signals
    signal char         : std_logic_vector(7 downto 0) := (others => '0');
    signal d_past       : std_logic_vector(2 downto 0) := (others => '0');
    signal number       : std_logic_vector(5 downto 0) := (others => '0');
    signal position     : integer := 0;
    signal start_counter: integer := 0;
    signal first_char   : integer := 0;
    signal second_char  : integer := 0;
    signal letter       : std_logic_vector(7 downto 0) := (others => '0');
    signal STOP_COUNTER : integer := 0;
    signal valid_counter: std_logic;
    signal dtest :std_logic;

begin

    -- Synchronous process for state transitions
    sync_process: process (clk, clr)
    begin
        if clr = '1' then
            state <= St_RESET;
            dvalid <= '0';
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- State logic to control transitions and operations
    state_logic: process (state, din, valid)
    begin
        -- Default state to remain unchanged
        next_state <= state;
        d_past <= din;
        case state is
            when St_RESET =>
                if valid = '1'  then
                    if start_counter = 1 then
                    if position = 0 then
                        number(2 downto 0) <= din(2 downto 0);
                        position <= 1;
                    elsif position = 1 then
                        number(5 downto 3) <= din(2 downto 0);
                        position <= 0;
                        if number = "000111" then  -- START pattern
                            if first_char = 1 then
                                second_char <= 1;
                                position <= 0;
                                number <= (others => '0');
                                next_state <= St_START;
                            else
                                first_char <= 1;
                                number <= (others => '0');
                                next_state <= St_RESET;
                            end if;
                        end if;
                    end if;
                    else
                start_counter <= 1;
                end if;
                end if;

            when St_START =>
                if valid = '1' then
                    if position = 1 then
                        number(2 downto 0) <= din;
                        position <= 0;
                        valid_counter <= '0';
                    elsif position = 0 then
                        number(5 downto 3) <= din;
                        position <= 1;
                        valid_counter <= '1';
                        
                        case number is
                            when "001010" => letter <= "01000001"; -- A
                            when "001011" => letter <= "01000010"; -- B
                            when "001100" => letter <= "01000011"; -- C
                            when "001101" => letter <= "01000100"; -- D
                            when "001110" => letter <= "01000101"; -- E
                            when "010001" => letter <= "01000110"; -- F
                            when "010011" => letter <= "01000111"; -- G
                            when "010100" => letter <= "01001000"; -- H
                            when "010101" => letter <= "01001001"; -- I
                            when "010110" => letter <= "01001010"; -- J
                            when "011001" => letter <= "01001011"; -- K
                            when "011010" => letter <= "01001100"; -- L
                            when "011100" => letter <= "01001101"; -- M
                            when "011101" => letter <= "01001110"; -- N
                            when "011110" => letter <= "01001111"; -- O
                            when "100001" => letter <= "01010000"; -- P
                            when "100010" => letter <= "01010001"; -- Q
                            when "100011" => letter <= "01010010"; -- R
                            when "100101" => letter <= "01010011"; -- S
                            when "100110" => letter <= "01010100"; -- T
                            when "101001" => letter <= "01010101"; -- U
                            when "101010" => letter <= "01010110"; -- V
                            when "101011" => letter <= "01010111"; -- W
                            when "101100" => letter <= "01011000"; -- X
                            when "101110" => letter <= "01011001"; -- Y
                            when "110001" => letter <= "01011010"; -- Z
                            when "110010" => letter <= "00100001"; -- !
                            when "110011" => letter <= "00101110"; -- .
                            when "110100" => letter <= "00111111"; -- ?
                            when "110101" => letter <= "00100000"; -- SPACE
                            when "111000" =>
                                if STOP_COUNTER = 1 then
                                    next_state <= St_STOP;
                                else
                                    STOP_COUNTER <= STOP_COUNTER + 1;
                                    next_state <= St_START;
                                end if;
                            when others =>
                                next_state <= St_ERROR;
                        end case;
                        next_state <= ST_START;

                    end if;
                end if;

            when St_STOP =>
                -- Reset all variables
                number      <= (others => '0');
                position    <= 0;
                first_char  <= 0;
                second_char <= 0;
                letter      <= (others => '0');
                STOP_COUNTER <= 0;
                next_state  <= St_RESET;

            when St_ERROR =>
                -- Reset on error
                number      <= (others => '0');
                position    <= 0;
                first_char  <= 0;
                second_char <= 0;
                letter      <= (others => '0');
                next_state  <= St_RESET;

            when others =>
                next_state <= St_ERROR;
        end case;
    end process;

    -- Output logic 
    output_logic: process (state, letter, valid_counter)
    begin
        case state is
            when St_ERROR =>
                error <= '1';
            when ST_START =>
                dout   <= letter'event;
                error  <= '0';
            when others =>
                dout   <= (others => '0');
                dvalid <= '0';
                error  <= '0';
        end case;
    end process;

end Behavioral;
