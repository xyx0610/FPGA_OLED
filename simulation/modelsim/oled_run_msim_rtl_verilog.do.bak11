transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {e:/myexe/quartus21/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {e:/myexe/quartus21/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {e:/myexe/quartus21/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {e:/myexe/quartus21/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {e:/myexe/quartus21/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cyclone10lp_ver
vmap cyclone10lp_ver ./verilog_libs/cyclone10lp_ver
vlog -vlog01compat -work cyclone10lp_ver {e:/myexe/quartus21/quartus/eda/sim_lib/cyclone10lp_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/spi_writebyte.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/ram_write.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/ram_read.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/oled_show_char.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/oled_init.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/oled_drive.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/rtl {E:/FPGA_Study/MyStudy2/OLED/rtl/clk_fenpin.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/ip {E:/FPGA_Study/MyStudy2/OLED/ip/zm_24.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/ip {E:/FPGA_Study/MyStudy2/OLED/ip/zm_16.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/ip {E:/FPGA_Study/MyStudy2/OLED/ip/zm_12.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED/ip {E:/FPGA_Study/MyStudy2/OLED/ip/ram_show.v}

vlog -vlog01compat -work work +incdir+E:/FPGA_Study/MyStudy2/OLED {E:/FPGA_Study/MyStudy2/OLED/oled_drive_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclone10lp_ver -L rtl_work -L work -voptargs="+acc"  oled_drive_tb

add wave *
view structure
view signals
run 5 sec
