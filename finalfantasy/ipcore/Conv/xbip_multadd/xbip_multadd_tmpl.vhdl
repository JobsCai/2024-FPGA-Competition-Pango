-- Created by IP Generator (Version 2022.1 build 99559)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT xbip_multadd
  PORT (
    a0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    a1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    b0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    b1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    ce : IN STD_LOGIC;
    p : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : xbip_multadd
  PORT MAP (
    a0 => a0,
    a1 => a1,
    b0 => b0,
    b1 => b1,
    clk => clk,
    rst => rst,
    ce => ce,
    p => p
  );
