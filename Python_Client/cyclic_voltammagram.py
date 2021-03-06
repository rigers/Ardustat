from pylab import *
import numpy
import ardustat_library_simple as ard
import time

#set parameters
cycles = 3
min_potential = .2 #V
max_potential = 1.8 #V
rate = 1 #mV/s
read_delay = .5 #second
ardustat_id = 16
file_name = "two_penny_test"
ardustat_socket = 7777
debug = False

#Below here no touchy
#connect to to ardustat and setup resistance table
a = ard.ardustat()
a.connect(ardustat_socket)
a.debug = debug
a.load_resistance_table(ardustat_id)

#create arrays + a function for logging data
times = []
potential = []
current = []
time_start = time.time()
cycle = 0
file_name = file_name+"_"+str(int(time_start))+".dat"
def appender(reading):
	print reading['cell_ADC'],read['current']
	tdiff = str(time.time()-time_start)
	out = tdiff+","+str(reading['cell_ADC'])+","+str(read['current'])+","+str(cycle)+"\n"
	open(file_name,"a").write(out)
	


#Allows cell to settle and picks starting potential based on OCV
output = 0
a.ocv()
for i in range(0,60):
	time.sleep(1)
	read = a.parsedread()
	appender(read)
	output = float(read['cell_ADC'])

#Stepping
while cycle < cycles:
	#Scan Up
	while output < max_potential:	
		step_time = time.time()
		output = output + .005
		a.potentiostat(output)
		while (time.time()-step_time) < (5/rate):
			time.sleep(read_delay)
			read = a.parsedread()
			appender(read)
	#Scan Down
	while output > min_potential:
		step_time = time.time()
		output = output - .005
		a.potentiostat(output)
		while (time.time()-step_time) < (5/rate):
			time.sleep(read_delay)
			read = a.parsedread()
			appender(read)
	#Tick the Cycle
	cycle = cycle +1 
		
#Set to OCV
a.ocv()
