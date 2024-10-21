library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity decoder is
    Port ( clk : in  STD_LOGIC;
           clr : in  STD_LOGIC;
           din : in  STD_LOGIC_VECTOR (2 downto 0);
           valid : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
           dvalid : out  STD_LOGIC;
           error : out  STD_LOGIC);
end decoder;

architecture Behavioral of decoder is

    type STATE_TYPE is (IDLE, MONITOR, DECODE, ERROR);
    signal state, next_state : STATE_TYPE;

    signal data_stream : STD_LOGIC_VECTOR(15 downto 0);
    signal data_index : integer := 0;

    signal lookup_table : array(11 to 66) of STD_LOGIC_VECTOR(7 downto 0) := (
        12 => "01000010", 13 => "01000100", 14 => "01001000", 15 => "01001100", 16 => "01010000",
        21 => "01000001", 23 => "01000111", 24 => "01001011", 25 => "01010001", 26 => "01010110",
        31 => "01000011", 32 => "01000101", 34 => "01001111", 35 => "01010101", 36 => "01011010",
        41 => "01000101", 42 => "01001010", 43 => "01001111", 45 => "01011001", 46 => "00101110",
        51 => "01001001", 52 => "01010010", 53 => "01010100", 54 => "01011000", 56 => "00111111",
        61 => "01001101", 62 => "01010011", 63 => "01011111", 64 => "01100000", 65 => "01000000");

begin

    process(clk, clr)
    begin
        if clr = '1' then
            state <= IDLE;
            data_index <= 0;
            error <= '0';
            dvalid <= '0';
        elsif rising_edge(clk) then
            state <= next_state;
            if state = DECODE then
                data_index <= data_index + 1;
            else
                data_index <= 0;
            end if;
        end if;
    end process;

    process(state, din, valid, data_index)
    begin
        next_state <= state;
        dout <= "00000000";
        dvalid <= '0';
        error <= '0';

        case state is
            when IDLE =>
                if valid = '1' then
                    data_stream(data_index*3+2 downto data_index*3) <= din;
                    if data_index = 4 then
                        if data_stream = "0000011100000111" then
                            next_state <= DECODE;
                        else
                            next_state <= IDLE;
                        end if;
                    end if;
                end if;

            when DECODE =>
                if valid = '1' then
                    data_stream(data_index*3+2 downto data_index*3) <= din;
                    if data_index = 4 then
                        if data_stream = "0111000001110000" then
                            next_state <= IDLE;
                        elsif lookup_table(to_integer(unsigned(data_stream))) = "00000000" then
                            error <= '1';
                            next_state <= ERROR;
                        else
                            dout <= lookup_table(to_integer(unsigned(data_stream)));
                            dvalid <= '1';
                        end if;
                    end if;
                end if;

            when ERROR =>
                error <= '1';
                if valid = '1' and din = "00000111" then
                    next_state <= MONITOR;
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

end Behavioral;
