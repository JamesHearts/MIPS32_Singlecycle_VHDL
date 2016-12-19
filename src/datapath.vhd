library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is -- This datapath will be used with a controller.

	generic (
		width  :     positive := 32);
	port(
			mem_clk          : in std_logic;
			rst				 : in std_logic;
			
			alu_op_code      : in std_logic_vector(2 downto 0);
			alu_b_mux_sel    : in std_logic;
			branch 			 : in std_logic;
			branch_ne        : in std_logic;
			data_mem_wren	 : in std_logic;
			data_mux_sel	 : in std_logic_vector(1 downto 0);
			dest_mux_sel     : in std_logic_vector(1 downto 0);
			inst_mem_en      : in std_logic;
			lui 			 : in std_logic;
			load_command	 : in std_logic_vector(1 downto 0);
			pc_mux_sel       : in std_logic_vector(1 downto 0);
			pc_reg_en		 : in std_logic;
			reg_file_en		 : in std_logic;
			sign_ext_sel	 : in std_logic;
			store_command    : in std_logic_vector(1 downto 0);
			func        : out std_logic_vector(5 downto 0);
			carry 		: out std_logic;
			op_code		: out std_logic_vector(5 downto 0);
			overflow 	: out std_logic;
			sign 		: out std_logic
		);
	
end datapath;

architecture str of datapath is
	
	signal clk 				: std_logic;
	
	signal alu_b_mux_out_n  : std_logic_vector(width-1 downto 0);
	signal alu_out_n 		: std_logic_vector(width-1 downto 0);
	signal alu_ctrl_out_n 	: std_logic_vector(3 downto 0);
	signal alu_ctrl_shdir_n : std_logic;
	signal br_mux_sel_n		: std_logic;
	signal br_mux_out_n 	: std_logic_vector(width-1 downto 0);
	signal br_add_out_n 	: std_logic_vector(width-1 downto 0);
	signal data_mem_out_n 	: std_logic_vector(width-1 downto 0);
	signal data_mux_out_n   : std_logic_vector(width-1 downto 0);
	signal dest_mux_out_n   : std_logic_vector(4 downto 0);
	signal extender_out_n 	: std_logic_vector(width-1 downto 0);
	signal increment		: std_logic_vector(width-1 downto 0);
	signal instruction_n 	: std_logic_vector(width-1 downto 0);
	signal pc_out_n 		: std_logic_vector(width-1 downto 0);
	signal pc_mux_in1		: std_logic_vector(width-1 downto 0);
	signal pc_mux_out_n     : std_logic_vector(width-1 downto 0);
	signal pc_inc_out_n 	: std_logic_vector(31 downto 0);
	signal regfile_out_a_n 	: std_logic_vector(width-1 downto 0);
	signal regfile_out_b_n 	: std_logic_vector(width-1 downto 0);
	signal return_reg		: std_logic_vector(4 downto 0);
	signal sl_br_out_n		: std_logic_vector(width-1 downto 0);
	signal sl_jmp_out_n     : std_logic_vector(27 downto 0);
	signal zero_n		    : std_logic;
	
	
	

begin

	PC_INC : entity work.add32 -- The adder to calculate PC increment. (PC + 4)
		port map(
			in0     => pc_out_n,
			in1     => increment,
			sum     => pc_inc_out_n
		);

	ALU	: entity work.alu32 -- The ALU entity.
		port map(
			ia  	=> regfile_out_a_n,
			ib 		=> alu_b_mux_out_n,
			control => alu_ctrl_out_n,
			shamt	=> instruction_n(10 downto 6),
			shdir	=> alu_ctrl_shdir_n,
			lui     => lui,
			bne     => branch_ne,
			o 	    => alu_out_n,
			Z 	    => zero_n,
			S       => sign,
			V	    => overflow,
			C       => carry
		);
		
	ALU_B_MUX : entity work.mux32 -- The mux that feeds the B input to the ALU.
		port map(
			in0     => regfile_out_b_n,
			in1     => extender_out_n,
			Sel     => alu_b_mux_sel,
			O       => alu_b_mux_out_n
		);
		
	ALU_CONT : entity work.alu32control -- The ALU control.
		port map(
			func    => instruction_n(5 downto 0),
			ALUop   => alu_op_code,
			control => alu_ctrl_out_n,
			shdir   => alu_ctrl_shdir_n
		);
		
	BRANCH_ADD : entity work.add32 -- The adder to calculate branches.
		port map(
			in0     => pc_inc_out_n,
			in1     => sl_br_out_n,
			sum     => br_add_out_n
		);
		
	BRANCH_MUX : entity work.mux32 -- The mux that selects between the jump address or branch address.
		port map(
			in0     => pc_inc_out_n,
			in1     => br_add_out_n,
			Sel     => br_mux_sel_n,
			O       => br_mux_out_n
		);

	CLK_DIV : entity work.clk_divider -- This entity divides the clock memory.
		port map(
			clk 	=> mem_clk,
			div_clk => clk
		);
		
	DATA_MUX : entity work.mux32_4 -- The mux that feeds the data input on the register file.
		port map(
			in0     => alu_out_n,
			in1     => data_mem_out_n,
			in2 	=> pc_inc_out_n,
			in3		=> pc_inc_out_n,
			Sel     => data_mux_sel,
			O       => data_mux_out_n
		);
	
	DEST_MUX : entity work.mux5_4 -- The mux that feeds the destination register in the register file.
		port map(
			in0     => instruction_n(20 downto 16),
			in1     => instruction_n(15 downto 11),
			in2     => return_reg,
			in3 	=> return_reg,
			Sel     => dest_mux_sel,
			O       => dest_mux_out_n
		);	
		
	INST_MEM : entity work.instruction_memory -- The instruction register.
		port map(
		address		=> pc_out_n(9 downto 2),
		clock		=> mem_clk,
		rden		=> inst_mem_en,
		q			=> instruction_n
		);
		
	PC_REG : entity work.pc_reg32 -- The PC register.
		port map(
			Clk     => clk,
			clr     => rst,
			wr      => pc_reg_en,
			D       => pc_mux_out_n,
			Q       => pc_out_n
		);
		
	PC_MUX : entity work.mux32_4 -- The mux that feeds the PC register.
		port map(
			in0     => br_mux_out_n,
			in1     => pc_mux_in1,
			in2     => alu_out_n,
			in3		=> alu_out_n,
			Sel     => pc_mux_sel,
			O 	    => pc_mux_out_n
		);
		
	BR_EN : entity work.branchlogic -- Logic that selects the branch value to the pc register.
		port map(
			Z       => zero_n,
			branch  => branch,
			output  => br_mux_sel_n
		);	
		
	REG_FILE : entity work.registerFile -- register file entity.
		port map(
			q0      => regfile_out_a_n,
			q1      => regfile_out_b_n,
			d       => data_mux_out_n,
			wr      => reg_file_en,
			rr0   	=> instruction_n(25 downto 21),
			rr1   	=> instruction_n(20 downto 16),
			rw	  	=> dest_mux_out_n,
			clk     => clk,
			rst     => rst
		);
	
	SIGN_EXT : entity work.extender -- This module does sign extension. Could also use ALU for this.
		port map(
			in0  	=> instruction_n(15 downto 0),
			Sel		=> sign_ext_sel,
			out0	=> extender_out_n
		);
		
	SHIFT_LEFT_BRANCH : entity work.leftshift32 -- This module performs a left shift twice.
		port map(
			input   => extender_out_n,
			output  => sl_br_out_n
		);
		
	SHIFT_LEFT_JUMP : entity work.leftshift26 -- This module performs a left shift twice. 
		port map(
			input   => instruction_n(25 downto 0),
			output  => sl_jmp_out_n
		);
		
	DATA_MEM : entity work.data_memory -- Not sure if the RAM implementation is the correct one but needed to compile datapath.
		port map(
			mem_clk          => mem_clk,
			address          => alu_out_n(7 downto 0),
			data			 => regfile_out_b_n,
			wren			 => data_mem_wren,
			store_command    => store_command,
			load_command     => load_command,
			q				 => data_mem_out_n -- 32 bit output.
		);
	
	increment <= x"00000004"; 
	return_reg <= "11111";
	pc_mux_in1 <= pc_inc_out_n(31 downto 28) & sl_jmp_out_n;
	op_code <= instruction_n(31 downto 26);
	func <= instruction_n(5 downto 0);
	

end str;