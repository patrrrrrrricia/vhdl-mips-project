library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- definitia entitatii pentru unitatea de decodificare
entity ID is
    port ( clk, en : in std_logic; -- semnale de ceas si validare (buton)
           instr : in std_logic_vector(25 downto 0); -- restul instructiunii fara opcode
           wd : in std_logic_vector(31 downto 0); -- datele care trebuie scrise in registru
           regwrite, regdst, extop : in std_logic; -- semnale de control de la uc
           rd1, rd2, ext_imm : out std_logic_vector(31 downto 0); -- iesiri de date si offset extins
           func : out std_logic_vector(5 downto 0); -- campul function pentru alu control
           sa : out std_logic_vector(4 downto 0)); -- shift amount pentru deplasari
end ID;

architecture behavioral of ID is
    -- definirea tipului pentru bancul de registre (32 registre a cate 32 biti)
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    -- initializarea tuturor registrelor cu valoarea zero
    signal reg_file : reg_array := (others => x"00000000");
    -- semnal intern pentru adresa registrului de destinatie
    signal write_addr : std_logic_vector(4 downto 0);
begin
    -- multiplexor pentru alegerea adresei de scriere: rd (bits 15-11) sau rt (bits 20-16)
    write_addr <= instr(15 downto 11) when regdst = '1' else instr(20 downto 16);

    -- proces pentru scrierea in registre pe frontul crescator de ceas
    process(clk)
    begin
        if rising_edge(clk) then
            -- scrierea are loc doar daca enable si regwrite sunt active
            if en = '1' and regwrite = '1' then
                reg_file(to_integer(unsigned(write_addr))) <= wd;
            end if;
        end if;
    end process;

    -- citirea registrelor este asincrona (combinationala)
    -- rd1 primeste valoarea din registrul sursa rs (bits 25-21)
    rd1 <= reg_file(to_integer(unsigned(instr(25 downto 21))));
    -- rd2 primeste valoarea din registrul sursa rt (bits 20-16)
    rd2 <= reg_file(to_integer(unsigned(instr(20 downto 16))));

    -- unitatea de extindere a constantei de 16 biti la 32 biti
    ext_imm(15 downto 0) <= instr(15 downto 0); -- primii 16 biti raman identici
    -- daca extop e 1, se face extindere cu semn (bit 15), altfel se completeaza cu zero
    ext_imm(31 downto 16) <= (others => instr(15)) when extop = '1' else (others => '0');

    -- extragerea campurilor func si sa din instructiune
    func <= instr(5 downto 0);
    sa <= instr(10 downto 6);
    
end behavioral;