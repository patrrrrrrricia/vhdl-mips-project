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

-- adaugat pentru a prelua rt si rd din ID catre registrele pipeline
signal rt, rd : std_logic_vector(4 downto 0);
signal alu_res_wa : std_logic_vector(4 downto 0); -- iesirea multiplexorului RegDst din EX

--PIPELINE: semnale registre
--REGISTRUL IF/ID
signal REG_IF_ID_PC4, REG_IF_ID_Instr: std_logic_vector(31 downto 0);

--REGISTRUL ID/EX
signal REG_ID_EX_PC4, REG_ID_EX_RD1, REG_ID_EX_RD2, REG_ID_EX_ExtImm: std_logic_vector(31 downto 0);
signal REG_ID_EX_sa: std_logic_vector(4 downto 0);
signal REG_ID_EX_func: std_logic_vector(5 downto 0); 
signal REG_ID_EX_rt, REG_ID_EX_rd : std_logic_vector(4 downto 0);
--PT UC
signal REG_ID_EX_RegDst, REG_ID_EX_ALUSrc, REG_ID_EX_Branch, REG_ID_EX_MemWrite, REG_ID_EX_MemtoReg, REG_ID_EX_RegWrite : std_logic;
signal REG_ID_EX_ALUOp : std_logic_vector(2 downto 0);

--REGISTRUL EX/MEM
signal REG_EX_MEM_BranchAddr, REG_EX_MEM_ALURes, REG_EX_MEM_RD2 : std_logic_vector(31 downto 0);
signal REG_EX_MEM_Zero, REG_EX_MEM_Branch, REG_EX_MEM_MemWrite, REG_EX_MEM_MemtoReg, REG_EX_MEM_RegWrite : std_logic;
signal REG_EX_MEM_WriteReg : std_logic_vector(4 downto 0);

--REGISTRUL MEM/WB
signal REG_MEM_WB_MemData, REG_MEM_WB_ALURes : std_logic_vector(31 downto 0);
signal REG_MEM_WB_WriteReg : std_logic_vector(4 downto 0);
signal REG_MEM_WB_MemtoReg, REG_MEM_WB_RegWrite : std_logic;

-- componentele procesorului
component MPG is
    port ( btn : in std_logic; clk : in std_logic; en : out std_logic);
end component;

component SSD is
    port ( clk: in std_logic; digits: in std_logic_vector(31 downto 0); an: out std_logic_vector(7 downto 0); cat: out std_logic_vector(6 downto 0));
end component;

component IFETCH is
    port ( clk: in std_logic; rst: in std_logic; en: in std_logic; jump: in std_logic; pcsrc: in std_logic; 
           jumpaddress: in std_logic_vector(31 downto 0); branchaddress: in std_logic_vector(31 downto 0);
           instruction: out std_logic_vector(31 downto 0); pc_4: out std_logic_vector(31 downto 0));
end component;

component UC is
    port ( opcode: in std_logic_vector(5 downto 0); regdst: out std_logic; extop: out std_logic; alusrc: out std_logic; 
           branch: out std_logic; jump: out std_logic; aluop: out std_logic_vector(2 downto 0); memwrite: out std_logic; 
           memtoreg: out std_logic; regwrite: out std_logic);
end component;

component ID is
    port ( clk: in std_logic; en: in std_logic; instr: in std_logic_vector(25 downto 0); wd: in std_logic_vector(31 downto 0);
           wa: in std_logic_vector(4 downto 0); -- adaugat pentru wa din mem/wb
           regwrite: in std_logic; extop: in std_logic; rd1: out std_logic_vector(31 downto 0); 
           rd2: out std_logic_vector(31 downto 0); ext_imm: out std_logic_vector(31 downto 0); 
           func: out std_logic_vector(5 downto 0); sa: out std_logic_vector(4 downto 0);
           rt, rd : out std_logic_vector(4 downto 0)); -- adaugat pentru rt si rd
end component;

component EX is
   Port ( RD1, RD2, Ext_Imm, PC_4: in std_logic_vector(31 downto 0);
          rt, rd : in std_logic_vector(4 downto 0); -- adaugat rt, rd
          ALUsrc, regdst: in std_logic; -- adaugat regdst
          sa: in std_logic_vector(4 downto 0);
          func: in std_logic_vector(5 downto 0);
          ALUOp: in std_logic_vector(2 downto 0);
          Zero: out std_logic;
          rwa : out std_logic_vector(4 downto 0); -- adaugat rwa
          ALURes, branch_addr: out std_logic_vector(31 downto 0));
end component;

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
    
    --PROCESS PIPELINE
     process(clk)
    begin
        if rising_edge(clk) then
            if en_mpg = '1' then
                -- IF/ID
                REG_IF_ID_PC4 <= pc4;
                REG_IF_ID_Instr <= instr;
                -- ID/EX
                REG_ID_EX_PC4 <= REG_IF_ID_PC4;
                REG_ID_EX_RD1 <= rd1;
                REG_ID_EX_RD2 <= rd2;
                REG_ID_EX_ExtImm <= ext_imm;
                REG_ID_EX_sa <= sa;
                REG_ID_EX_func <= func;
                REG_ID_EX_rt <= rt; -- corectat sa ia din iesirea ID
                REG_ID_EX_rd <= rd; -- corectat sa ia din iesirea ID
                REG_ID_EX_RegDst <= reg_dst;
                REG_ID_EX_ALUOp <= alu_op;
                REG_ID_EX_ALUSrc <= alu_src;
                REG_ID_EX_Branch <= branch;
                REG_ID_EX_MemWrite <= mem_write;
                REG_ID_EX_MemtoReg <= mem_to_reg;
                REG_ID_EX_RegWrite <= reg_write;
                -- EX/MEM
                REG_EX_MEM_BranchAddr <= branch_addr;
                REG_EX_MEM_Zero <= zero;
                REG_EX_MEM_ALURes <= alu_res;
                REG_EX_MEM_RD2 <= REG_ID_EX_RD2;
                REG_EX_MEM_WriteReg <= alu_res_wa; -- preia adresa selectata de mux din EX
                REG_EX_MEM_Branch <= REG_ID_EX_Branch;
                REG_EX_MEM_MemWrite <= REG_ID_EX_MemWrite;
                REG_EX_MEM_MemtoReg <= REG_ID_EX_MemtoReg;
                REG_EX_MEM_RegWrite <= REG_ID_EX_RegWrite;
                -- MEM/WB
                REG_MEM_WB_MemData <= mem_data;
                REG_MEM_WB_ALURes <= alu_res_mem;
                REG_MEM_WB_WriteReg <= REG_EX_MEM_WriteReg;
                REG_MEM_WB_MemtoReg <= REG_EX_MEM_MemtoReg;
                REG_MEM_WB_RegWrite <= REG_EX_MEM_RegWrite;
            end if;
        end if;
    end process;
    
    -- calculul adresei de jump conform formatului mips
    jump_addr <= REG_IF_ID_PC4(31 downto 28) & REG_IF_ID_Instr(25 downto 0) & "00"; 
    
    -- logica pentru pc_src
    pc_src <= REG_EX_MEM_Branch and REG_EX_MEM_Zero; 

    -- instantiere ifetch
    inst_if: ifetch port map(clk, btn(1), en_mpg, jump, pc_src, jump_addr, REG_EX_MEM_BranchAddr, instr, pc4);
    
    -- instantiere uc
    inst_uc: uc port map(REG_IF_ID_Instr(31 downto 26), reg_dst, ext_op, alu_src, branch, jump, alu_op, mem_write, mem_to_reg, reg_write);
    
    -- instantiere id: conectat la reg_write si wa din etapa WB
    inst_id: id port map(clk, en_mpg, REG_IF_ID_Instr(25 downto 0), wd, REG_MEM_WB_WriteReg, REG_MEM_WB_RegWrite, ext_op, rd1, rd2, ext_imm, func, sa, rt, rd);
    
    -- instantiere ex: acum include regdst si rwa
    inst_ex: EX port map(REG_ID_EX_RD1, REG_ID_EX_RD2, REG_ID_EX_ExtImm, REG_ID_EX_PC4, REG_ID_EX_rt, REG_ID_EX_rd, REG_ID_EX_ALUSrc, REG_ID_EX_RegDst, REG_ID_EX_sa, REG_ID_EX_func, REG_ID_EX_ALUOp, zero, alu_res_wa, alu_res, branch_addr);
    
    -- instantiere mem
    inst_mem: MEM port map(clk, en_mpg, REG_EX_MEM_ALURes, REG_EX_MEM_RD2, REG_EX_MEM_MemWrite, mem_data, alu_res_mem);

    -- mux final WB
    wd <= REG_MEM_WB_MemData when REG_MEM_WB_MemtoReg = '1' else REG_MEM_WB_ALURes;

    -- proces multiplexare ssd
    process(sw(7 downto 5), REG_IF_ID_Instr, REG_IF_ID_PC4, REG_ID_EX_RD1, REG_ID_EX_RD2, REG_ID_EX_ExtImm, REG_EX_MEM_ALURes, REG_MEM_WB_MemData, wd)
    begin
        case sw(7 downto 5) is
            when "000" => digits <= REG_IF_ID_Instr;
            when "001" => digits <= REG_IF_ID_PC4;
            when "010" => digits <= REG_ID_EX_RD1;
            when "011" => digits <= REG_ID_EX_RD2;
            when "100" => digits <= REG_ID_EX_ExtImm;
            when "101" => digits <= REG_EX_MEM_ALURes;
            when "110" => digits <= REG_MEM_WB_MemData;
            when "111" => digits <= wd;
            when others => digits <= (others => '0');
        end case;
    end process;

    displ: SSD port map(clk, digits, an, cat);
    
    led(7 downto 0) <= REG_ID_EX_RegDst & ext_op & REG_ID_EX_ALUSrc & REG_ID_EX_Branch & jump & REG_ID_EX_MemWrite & REG_ID_EX_MemtoReg & REG_ID_EX_RegWrite;
    led(10 downto 8) <= REG_ID_EX_ALUOp;
    led(15) <= en_mpg; 

end behavioral;