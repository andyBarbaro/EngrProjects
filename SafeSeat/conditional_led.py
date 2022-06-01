#!/usr/bin/env python
# -*- coding: utf-8 -*-

import Adafruit_DHT as dht
import time
import RPi.GPIO as GPIO
import FONA_Code
import os

is_window_up = True
STEPS = 768

def raise_window():
        global is_window_up
        if is_window_up == False:
                for i in range(STEPS):
                        for halfstep in range(8):
                                for pin in range(4):
                                        GPIO.output(motor_pins_reverse[pin], seq[halfstep][pin])
                                time.sleep(0.001)
        is_window_up = True

def lower_window():
        global is_window_up
        if is_window_up == True:
                for i in range(STEPS):
                        for halfstep in range(8):
                                for pin in range(4):
                                        GPIO.output(motor_pins[pin], seq[halfstep][pin])
                                time.sleep(0.001)
        is_window_up = False

def get_lat_long(fona):
        fona.start_gps()
        try:
                GPS_time = time.time()
                while (time.time() - GPS_time)<180:
                        time.sleep(10)
                        coordinates = fona.read_gps()
                        second_item = coordinates[1]
                        second_item_list = second_item.split(',')
                        latitude = second_item_list[3]
                        longitude = second_item_list[4]
                        spaced_latitude = (latitude[0:3] + " ".join(latitude[3:]))
                        spaced_longitude = (longitude[0:4] + " ".join(longitude[4:]))
                        print(latitude)
                        if not (latitude == ''):
                                print('FOUND YOU!! :)')
                                return (latitude, longitude, spaced_latitude, spaced_longitude)
                set_latitude1 = '39.756461'
                set_longitude1 = '-84.190013'
                set_latitude2 = '39.7 5 6 4 6 1'
                set_longitude2 = '-84.1 9 0 0 1 3'
                print('GAVE UP :(')
                return(set_latitude1, set_longitude1, set_latitude2, set_longitude2)
        finally:
                fona.stop_gps()
                print('GPS Turned Off')


if __name__ == "__main__":
        fona = FONA_Code.FONA()
        #clockwise/up
        motor_pins = [19,13,6,20]
        #counterclockwise/down
        motor_pins_reverse = [20,6,13,19]
        
        GPIO.setmode(GPIO.BCM)

        for pin in motor_pins:
                GPIO.setup(pin, GPIO.OUT)
                GPIO.output(pin, GPIO.LOW)

        GPIO.setup(5, GPIO.IN)
        GPIO.setup(4, GPIO.IN)
        GPIO.setup(16, GPIO.OUT)
        GPIO.setup(26, GPIO.OUT)
        GPIO.setup(17, GPIO.OUT)
        GPIO.setup(23, GPIO.IN)
        GPIO.setup(21, GPIO.IN)

        GPIO.output(26, GPIO.LOW)
        GPIO.output(16, GPIO.LOW)
        GPIO.output(17, GPIO.HIGH)

        seq = [ [1,0,0,0],
		[1,1,0,0],
		[0,1,0,0],
		[0,1,1,0],
		[0,0,1,0],
		[0,0,1,1],
		[0,0,0,1],
		[1,0,0,1] ]

        while 1:

                if (GPIO.input(23) == True and GPIO.input(21) == True):
                        GPIO.output(16, GPIO.HIGH)
                else:
                        GPIO.output(16, GPIO.LOW)

                if GPIO.input(4) == False:
                        print('Car turned off')
                        humidity, temperature = dht.read_retry(dht.DHT11, 5)
                        init_temp = temperature
                        print('Initial temperature is: ' + '%0.1f'% init_temp + '°')

                        start_time = time.time()

                        time.sleep(2)
                        
                        if (GPIO.input(23) == True and GPIO.input(21) == True):
                                for i in range(3):	
                                        GPIO.output(17, GPIO.LOW)
                                        time.sleep(0.25)
                                        GPIO.output(17, GPIO.HIGH)
                                        time.sleep(0.25)

                        has_sent_SMS = False
                        time_SMS = False


                        while GPIO.input(4) == False:
                        
                                if (GPIO.input(23) == True and GPIO.input(21) == True):
                                        
                                        humidity, temperature = dht.read_retry(dht.DHT11, 5)
                                        print 'Temp={0:0.1f}°'.format(temperature)

                                        temp_dif = (temperature - init_temp)

                                        GPIO.output(16, GPIO.HIGH)

                                        if (temperature >= 37.8 or temp_dif >= 8):
                                                GPIO.output(26, GPIO.HIGH)
                                                GPIO.output(17, GPIO.LOW)
                                                print ("Button Pressed and it's getting hot in here!!")
                                                time.sleep(0.5)
                                                if not has_sent_SMS:
                                                        lower_window()
                                                        
                                                        print('Sending Message...')
                                                        coordinates = get_lat_long(fona)
                                                        message = 'This is an emergency alert from SafeSeat.\n\nYour child has been left alone in a closed vehicle. Please return to the vehicle immediately.\n\nSafeSeat emergency procedures are underway. A 911 emergency has been issued and the vehicle\'s windows have been lowered.\n\nPlease return to your vehicle immediately.\n\nSee location of emergency in the map below.\n https://maps.google.com/maps?q={},{}'
                                                        print(fona.send_SMS('19377168400',
                                                                            message.format(coordinates[0],
                                                                                            coordinates[1])))
                                                        time.sleep(50)
                                                        print('Placing call')
                                                        place_call = fona.call_911('19377168400')
                                                        time.sleep(15)
                                                        print(coordinates[0], coordinates[1])
                                                        os.system('flite --setf duration_stretch=1.7 --setf int_f0_target_mean=155.0 --setf int_f0_target_stddev=5.0 "This is an emergency message from the Safe Seat alert system. A child has been left in a car with conditions near one hundred ten degrees.  There is risk of harm to the child. Please listen to the exact location. The child is located at the following G P S location. Latitude:' + coordinates[2] + 'and longitude:' + coordinates[3] + ' Again, the G P S location is Latitude:' + coordinates[2] + ' and Longitude:' + coordinates[3] + 'A Safe Seat emergency has been issued. End Message"')
                                                        terminate_call = fona.end_call()
                                                        #fona.close()
                                                        has_sent_SMS = True

                                        else:
                                                GPIO.output(26, GPIO.LOW)
                                                GPIO.output(17, GPIO.HIGH)
                                                print ("Button pressed, but it's cool as a cucumber!")
                                                time.sleep(0.5)

                                        if time.time()-start_time>30:
                                                if (not time_SMS) and (not has_sent_SMS):
                                                        print('Sending Time Activated Message...')
                                                        message2 = 'This is a SafeSeat Alert.\nThere may be a child left unattended in your vehicle.\nPlease return before emergency procedures are intitiated.'
                                                        print(fona.send_SMS('19377168400', message2))
                                                        #fona.close()
                                                        time_SMS = True

                                else:
                                        GPIO.output(26, GPIO.LOW)
                                        GPIO.output(16, GPIO.LOW)
                                        GPIO.output(17, GPIO.HIGH)

                else:
                        if is_window_up == False:
                                raise_window()
                                is_window_up = True

                        if (GPIO.input(23) == True and GPIO.input(21) == False):
                                GPIO.output(17, GPIO.LOW)
                                time.sleep(2)
                                GPIO.output(17, GPIO.HIGH)
                                time.sleep(10)
