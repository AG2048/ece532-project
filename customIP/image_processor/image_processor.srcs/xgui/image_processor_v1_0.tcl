# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BLOCK_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BUFFER_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_AXIS_TDATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FILTER_FRACT_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FILTER_INT_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INPUT_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RESULT_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.BLOCK_SIZE { PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to update BLOCK_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BLOCK_SIZE { PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to validate BLOCK_SIZE
	return true
}

proc update_PARAM_VALUE.BUFFER_HEIGHT { PARAM_VALUE.BUFFER_HEIGHT } {
	# Procedure called to update BUFFER_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BUFFER_HEIGHT { PARAM_VALUE.BUFFER_HEIGHT } {
	# Procedure called to validate BUFFER_HEIGHT
	return true
}

proc update_PARAM_VALUE.C_AXIS_TDATA_WIDTH { PARAM_VALUE.C_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXIS_TDATA_WIDTH { PARAM_VALUE.C_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_AXIS_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.FILTER_FRACT_BITS { PARAM_VALUE.FILTER_FRACT_BITS } {
	# Procedure called to update FILTER_FRACT_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FILTER_FRACT_BITS { PARAM_VALUE.FILTER_FRACT_BITS } {
	# Procedure called to validate FILTER_FRACT_BITS
	return true
}

proc update_PARAM_VALUE.FILTER_INT_BITS { PARAM_VALUE.FILTER_INT_BITS } {
	# Procedure called to update FILTER_INT_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FILTER_INT_BITS { PARAM_VALUE.FILTER_INT_BITS } {
	# Procedure called to validate FILTER_INT_BITS
	return true
}

proc update_PARAM_VALUE.INPUT_HEIGHT { PARAM_VALUE.INPUT_HEIGHT } {
	# Procedure called to update INPUT_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INPUT_HEIGHT { PARAM_VALUE.INPUT_HEIGHT } {
	# Procedure called to validate INPUT_HEIGHT
	return true
}

proc update_PARAM_VALUE.RESULT_WIDTH { PARAM_VALUE.RESULT_WIDTH } {
	# Procedure called to update RESULT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESULT_WIDTH { PARAM_VALUE.RESULT_WIDTH } {
	# Procedure called to validate RESULT_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.RESULT_WIDTH { MODELPARAM_VALUE.RESULT_WIDTH PARAM_VALUE.RESULT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESULT_WIDTH}] ${MODELPARAM_VALUE.RESULT_WIDTH}
}

proc update_MODELPARAM_VALUE.BLOCK_SIZE { MODELPARAM_VALUE.BLOCK_SIZE PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BLOCK_SIZE}] ${MODELPARAM_VALUE.BLOCK_SIZE}
}

proc update_MODELPARAM_VALUE.C_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_AXIS_TDATA_WIDTH PARAM_VALUE.C_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.FILTER_INT_BITS { MODELPARAM_VALUE.FILTER_INT_BITS PARAM_VALUE.FILTER_INT_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FILTER_INT_BITS}] ${MODELPARAM_VALUE.FILTER_INT_BITS}
}

proc update_MODELPARAM_VALUE.FILTER_FRACT_BITS { MODELPARAM_VALUE.FILTER_FRACT_BITS PARAM_VALUE.FILTER_FRACT_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FILTER_FRACT_BITS}] ${MODELPARAM_VALUE.FILTER_FRACT_BITS}
}

proc update_MODELPARAM_VALUE.BUFFER_HEIGHT { MODELPARAM_VALUE.BUFFER_HEIGHT PARAM_VALUE.BUFFER_HEIGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BUFFER_HEIGHT}] ${MODELPARAM_VALUE.BUFFER_HEIGHT}
}

proc update_MODELPARAM_VALUE.INPUT_HEIGHT { MODELPARAM_VALUE.INPUT_HEIGHT PARAM_VALUE.INPUT_HEIGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INPUT_HEIGHT}] ${MODELPARAM_VALUE.INPUT_HEIGHT}
}

