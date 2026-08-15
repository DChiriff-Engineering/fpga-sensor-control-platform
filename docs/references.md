# Technical References

Primary/vendor sources used to define the baseline implementation:

1. **Terasic DE10-Lite product/resources page**  
   `https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1021&PartNo=4`

2. **Terasic DE10-Lite download index / System CD**  
   `https://download.terasic.com/downloads/cd-rom/de10-lite/`

3. **Analog Devices ADXL345 product page and Rev. G data sheet**  
   `https://www.analog.com/en/products/adxl345.html`

4. **Analog Devices AN-1077 — ADXL345 Quick Start Guide**  
   `https://www.analog.com/en/resources/app-notes/an-1077.html`

5. **Intel MAX 10 design guidance**  
   `https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-guidance/max-10.html`

6. **Intel Quartus Prime resources**  
   `https://www.intel.com/content/www/us/en/products/details/fpga/development-tools/quartus-prime/resource.html`

## Source-control policy

Terasic's official Golden Top project is used as the physical pin-assignment authority during local hardware setup. This repository does not copy vendor demo RTL or redistribute a vendor QSF; the import script consumes the user's locally downloaded official QSF and transfers only assignments for ports used by this project.
