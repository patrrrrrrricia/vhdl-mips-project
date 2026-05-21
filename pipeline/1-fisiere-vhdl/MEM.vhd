library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM is
     Port ( clk: in std_logic;
            en: in std_logic;
            ALURes_In: in std_logic_vector(31 downto 0);
            RD2: in std_logic_vector(31 downto 0);
            MemWrite: in std_logic;
            MemData: out std_logic_vector(31 downto 0);
            ALURes_Out: out std_logic_vector(31 downto 0)
            );
end MEM;

architecture Behavioral of MEM is
     -- definirea tipului ram: 64 de cuvinte a cate 32 de biti fiecare
     type ram_type is array (0 to 63) of std_logic_vector(31 downto 0);
     -- initializarea ram cu date specifice pentru problema 1 (numarare valori impare si pozitive)
     -- indexul 1 corespunde adresei 4, indexul 2 adresei 8, etc. (aliniere la 4 octeti)
     signal RAM : ram_type := (
        1 => x"00000003", -- adresa 4: N=3 (avem 3 elemente de verificat)
        2 => x"00000005", -- adresa 8: valoarea 5 (pozitiv, impar) -> numarata
        3 => x"fffffffe", -- adresa 12: valoarea -2 (negativ, par) -> ignorata
        4 => x"00000007", -- adresa 16: valoarea 7 (pozitiv, impar) -> numarata
        others => x"00000000"
     );
begin
    -- scrierea sincrona in ram
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' and MemWrite = '1' then
                -- indexarea se face pe bitii 7-2 pentru a respecta byte addressing
                RAM(to_integer(unsigned(ALURes_In(7 downto 2)))) <= RD2;
            end if;
        end if;
    end process;

    -- citirea din memoria ram este asincrona
    -- datele sunt disponibile imediat ce adresa (alures_in) se schimba
    MemData <= RAM(to_integer(unsigned(ALURes_In(7 downto 2))));
    
    -- trimiterea rezultatului alu catre etajul urmator pentru instructiuni non-load
    ALURes_Out <= ALURes_In;
    
end Behavioral;