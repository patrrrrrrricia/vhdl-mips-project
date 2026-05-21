library ieee;
use ieee.std_logic_1164.all;

entity UC is
    port ( opcode : in std_logic_vector (5 downto 0); -- cei mai semnificativi 6 biti ai instructiunii
           regdst : out std_logic;    -- selecteaza registrul destinatie (rt sau rd)
           extop : out std_logic;     -- selecteaza tipul de extindere (cu semn sau zero)
           alusrc : out std_logic;    -- selecteaza a doua intrare alu (registru sau valoare imediata)
           branch : out std_logic;    -- activeaza logica pentru instructiuni de salt conditional
           jump : out std_logic;      -- activeaza saltul neconditional
           aluop : out std_logic_vector (2 downto 0); -- codul operatiei pentru unitatea alu control
           memwrite : out std_logic;  -- activeaza scrierea in memoria de date
           memtoreg : out std_logic;  -- selecteaza sursa pentru scrierea in registru (alu sau memorie)
           regwrite : out std_logic); -- activeaza permisiunea de scriere in bancul de registre
end UC;

architecture behavioral of UC is
begin
    process(opcode)
    begin
        -- setarea valorilor implicite pentru a evita generarea circuitelor de tip latch
        -- toate semnalele sunt dezactivate ('0') pana cand opcode-ul specifica altceva
        regdst <= '0'; extop <= '0'; alusrc <= '0'; branch <= '0'; jump <= '0'; 
        memwrite <= '0'; memtoreg <= '0'; regwrite <= '0'; aluop <= "000";
        
        case opcode is
            when "000000" => -- instructiuni de tip r (add, sub, and, or, etc.)
                regdst <= '1';    -- destinatia este campul rd
                regwrite <= '1';  -- se scrie rezultatul in registru
                aluop <= "000";   -- alu control va decide operatia dupa campul func

            when "001000" => -- addi (adunare cu o valoare imediata)
                alusrc <= '1';    -- se foloseste valoarea extinsa, nu al doilea registru
                regwrite <= '1';  -- se salveaza rezultatul in registru
                extop <= '1';     -- se face extindere cu semn a constantei
                aluop <= "001";   -- alu va executa adunare

            when "100011" => -- lw (load word din memorie in registru)
                alusrc <= '1';    -- alu calculeaza adresa folosind offset-ul
                regwrite <= '1';  -- se scrie valoarea citita in registru
                memtoreg <= '1';  -- datele vin din memorie, nu din alu
                extop <= '1';     -- extindere cu semn pentru offset
                aluop <= "001";   -- adunare pentru calculul adresei

            when "101011" => -- sw (store word din registru in memorie)
                alusrc <= '1';    -- alu calculeaza adresa de memorie
                memwrite <= '1';  -- se activeaza scrierea in ram
                extop <= '1';     -- extindere cu semn pentru offset
                aluop <= "001";   -- adunare pentru calculul adresei

            when "000100" => -- beq (branch if equal)
                branch <= '1';    -- se activeaza poarta de control pentru branch
                extop <= '1';     -- offset-ul de salt este extins cu semn
                aluop <= "010";   -- alu face scadere pentru a verifica egalitatea

            when "000010" => -- jump (salt neconditional)
                jump <= '1';      -- se forteaza noua adresa in pc

            when "001100" => -- andi (si logic cu o valoare imediata)
                alusrc <= '1';    -- se foloseste constanta din instructiune
                regwrite <= '1';  -- rezultatul se salveaza in registru
                extop <= '0';     -- zero extension (specific operatiilor logice)
                aluop <= "100";   -- alu va executa operatia and

            when others => 
                null; -- pentru orice alt opcode, semnalele raman la valorile de baza
        end case;
    end process;
end behavioral;