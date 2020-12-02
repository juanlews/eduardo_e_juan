LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY eduardo_e_juan IS
	PORT (
		-- ENTRADAS
		clk			: IN STD_LOGIC;
		nrst		: IN STD_LOGIC;
		instr		: IN STD_LOGIC_VECTOR(13 DOWNTO 0);
		alu_z		: IN STD_LOGIC;						-- Entrada flag de zero ALU

		-- SAIDAS
		op_sel		: OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Selecionar operação da ALU
		bit_sel		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- Selecionar bit 
		wr_z_en		: OUT STD_LOGIC;					-- Flag de Zero
		wr_dc_en	: OUT STD_LOGIC;					-- Carry out nibble
		wr_c_en		: OUT STD_LOGIC;					-- Carry out
		wr_w_reg_en	: OUT STD_LOGIC;					-- Escrita em W
		wr_en		: OUT STD_LOGIC;					-- Habilitar escrita 
		rd_en		: OUT STD_LOGIC;					-- Habilitar leitura
		load_pc		: OUT STD_LOGIC;					-- Carregar de PC
		inc_pc		: OUT STD_LOGIC;					-- Incrementar PC
		stack_push	: OUT STD_LOGIC;					-- Colocar na pilha
		stack_pop	: OUT STD_LOGIC;					-- Remover da pilha
		lit_sel		: OUT STD_LOGIC						-- Literal
	);
END eduardo_e_juan;

ARCHITECTURE arch OF eduardo_e_juan IS

	TYPE state_type IS (reset, fetch_decode, fetch_only);
	SIGNAL next_state	: state_type;
	SIGNAL pres_state	: state_type;

	SIGNAL opcode		: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL dir_bit		: STD_LOGIC;
	SIGNAL b_bits		: STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN

	opcode <= instr(13 DOWNTO 8);
	dir_bit <= instr(7);
	b_bits <= instr(9 DOWNTO 7);

	PROCESS(nrst, clk)
	BEGIN 
		IF nrst = '0' THEN
			pres_state <= reset;
		ELSIF RISING_EDGE(clk) THEN
			pres_state <= next_state;
		END IF;
	END PROCESS;


	PROCESS(pres_state, nrst, instr, alu_z, b_bits, opcode, dir_bit)
	BEGIN 
		
		next_state <= pres_state;

		op_sel 		<= "----";
		bit_sel 	<= "---";
		wr_z_en 	<= '0';
		wr_dc_en 	<= '0';
		wr_c_en 	<= '0';
		wr_w_reg_en <= '0';
		wr_en 		<= '0';
		rd_en 		<= '0';
		load_pc 	<= '0';
		inc_pc 		<= '0';
		stack_push 	<= '0';
		stack_pop 	<= '0';
		lit_sel 	<= '0';

		CASE pres_state IS
			WHEN reset =>
				IF nrst = '0' THEN
					next_state <= reset;
				ELSE 
					next_state <= fetch_only;
				END IF;

			-- Apenas buscar instrução	
			WHEN fetch_only =>
				next_state <= fetch_decode;
				inc_pc <= '1';

			-- Buscar e decodificar instrução. Operação sobre registradores	
			WHEN fetch_decode =>
			-- Operações efetuadas sobre registradores
				CASE opcode IS
					WHEN "000111" => -- ADDWF
						next_state 	<= fetch_decode;
						
						op_sel 		<= "1000";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						wr_dc_en 	<= '1';
						wr_c_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "000101" => -- ANDWF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0001";
						wr_z_en 	<= '1';
						inc_pc 		<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
						
					WHEN "000001" => -- CLRF ou CLRW	
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0111";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							rd_en <= '1';
							wr_en <= '1';
						END IF;
					
					WHEN "001001" => -- COMF
						next_state	<= fetch_decode;
					
						op_sel 		<= "0011";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "000011" => -- DECF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1011";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;		
						
					WHEN "001011" => -- DECFSZ
						IF alu_z = '0' THEN
							next_state 	<= fetch_only;
						ELSE
							next_state 	<= fetch_decode;
							
							op_sel 		<= "1011";
							inc_pc 		<= '1';
							rd_en 		<= '1';
							
							IF dir_bit = '0' THEN
								wr_w_reg_en <= '1';
							ELSE
								wr_en <= '1';
							END IF;
						END IF;		
					
					WHEN "001010" => -- INCF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1010";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;							
					
					WHEN "001111" => -- INCFSZ
						IF alu_z = '0' THEN
							next_state <= fetch_only;
						ELSE
							next_state 	<= fetch_decode;
							
							op_sel 		<= "1010";
							inc_pc 		<= '1';
							rd_en 		<= '1';
							
							IF dir_bit = '0' THEN
								wr_w_reg_en <= '1';
							ELSE
								wr_en <= '1';
							END IF;
						END IF;
					
					WHEN "000100" => -- IORWF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0000";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "001000" => -- MOVF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1111";
						inc_pc 		<= '1';
						wr_z_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "000000" => -- NOP\MOVEWF
						next_state 	<= fetch_decode;
						
						inc_pc 		<= '1';
						
						IF dir_bit = '1' THEN
							op_sel 	<= "1110";
							wr_en 	<= '1';
						END IF;
					
					WHEN "001101" => -- RLF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0101";
						wr_c_en 	<= '1';
						inc_pc 		<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "001100" => -- RRF
						next_state <= fetch_decode;
					
						op_sel 	<= "0100";
						inc_pc 	<= '1';
						wr_c_en <= '1';
						rd_en 	<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "000010" => -- SUBWF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1001";
						inc_pc 		<= '1';
						wr_c_en 	<= '1';
						wr_dc_en 	<= '1';
						wr_z_en 	<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "001110" => -- SWAPF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0110";
						inc_pc 		<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "000110" => -- XORWF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0010";
						wr_z_en 	<= '1';
						inc_pc 		<= '1';
						rd_en 		<= '1';
						
						IF dir_bit = '0' THEN
							wr_w_reg_en <= '1';
						ELSE
							wr_en <= '1';
						END IF;
					
					WHEN "111001" => -- ANDLW
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0001";
						inc_pc 		<= '1';
						lit_sel 	<= '1';
						wr_z_en 	<= '1';
					
					WHEN "111000" => -- IORLW
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0000";
						inc_pc 		<= '1';
						lit_sel 	<= '1';
						wr_z_en 	<= '1';
					
					WHEN "111010" => -- XORLW
						next_state 	<= fetch_decode;
					
						op_sel 		<= "0010";
						inc_pc 		<= '1';
						lit_sel 	<= '1';
						wr_z_en 	<= '1';
					
					WHEN OTHERS => NULL;
				END CASE;
				
				-- Instruções efetuadas sobre registrador W e Literal
				CASE opcode(5 DOWNTO 1) IS
					WHEN "11111" => -- ADDLW
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1000";
						inc_pc 		<= '1';
						lit_sel 	<= '1';
						wr_z_en 	<= '1';
						wr_c_en 	<= '1';
						wr_dc_en 	<= '1';
					
					WHEN "11110" => -- SUBLW
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1001";
						inc_pc 		<= '1';
						lit_sel 	<= '1';
						wr_z_en 	<= '1';
						wr_dc_en 	<= '1';
						wr_c_en 	<= '1';
					
					WHEN OTHERS => NULL;
				END CASE;
				
				-- Instruções sobre um registrador apenas. Limpar reg, comparar valores
				-- incrementar, decrementar, etc...
				CASE opcode(5 DOWNTO 2) IS
					WHEN "0100" => -- BCF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1100";
						bit_sel 	<= b_bits;
						inc_pc 		<= '1';
						rd_en 		<= '1';
						
					WHEN "0110" => -- BTFSC
						IF b_bits = "000" THEN
							next_state <= fetch_only;
						ELSE
							next_state <= fetch_decode;
							
							op_sel 	<= "1100";
							bit_sel <= b_bits;
							inc_pc 	<= '1';
							rd_en 	<= '1';
						END IF;
					
					WHEN "0101" => -- BSF
						next_state 	<= fetch_decode;
					
						op_sel 		<= "1101";
						bit_sel 	<= b_bits;
						inc_pc 		<= '1';
						rd_en 		<= '1';
						
					WHEN "0111" => -- BTFSS
						IF b_bits = "111" THEN
							next_state <= fetch_only;
						ELSE
							next_state 	<= fetch_decode;
							
							op_sel 		<= "1101";
							bit_sel 	<= b_bits;
							inc_pc 		<= '1';
							rd_en 		<= '1';
						END IF;
						
					WHEN OTHERS => NULL;
				END CASE;
				
				CASE opcode(5 DOWNTO 3) IS
					WHEN "100" => -- CALL
						next_state 	<= fetch_decode;
					
						stack_push 	<= '1';
						load_pc 	<= '1';
					  
					WHEN "101" => -- GOTO
						next_state 	<= fetch_decode;
						load_pc 	<= '1';
					 
					WHEN OTHERS => NULL;
				END CASE;
				
				IF instr = "00000000001000" THEN -- RETURN
					next_state <= fetch_decode;
					stack_pop <= '1';
					
				END if;
		END CASE;
	END PROCESS;

END ARCHITECTURE;
