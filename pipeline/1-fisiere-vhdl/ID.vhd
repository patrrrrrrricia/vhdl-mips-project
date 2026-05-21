library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- definitia entitatii pentru unitatea de decodificare
entity id is
    port ( clk, en : in std_logic; -- semnale de ceas si validare (buton)
           instr : in std_logic_vector(25 downto 0); -- restul instructiunii fara opcode
           wd : in std_logic_vector(31 downto 0); -- datele care trebuie scrise in registru
           --wa adaugat
           wa : in std_logic_vector(4 downto 0); -- adresa de scriere (wa) venita din mem/wb
           regwrite, extop : in std_logic; -- semnale de control de la uc (fara regdst)
           rd1, rd2, ext_imm : out std_logic_vector(31 downto 0); -- iesiri de date si offset extins
           func : out std_logic_vector(5 downto 0); -- campul function pentru alu control
           sa : out std_logic_vector(4 downto 0); -- shift amount pentru deplasari
           --iesirie rt si rd adaugate
           rt : out std_logic_vector(4 downto 0); -- adresa registrului rt pentru pipeline
           rd : out std_logic_vector(4 downto 0)); -- adresa registrului rd pentru pipeline
end id;

architecture behavioral of id is
    -- definirea tipului pentru bancul de registre (32 registre a cate 32 biti)
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    -- initializarea tuturor registrelor cu valoarea zero
    signal reg_file : reg_array := (others => x"00000000");
begin

    --PT PIPELINE
    -- proces pentru scrierea in registre pe frontul descrescator de ceas (falling edge)
    process(clk)
    begin
        if falling_edge(clk) then -- scrierea pe front descendent conform activitati practice
            -- scrierea are loc doar daca enable si regwrite sunt active
            if en = '1' and regwrite = '1' then
                reg_file(to_integer(unsigned(wa))) <= wd; -- foloseste adresa de scriere wa
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

    -- extragerea campurilor func, sa, rt si rd din instructiune
    func <= instr(5 downto 0);
    sa <= instr(10 downto 6);
    rt <= instr(20 downto 16); -- trimite rt catre registrul pipeline id/ex
    rd <= instr(15 downto 11); -- trimite rd catre registrul pipeline id/ex
    
end behavioral;