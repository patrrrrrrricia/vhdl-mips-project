library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity IFETCH is
 port ( 
    clk: in std_logic;              -- semnalul de ceas global
    rst: in std_logic;              -- reset asincron pentru aducerea pc la zero
    en: in std_logic;               -- semnal de enable de la mpg pentru executie pas cu pas
    jump: in std_logic;             -- semnal de control care indica o instructiune de jump
    pcsrc: in std_logic;            -- semnal de control pentru alegerea adresei de branch
    jumpaddress: in std_logic_vector(31 downto 0); -- adresa tinta pentru jump
    branchaddress: in std_logic_vector(31 downto 0); -- adresa tinta pentru branch
    instruction: out std_logic_vector(31 downto 0); -- instructiunea citita trimisa spre decodificare
    pc_4: out std_logic_vector(31 downto 0) -- adresa pc incrementata cu 4
 );
end IFETCH;

architecture behavioral of IFETCH is
    -- registrul program counter (pc) care tine adresa curenta
    signal pc_reg : std_logic_vector(31 downto 0) := (others => '0');
    -- semnale interne pentru calculul adresei urmatoare
    signal pc_next : std_logic_vector(31 downto 0);
    signal pc_inc : std_logic_vector(31 downto 0);
    signal mux_branch_out : std_logic_vector(31 downto 0);
    
    -- definirea memoriei rom pentru stocarea programului
    type rom_type is array (0 to 31) of std_logic_vector(31 downto 0);
    -- programul pentru numararea valorilor pozitive si impare
    -- pozitie | hexazecimal | codificare binara pe campuri (Op|rs|rt|Imm sau Op|target) | asamblare | descriere
    signal mem_rom : rom_type := (
        0  => x"8C010004", -- b"100011_00000_00001_0000000000000100" | lw $1, 4($0) : incarca n de la adresa 4 in reg 1
        1  => x"20020008", -- b"001000_00000_00010_0000000000001000" | addi $2, $0, 8 : reg 2 devine adresa de start a sirului
        2  => x"20030000", -- b"001000_00000_00011_0000000000000000" | addi $3, $0, 0 : reg 3 este contorul pentru rezultat
        
        -- bucla -> apoi aici
        3  => x"1020000A", -- b"000100_00001_00000_0000000000001010" | beq $1, $0, 10 : daca n a ajuns la 0, sari la final
        4  => x"8C440000", -- b"100011_00010_00100_0000000000000000" | lw $4, 0($2) : citeste elementul curent in reg 4
        5  => x"0004282A", -- b"000000_00000_00100_00101_00000_101010" | slt $5, $0, $4 : verifica daca elementul este > 0
        6  => x"10A00003", -- b"000100_00101_00000_0000000000000011" | beq $5, $0, 3 : daca nu e pozitiv, sari peste pasi
        -- sare
        7  => x"30850001", -- b"001100_00100_00101_0000000000000001" | andi $5, $4, 1 : verifica bitul 0 pentru numar impar
        8  => x"10A00001", -- b"000100_00101_00000_0000000000000001" | beq $5, $0, 1 : daca nu e impar, sari peste incrementare
        9  => x"20630001", -- b"001000_00011_00011_0000000000000001" | addi $3, $3, 1 : incrementeaza contorul de numere gasite
        -- aici
        10 => x"20420004", -- b"001000_00010_00010_0000000000000100" | addi $2, $2, 4 : trece la urmatoarea adresa de memorie
        11 => x"2021FFFF", -- b"001000_00001_00001_1111111111111111" | addi $1, $1, -1 : scade 1 din numarul de elemente ramase
        12 => x"08000003", -- b"000010_00000000000000000000000011"   | j 3 : revino la inceputul buclei pentru testarea lui n
        13 => x"AC030000", -- b"101011_00000_00011_0000000000000000" | sw $3, 0($0) : scrie rezultatul final la adresa 0
        others => x"00000000"
    );
begin
    -- proces sincron pentru actualizarea registrului pc
    process(clk, rst)
    begin
        if rst = '1' then 
            pc_reg <= (others => '0'); -- la reset, pc revine la prima instructiune
        elsif rising_edge(clk) then
            if en = '1' then 
                pc_reg <= pc_next; -- actualizeaza pc doar la apasarea butonului
            end if;
        end if;
    end process;

    -- logica combinationala pentru calculul adresei urmatoare
    pc_inc <= pc_reg + 4; -- incrementare standard cu 4 octeti
    pc_4 <= pc_inc; -- trimite pc+4 spre exterior (pentru jump sau branch)
    
    -- multiplexor pentru alegerea intre pc+4 si adresa de branch
    mux_branch_out <= branchaddress when pcsrc = '1' else pc_inc;
    
    -- multiplexor final pentru alegerea adresei urmatoare (jump sau secvential/branch)
    pc_next <= jumpaddress when jump = '1' else mux_branch_out;
    
    -- accesarea memoriei rom pentru a scoate instructiunea
    -- se folosesc bitii 6-2 pentru ca memoria este organizata pe cuvinte de 32 biti (alinere la 4)
    instruction <= mem_rom(to_integer(unsigned(pc_reg(6 downto 2))));
    
end behavioral;