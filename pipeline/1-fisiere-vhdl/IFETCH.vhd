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
    type rom_type is array (0 to 63) of std_logic_vector(31 downto 0);
    -- definirea memoriei rom pentru stocarea programului modificat
    -- binar | pozitie | hexazecimal | asamblare | descriere efect
    signal mem_rom : rom_type := (
    -- etapa de initializare
    --2.inapoi aici
    0  => "10001100000000010000000000000100", -- poz 0: x"8C010004" | lw $1, 4($0)      | incarca n (elemente)
    1  => "00100000000000100000000000001000", -- poz 1: x"20020008" | addi $2, $0, 8    | adresa start sir
    2  => "00100000000000110000000000000000", -- poz 2: x"20030000" | addi $3, $0, 0    | contor rezultate = 0
    --1.sare aici->12 NoOP -> 2.sare
    3  => "00010000001000000000000000011001", -- poz 3: x"10200019" | beq $1, $0, 25    | daca n=0, sari la poz 29
    4  => "10001100010001000000000000000000", -- poz 4: x"8C440000" | lw $4, 0($2)      | incarca element curent
    5  => "00000000000000000000000000000000", -- poz 5: x"00000000" | noop              | hazard $4 (lw)
    6  => "00000000000000000000000000000000", -- poz 6: x"00000000" | noop              | hazard $4 (lw)

    7  => "00000000000001000010100000101010", -- poz 7: x"0004282A" | slt $5, $0, $4    | $5=1 daca $4 > 0
    8  => "00000000000000000000000000000000", -- poz 8: x"00000000" | noop              | hazard $5 (slt)
    9  => "00000000000000000000000000000000", -- poz 9: x"00000000" | noop              | hazard $5 (slt)

    10 => "00010000101000000000000000001010", -- poz 10: x"10A0000A" | beq $5, $0, 10   | daca nu e pozitiv, sari
    11 => "00110000100001010000000000000001", -- poz 11: x"30850001" | andi $5, $4, 1   | verifica daca e impar
    12 => "00000000000000000000000000000000", -- poz 12: x"00000000" | noop             | hazard $5 (andi)
    13 => "00000000000000000000000000000000", -- poz 13: x"00000000" | noop             | hazard $5 (andi)
    
    14 => "00010000101000000000000000000011", -- poz 14: x"10A00003" | beq $5, $0, 3    | daca e par, sari
    15 => "00100000011000110000000000000001", -- poz 15: x"20630001" | addi $3, $3, 1   | incrementare contor
    16 => "00100000010000100000000000000100", -- poz 16: x"20420004" | addi $2, $2, 4   | adresa urmatoare
    17 => "00100000001000011111111111111111", -- poz 17: x"2021FFFF" | addi $1, $1, -1  | n = n - 1
    18 => "00001000000000000000000000000011", -- poz 18: x"08000003" | j 3              | inapoi la beq (poz 3)
 
    others => (others => '0')
    --1.de aici
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