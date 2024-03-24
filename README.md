# Sunlight Glasses inspired by Dr. Andrew Huberman

![Sunlight Glasses](/sunlight_glasses_close_up.jpg)

Dr. Andrew Huberman is really big on sunlight exposure. It has positive effects on mood, sleep, cognition and so much more. In an interview with Dr. Peter Attia, Huberman said it would be great if there was an invention to let the user know when they have achieved enough sunlight during the day. Furthermore, notify them if they are looking at too much light at nighttime.

This gadget is built to do just that. Inside of these 3D printed glasses frame I created a custom PCB using the NRF52. 

![Sunlight Glasses PCB](/sunlight_glasses_pcb.jpg)
![Sunlight Glasses Wiring](/sunlight_glasses_inside_frame.jpg)

It reads ambient light from the VEML7700 located in between the eyes of the frame and sends it via BLE to an IOS app. (I make use of the Environmental Sensing Service profile and Perceived Light Characteristic).

![Sunlight Glasses App](/sunlight_glasses_app.jpg)

The IOS app receives the ambient light value every second and calculates the average once per minute. It then tells you how many total LUX that you have received. Furthermore, given the total lux it will tell you how many minutes it would take to reach 100K LUX given the current LUX.

## Links:
YouTube Video: https://www.youtube.com/watch?v=xIHv9QHtEUs

Detailed Blog Post: https://www.bennettnotes.com/projects/sunlight_glasses_inspired_by_andrew_huberman/