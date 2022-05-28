#ifndef DPI_C__PROJECTS_DE2_115_TBS_CPU86_GOLDEN_REF_CPU86_E8086_TB_H
#define DPI_C__PROJECTS_DE2_115_TBS_CPU86_GOLDEN_REF_CPU86_E8086_TB_H

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif

DPI_DLLISPEC void VerilogDPIExpInitCall( const char* _subprogram_name, const char* _description, ... );

static void dpi_print(const char* _msg)
{
	VerilogDPIExpInitCall("dpi_print","ISU.",_msg);
}

#ifdef __cplusplus
}
#endif
#endif
