library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TEST_ENV is
    port ( 
        clk : in std_logic;             -- semnalul de ceas global de pe placa
        btn : in std_logic_vector (4 downto 0); -- butoanele de pe placa (reset, step etc)
        sw : in std_logic_vector (15 downto 0); -- switch-urile pentru selectia afisarii
        led : out std_logic_vector (15 downto 0); -- led-uri pentru vizualizarea semnalelor de control
        an : out std_logic_vector (7 downto 0);  -- selectia anodului pentru afisajul ssd
        cat : out std_logic_vector (6 downto 0)  -- segmentele catodului pentru afisajul ssd
    );
end TEST_ENV;

architecture behavioral of TEST_ENV is

-- semnale de control generate de unitatea de control (uc)
signal en_mpg, zero, pc_src : std_logic;
signal reg_dst, ext_op, alu_src, branch, jump, mem_write, mem_to_reg, reg_write : std_logic;
signal alu_op : std_logic_vector(2 downto 0);

-- magistrale de date pe 32 de biti pentru fluxul de date
signal instr, pc4, rd1, rd2, wd, ext_imm : std_logic_vector(31 downto 0);
signal alu_res, alu_res_mem, mem_data, branch_addr, jump_addr : std_logic_vector(31 downto 0);

-- semnale auxiliare extrase din instructiune
signal sa : std_logic_vector(4 downto 0);     -- shift amount
signal func : std_logic_vector(5 downto 0);   -- functia pentru alu
signal digits : std_logic_vector(31 downto 0); -- datele selectate pentru afisare pe ssd

-- componentele procesorului
-- mpg: mono-pulse generator pentru a executa instructiuni pas cu pas
component MPG is
    port ( btn : in std_logic; clk : in std_logic; en : out std_logic);
end component;

-- ssd: seven segment display pentru vizualizarea registrelor si memoriei
component SSD is
    port ( clk: in std_logic; digits: in std_logic_vector(31 downto 0); an: out std_logic_vector(7 downto 0); cat: out std_logic_vector(6 downto 0));
end component;

-- ifetch: extrage instructiunea curenta si calculeaza pc+4
component IFETCH is
    port ( clk: in std_logic; rst: in std_logic; en: in std_logic; jump: in std_logic; pcsrc: in std_logic; 
           jumpaddress: in std_logic_vector(31 downto 0); branchaddress: in std_logic_vector(31 downto 0);
           instruction: out std_logic_vector(31 downto 0); pc_4: out std_logic_vector(31 downto 0));
end component;

-- uc: unitatea de control care decodeaza opcode-ul si activeaza semnalele de control
component UC is
    port ( opcode: in std_logic_vector(5 downto 0); regdst: out std_logic; extop: out std_logic; alusrc: out std_logic; 
           branch: out std_logic; jump: out std_logic; aluop: out std_logic_vector(2 downto 0); memwrite: out std_logic; 
           memtoreg: out std_logic; regwrite: out std_logic);
end component;

-- id: decodificarea instructiunii si citirea din blocul de registre
component ID is
    port ( clk: in std_logic; en: in std_logic; instr: in std_logic_vector(25 downto 0); wd: in std_logic_vector(31 downto 0);
           regwrite: in std_logic; regdst: in std_logic; extop: in std_logic; rd1: out std_logic_vector(31 downto 0); 
           rd2: out std_logic_vector(31 downto 0); ext_imm: out std_logic_vector(31 downto 0); func: out std_logic_vector(5 downto 0); sa: out std_logic_vector(4 downto 0));
end component;

-- ex: unitatea de executie care efectueaza operatiile aritmetice/logice
component EX is
   Port ( RD1: in std_logic_vector(31 downto 0);
          RD2: in std_logic_vector(31 downto 0);
          ALUsrc: in std_logic;
          Ext_Imm: in std_logic_vector(31 downto 0);
          sa: in std_logic_vector(4 downto 0);
          func: in std_logic_vector(5 downto 0);
          ALUOp: in std_logic_vector(2 downto 0);
          PC_4: in std_logic_vector(31 downto 0);
          Zero: out std_logic;
          ALURes: out std_logic_vector(31 downto 0); 
          branch_addr: out std_logic_vector(31 downto 0));
end component;

-- mem: unitatea de memorie de date (pentru instructiuni load/store)
component MEM is
     Port ( clk: in std_logic;
            en: in std_logic;
            ALURes_In: in std_logic_vector(31 downto 0);
            RD2: in std_logic_vector(31 downto 0);
            MemWrite: in std_logic;
            MemData: out std_logic_vector(31 downto 0);
            ALURes_Out: out std_logic_vector(31 downto 0)
            );
end component;

begin
    -- folosim mpg pentru a avansa in program doar la apasarea butonului
    monopuls_en: mpg port map(btn => btn(0), clk => clk, en => en_mpg);
    
    -- calculul adresei de jump conform formatului mips
    jump_addr <= pc4(31 downto 28) & instr(25 downto 0) & "00"; 
    
    -- logica pentru pc_src (decide daca se face salt conditionat)
    pc_src <= branch and zero; 

    -- instantiere ifetch: aduce instructiunea din rom
    inst_if: ifetch port map(clk, btn(1), en_mpg, jump, pc_src, jump_addr, branch_addr, instr, pc4);
    
    -- instantiere uc: trimite semnale de control bazate pe bitii 31-26 ai instructiunii
    inst_uc: uc port map(instr(31 downto 26), reg_dst, ext_op, alu_src, branch, jump, alu_op, mem_write, mem_to_reg, reg_write);
    
    -- instantiere id: pregateste operanzii din registre si extinde constanta imediata
    inst_id: id port map(clk, en_mpg, instr(25 downto 0), wd, reg_write, reg_dst, ext_op, rd1, rd2, ext_imm, func, sa);
    
    -- instantiere ex: calculeaza rezultatul alu si adresa pentru branch
    inst_ex: EX port map(rd1, rd2, alu_src, ext_imm, sa, func, alu_op, pc4, zero, alu_res, branch_addr);
    
    -- instantiere mem: acceseaza ram-ul pentru date daca este necesar
    inst_mem: MEM port map(clk, en_mpg, alu_res, rd2, mem_write, mem_data, alu_res_mem);

    -- mux final care alege ce se scrie inapoi in registru (rezultat alu sau date din memorie)
    wd <= mem_data when mem_to_reg = '1' else alu_res_mem;

    -- proces pentru multiplexarea datelor afisate pe ssd prin switch-uri
    process(sw(7 downto 5), instr, pc4, rd1, rd2, ext_imm, alu_res, mem_data, wd)
    begin
        case sw(7 downto 5) is
            when "000" => digits <= instr;      -- afiseaza instructiunea binara
            when "001" => digits <= pc4;        -- afiseaza pc + 4
            when "010" => digits <= rd1;        -- afiseaza primul registru citit
            when "011" => digits <= rd2;        -- afiseaza al doilea registru citit
            when "100" => digits <= ext_imm;    -- afiseaza valoarea imediata extinsa
            when "101" => digits <= alu_res;    -- afiseaza rezultatul calculat de alu
            when "110" => digits <= mem_data;   -- afiseaza datele citite din ram
            when "111" => digits <= wd;         -- afiseaza valoarea finala de scriere
            when others => digits <= (others => '0');
        end case;
    end process;

    -- afisare pe segmente si semnalizare stari prin led-uri
    displ: SSD port map(clk, digits, an, cat);
    
    -- vizualizarea semnalelor de control pe primele 11 led-uri
    led(7 downto 0) <= reg_dst & ext_op & alu_src & branch & jump & mem_write & mem_to_reg & reg_write;
    led(10 downto 8) <= alu_op;
    
    -- led-ul 15 confirma daca semnalul de enable de la buton a fost generat
    led(15) <= en_mpg; 

end behavioral;