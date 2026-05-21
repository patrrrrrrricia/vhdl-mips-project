library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- entitatea pentru generatorul de impuls unic (debounce si detectie front)
entity MPG is
    port ( 
        btn : in std_logic; -- intrarea de la butonul fizic (cu zgomot)
        clk : in std_logic; -- ceasul principal al sistemului
        en  : out std_logic -- impulsul curat de iesire, activ un singur ciclu
    );
end MPG;

architecture behavioral of MPG is
    -- numarator pe 16 biti pentru a crea o perioada de asteptare (debounce)
    signal count : std_logic_vector (15 downto 0) := (others => '0');
    
    -- semnal de ceas intern mult mai lent pentru esantionare
    signal t : std_logic;
    
    -- bistabili de tip flip-flop pentru sincronizare si detectie front
    signal q1, q2, q3 : std_logic;
begin

    -- proces pentru numararea ciclurilor de ceas
    process (clk)
    begin
        if rising_edge(clk) then
            count <= count + 1; -- incrementare la fiecare puls de ceas
        end if;
    end process;

    -- generarea unui semnal de activare la fiecare aproximativ 650 microsecunde
    -- acest semnal filtreaza micile oscilatii mecanice ale butonului
    t <= '1' when count = x"ffff" else '0';

    -- primul bistabil sincronizeaza butonul cu ceasul sistemului
    -- esantionarea se face rar (doar cand t este 1) pentru a ignora zgomotul
    process(clk)
    begin
        if rising_edge(clk) then
            if t = '1' then
                q1 <= btn;
            end if;
        end if;
    end process;

    -- urmatorii doi bistabili creeaza o intarziere pentru a putea compara starile
    -- q2 retine starea actuala, q3 retine starea anterioara
    process(clk)
    begin
        if rising_edge(clk) then
            q2 <= q1;
            q3 <= q2;
        end if;
    end process;

    -- detectia frontului crescator (momentul in care butonul este apasat)
    -- en este 1 doar atunci cand starea noua e sus (q2) si cea veche era jos (q3)
    en <= q2 and not q3;

end behavioral;