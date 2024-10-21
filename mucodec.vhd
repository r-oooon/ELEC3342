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
        12 => "00000010", 13 => "00000100", 14 => "00001000", 15 => "00001100", 16 => "00010000",
        21 => "00000001", 23 => "00000111", 24 => "00001011", 25 => "00010001", 26 => "00010110",
        31 => "00000011", 32 => "00000101", 34 => "00001111", 35 => "00010101", 36 => "00011010",
        41 => "00000101", 42 => "00001010", 43 => "00001111", 45 => "00011001", 46 => "00011100",
        51 => "00001001", 52 => "00010010", 53 => "00010100", 54 => "00011000", 56 => "00011101",
        61 => "00001101", 62 => "00010011", 63 => "00011111", 64 => "00100000", 65 => "00100001");

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