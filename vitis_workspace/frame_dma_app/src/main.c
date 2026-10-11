#include "xparameters.h"
#include "xgpio.h"
#include "xaxidma.h"
#include "xil_printf.h"
#include "xstatus.h"

#define GPIO_DEVICE_ID       XPAR_AXI_GPIO_0_DEVICE_ID
#define DMA_DEVICE_ID        XPAR_AXIDMA_0_DEVICE_ID

#define GPIO_BUTTON_CHANNEL  1
#define GPIO_START_CHANNEL   2

#define FRAME_BUFFER_ADDR    0xC0000000U
#define FRAME_SIZE_BYTES     64000U

static XGpio Gpio;
static XAxiDma AxiDma;

int main(void)
{
    int Status;
    u32 ButtonState;

    xil_printf("\r\n--- Frame DMA Application ---\r\n");

    // ------------------------------------------------------------
    // Initialize AXI GPIO
    // ------------------------------------------------------------

    Status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: GPIO initialization failed\r\n");
        return XST_FAILURE;
    }

    // Channel 1 = button input
    XGpio_SetDataDirection(&Gpio, GPIO_BUTTON_CHANNEL, 0xFFFFFFFF);

    // Channel 2 = start output
    XGpio_SetDataDirection(&Gpio, GPIO_START_CHANNEL, 0x00000000);

    // START = 0 initially
    XGpio_DiscreteWrite(&Gpio, GPIO_START_CHANNEL, 0x0);

    // ------------------------------------------------------------
    // Initialize AXI DMA
    // ------------------------------------------------------------

    XAxiDma_Config *CfgPtr;

    CfgPtr = XAxiDma_LookupConfig(DMA_DEVICE_ID);

    if (!CfgPtr) {
        xil_printf("ERROR: No DMA configuration found\r\n");
        return XST_FAILURE;
    }

    Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);

    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: DMA initialization failed\r\n");
        return XST_FAILURE;
    }

    // Scatter-Gather must be disabled
    if (XAxiDma_HasSg(&AxiDma)) {
        xil_printf("ERROR: DMA is configured in SG mode\r\n");
        return XST_FAILURE;
    }

    xil_printf("System initialized\r\n");
    xil_printf("Waiting for button...\r\n");

    // ------------------------------------------------------------
    // Wait for button press
    // ------------------------------------------------------------

    while (1) {

        ButtonState =
            XGpio_DiscreteRead(&Gpio, GPIO_BUTTON_CHANNEL);

        if (ButtonState & 0x1) {
            break;
        }
    }

    xil_printf("Button pressed\r\n");

    // ------------------------------------------------------------
    // Start DMA S2MM transfer
    // ------------------------------------------------------------

    Status = XAxiDma_SimpleTransfer(
        &AxiDma,
        FRAME_BUFFER_ADDR,
        FRAME_SIZE_BYTES,
        XAXIDMA_DEVICE_TO_DMA
    );

    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: DMA transfer start failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("DMA configured for %d bytes\r\n", FRAME_SIZE_BYTES);

    // ------------------------------------------------------------
    // Generate START pulse for frame_rx_axis
    // ------------------------------------------------------------

    XGpio_DiscreteWrite(&Gpio, GPIO_START_CHANNEL, 0x1);

    // Short software pulse
    for (volatile int i = 0; i < 1000; i++);

    XGpio_DiscreteWrite(&Gpio, GPIO_START_CHANNEL, 0x0);

    xil_printf("START pulse generated\r\n");

    // ------------------------------------------------------------
    // Wait for S2MM completion
    // ------------------------------------------------------------

    while (XAxiDma_Busy(
        &AxiDma,
        XAXIDMA_DEVICE_TO_DMA
    )) {
        // wait
    }

    xil_printf("DMA transfer complete\r\n");
    xil_printf("Frame stored at 0x%08X\r\n", FRAME_BUFFER_ADDR);

    while (1);

    return 0;
}
