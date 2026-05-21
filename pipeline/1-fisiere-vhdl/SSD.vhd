library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- entitatea ssd se ocupa de afisarea datelor pe cele 8 cifre ale placii
-- aceasta transforma datele binare in semnale electrice pentru segmente
entity ssd is
    port ( 
        clk : in std_logic; -- ceasul de 100 mhz al placii pentru multiplexare rapida
        digits : in std_logic_vector(31 downto 0); -- vectorul care contine cele 8 cifre hexa
        an : out std_logic_vector(7 downto 0);    -- iesirile pentru anozi (controleaza pozitia)
        cat : out std_logic_vector(6 downto 0)   -- iesirile pentru catozi (controleaza forma)
    );
end ssd;

architecture behavioral of ssd is
    -- contorul cnt este folosit ca divizor de frecventa
    -- placa nu poate aprinde toate cifrele simultan, asa ca le aprinde pe rand
    signal cnt : std_logic_vector(16 downto 0);
    
    -- sel (selectia) determina care din cele 8 cifre este procesata acum
    signal sel : std_logic_vector(2 downto 0);
    
    -- digit retine valoarea de 4 biti (0-f) care trebuie afisata pe pozitia curenta
    signal digit : std_logic_vector(3 downto 0);
begin

    -- procesul pentru incrementarea contorului principal
    -- la fiecare front crescator de ceas, numarul creste cu 1
    process(clk)
    begin
        if rising_edge(clk) then 
            cnt <= cnt + 1;
        end if;
    end process;

    -- multiplexarea se bazeaza pe viteza de refresh a ochiului uman
    -- folosim bitii 15, 14 si 13 ai contorului pentru a schimba cifrele
    -- acesti biti se schimba suficient de rapid pentru a nu vedea palpairi
    sel <= cnt(15 downto 13);

    -- bloc pentru extragerea datelor corecte din vectorul de 32 de biti
    -- in functie de valoarea sel, decupam cate 4 biti din intrarea digits
    process(sel, digits)
    begin
        case sel is
            when "000" => digit <= digits(3 downto 0);   -- prima cifra (cea mai din dreapta)
            when "001" => digit <= digits(7 downto 4);   -- a doua cifra
            when "010" => digit <= digits(11 downto 8);  -- a treia cifra
            when "011" => digit <= digits(15 downto 12); -- a patra cifra
            when "100" => digit <= digits(19 downto 16); -- a cincea cifra
            when "101" => digit <= digits(23 downto 20); -- a sasea cifra
            when "110" => digit <= digits(27 downto 24); -- a saptea cifra
            when "111" => digit <= digits(31 downto 28); -- a opta cifra (cea mai din stanga)
            when others => digit <= (others => '0');
        end case;
    end process;

    -- decodorul transforma un numar de 4 biti intr-un model de segmente
    -- ordinea segmentelor in vectorul cat este de obicei: g f e d c b a
    -- logica este negativa: '0' inseamna ca segmentul primeste curent si se aprinde
    process(digit)
    begin
        case digit is
            -- formatul cat este: "abcdefg" (poate varia in functie de maparea pinilor)
            when "0000" => cat <= "1000000"; -- cifra 0 (toate segmentele aprinse in afara de g)
            when "0001" => cat <= "1111001"; -- cifra 1
            when "0010" => cat <= "0100100"; -- cifra 2
            when "0011" => cat <= "0110000"; -- cifra 3
            when "0100" => cat <= "0011001"; -- cifra 4
            when "0101" => cat <= "0010010"; -- cifra 5
            when "0110" => cat <= "0000010"; -- cifra 6
            when "0111" => cat <= "1111000"; -- cifra 7
            when "1000" => cat <= "0000000"; -- cifra 8 (toate segmentele aprinse)
            when "1001" => cat <= "0010000"; -- cifra 9
            when "1010" => cat <= "0001000"; -- litera a
            when "1011" => cat <= "0000011"; -- litera b
            when "1100" => cat <= "1000110"; -- litera c
            when "1101" => cat <= "0100001"; -- litera d
            when "1110" => cat <= "0000110"; -- litera e
            when "1111" => cat <= "0001110"; -- litera f
            when others => cat <= "1111111"; -- eroare: toate segmentele stinse
        end case;
    end process;

    -- activarea fizica a afisajului prin anozi
    -- anozii sunt in logica negativa: un '0' pe bitul respectiv activeaza acea pozitie
    -- prin multiplexare, aprindem doar o singura cifra in orice microsecunda
    process(sel)
    begin
        case sel is
            when "000" => an <= "11111110"; -- aprinde afisajul 0
            when "001" => an <= "11111101"; -- aprinde afisajul 1
            when "010" => an <= "11111011"; -- aprinde afisajul 2
            when "011" => an <= "11110111"; -- aprinde afisajul 3
            when "100" => an <= "11101111"; -- aprinde afisajul 4
            when "101" => an <= "11011111"; -- aprinde afisajul 5
            when "110" => an <= "10111111"; -- aprinde afisajul 6
            when "111" => an <= "01111111"; -- aprinde afisajul 7
            when others => an <= "11111111"; -- opreste toate afisajele
        end case;
    end process;

end behavioral;