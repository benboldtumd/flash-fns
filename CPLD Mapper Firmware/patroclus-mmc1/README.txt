
Free open-source implementation of popular MMC1 mapper used in NES cartridges.
By David Senabre Albujer, 2013.
Website:
www.consolasparasiempre.net

Tested succesfully on Xilinx XC9572 CPLD and SNROM PCB.

Files
-----

- mmc1.vhd     :  top level module.
                  Wires-up everything.
- std_reg.vhd  :  generic register with asynchronous reset and enable signal.
                  Used by the four internal registers.
- shift_reg.vhd:  generci shift register with synchornous reset.
                  Used for serial-parallel conversion.
- fsm.vhd      :  finite-state machine.
                  Used for serial-parallel conversion.