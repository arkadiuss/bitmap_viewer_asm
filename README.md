# Bitmap viewer

Simple bitmap viewer written using only assembly code. 

## Features
- displaying bitmap using vga mode (320 x 200)
- mapping rgb values to custom 64 colors from vga pallette
- moving through the image using arrows
- zooming in and out 
- displaying 8-bits and 24-bits color bitmaps 
- reading file from command line arguments

## Limitations
- displaying only 8-bits and 24-bits color bitmaps 
- images must be larger than 320 x 200 

## Examples
Images comes from: [Source](https://www.fileformat.info/format/bmp/sample/index.htm)  
Original:  
![Alt text](images/land2_original.png?raw=true "Orginal image")  

From viewer:  
![Alt text](images/land2_asm.png?raw=true "Image from viewer")  

From viewer zoomed:  
![Alt text](images/land2_zoomed.png?raw=true "Zoomed image from viewer")  

Original:  
![Alt text](images/land_original.png?raw=true "Orginal image")  

From viewer:  
![Alt text](images/land_asm.png?raw=true "Image from viewer")  

Original:  
![Alt text](images/delta_original.png?raw=true "Orginal image")  

From viewer:  
![Alt text](images/delta_asm.png?raw=true "Image from viewer")  
