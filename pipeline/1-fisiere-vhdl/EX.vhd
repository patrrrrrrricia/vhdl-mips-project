library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ex is
  port ( rd1, rd2, ext_imm, pc_4 : in std_logic_vector(31 downto 0); -- intrari date si adresa pc
       --rt si rd adaugat, 5 biti 
         rt, rd : in std_logic_vector(4 downto 0);      -- adresele registrelor din etajul id/ex
       --regdst adaugat
         alusrc, regdst : in std_logic;                 -- semnale de control (regdst mutat aici)
         sa : in std_logic_vector(4 downto 0);          -- shift amount pentru operatii de deplasare
         func : in std_logic_vector(5 downto 0);        -- campul function pentru instructiuni tip r
         aluop : in std_logic_vector(2 downto 0);       -- cod de operatie trimis de unitatea de control
         zero : out std_logic;                          -- flag care indica daca rezultatul alu este zero
         rwa : out std_logic_vector(4 downto 0);        -- adresa registrului de scriere selectata
         alures, branch_addr : out std_logic_vector(31 downto 0)); -- rezultat alu si adresa branch
end ex;

architecture behavioral of ex is
    signal alu_ctrl: std_logic_vector(2 downto 0); -- semnal intern pentru controlul alu
    signal alu_in2, res_tmp: std_logic_vector(31 downto 0); -- intrarea 2 si rezultat temporar
begin
    -- multiplexor pentru selectia celei de-a doua intrari a alu
    -- daca alusrc este 0, se foloseste rd2; daca este 1, se foloseste valoarea extinsa
    alu_in2 <= rd2 when alusrc = '0' else ext_imm;

    --PT PIPELINE
    -- multiplexor pentru selectia adresei de scriere (rwa)
    -- mutarea de la id la ex conform schemei de pipeline
    rwa <= rt when regdst = '0' else rd;
    
    -- proces pentru unitatea de control alu locala
    -- traduce aluop si func intr-o comanda specifica pentru alu
    process(aluop, func)
    begin
        case aluop is
            when "000" => -- instructiuni de tip r: operatia depinde de campul func
                case func is
                    when "100000" => alu_ctrl <= "000"; -- add (adunare)
                    when "100010" => alu_ctrl <= "001"; -- sub (scadere)
                    when "100100" => alu_ctrl <= "100"; -- and (si logic)
                    when "101010" => alu_ctrl <= "110"; -- slt (set on less than)
                    when others => alu_ctrl <= "111";
                end case;
            when "001" => alu_ctrl <= "000"; -- adunare pentru addi, lw, sw
            when "010" => alu_ctrl <= "001"; -- scadere pentru beq (verificare egalitate)
            when "100" => alu_ctrl <= "100"; -- si logic pentru andi
            when others => alu_ctrl <= "111";
        end case;
    end process;

    -- proces pentru executia operatiilor aritmetice si logice (alu propriu-zis)
    process(alu_ctrl, rd1, alu_in2, sa)
    begin
        case alu_ctrl is
            when "000" => res_tmp <= rd1 + alu_in2; -- adunare
            when "001" => res_tmp <= rd1 - alu_in2; -- scadere
            when "100" => res_tmp <= rd1 and alu_in2; -- si logic
            when "110" => -- operatia slt: verifica daca primul operand e mai mic decat al doilea
                if signed(rd1) < signed(alu_in2) then 
                    res_tmp <= x"00000001"; -- rezultatul este 1 daca e adevarat
                else 
                    res_tmp <= x"00000000"; -- altfel rezultatul este 0
                end if;
            when others => res_tmp <= (others => '0');
        end case;
    end process;

    -- atribuirea rezultatului catre iesire
    alures <= res_tmp;
    
    -- generarea flag-ului zero (util pentru instructiunea beq)
    -- devine 1 daca rezultatul alu este exact zero
    zero <= '1' when (res_tmp = x"00000000") else '0';
    
    -- calculul adresei de salt pentru branch (pc+4 + offset shiftat la stanga cu 2)
    -- shiftarea cu 2 se face prin concatenarea cu "00" pentru alinierea la cuvant
    branch_addr <= pc_4 + (ext_imm(29 downto 0) & "00");
    
end behavioral;