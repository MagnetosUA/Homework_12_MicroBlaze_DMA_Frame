# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\R_D_Homeworks\Homework_12_MicroBlaze_DMA_Frame\vitis_workspace\microblaze_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\R_D_Homeworks\Homework_12_MicroBlaze_DMA_Frame\vitis_workspace\microblaze_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {microblaze_platform}\
-hw {D:\R_D_Homeworks\Homework_12_MicroBlaze_DMA_Frame\design_1_wrapper.xsa}\
-proc {microblaze_0} -os {standalone} -out {D:/R_D_Homeworks/Homework_12_MicroBlaze_DMA_Frame/vitis_workspace}

platform write
platform generate -domains 
platform active {microblaze_platform}
platform config -updatehw {D:/R_D_Homeworks/Homework_12_MicroBlaze_DMA_Frame/design_1_wrapper.xsa}
platform generate
platform config -updatehw {D:/R_D_Homeworks/Homework_12_MicroBlaze_DMA_Frame/design_1_wrapper.xsa}
platform generate -domains 
platform clean
platform clean
platform generate
platform config -updatehw {D:/R_D_Homeworks/Homework_12_MicroBlaze_DMA_Frame/design_1_wrapper.xsa}
platform generate -domains 
platform clean
platform clean
platform generate
