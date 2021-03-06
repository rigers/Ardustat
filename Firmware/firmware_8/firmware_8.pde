/*#define DATAOUT 11//MOSI
#define DATAIN 12//MISO - not used, but part of builtin SPI
#define SPICLOCK  13//sck
#define SLAVESELECTD 10//ss
#define SLAVESELECTP 7//ss
#define RELAYPIN 3
#define LED 5
#define LEDGND 6
#define CLPIN 2*/
//If you are using a version 8 ardustat, comment out the above lines and uncomment the following:
#define DATAOUT 12//MOSI
#define DATAIN 11//MISO - not used, but part of builtin SPI
#define SPICLOCK 10//sck
#define SLAVESELECTD 13//ss
#define SLAVESELECTP 3//ss
#define RELAYPIN 4
#define LED 2
#define LEDGND 1
#define CLPIN 5

int adc;    //out of pot
int dac;    //out of main dac
int adcgnd; //adc at ground
int adcref; //ref electrode
int refvolt;//ref voltage 2.5V
int firstdac= 0;
int seconddac = 0;
int dacaddr = 0;
int dacmode=3;
boolean dactest = false;
boolean rtest = false;
int testcounter = 0;
int testlimit = 0;
int outvolt=1023;
byte pot= 0;
int temp;
byte resistance1=0;
int res=0;
int fixedres=0;
int cl=CLPIN;
int pdl = 4;
int counter = 0;
int sign = 1;
int waiter = 0;
int mode = 1;  //tells computer what's what
int pMode = 0; //saved variable to remember if the last mode was pstat or not
int lastData[10]; //previous error values for use in pstat's PID algorithm
int dacrun;
int adcrun;
int resmove;


//Serial Comm Stuff
int incomingByte;
boolean setVoltage;
char serInString[100];
char sendString[99];
char holdString[5];
//int adcArray[100];
//int adcArrayCounter = 0;
int output;
boolean whocares = false;
boolean positive = false;
boolean gstat = false;
boolean pstat = false;
boolean ocv = true;
boolean cv = false;
int dactoset = 0;
int setting = 0;
int speed = 100;
int countto = 0;
byte clr;


void setup()
{


  //Startup Serial
  Serial.begin(57600);
  //SPI
  byte i;
  //byte clr;
  pinMode(DATAOUT, OUTPUT);
  pinMode(RELAYPIN,OUTPUT);
  pinMode(DATAIN, INPUT);
  pinMode(SPICLOCK,OUTPUT);
  pinMode(SLAVESELECTD,OUTPUT);
  pinMode(LED,OUTPUT);
  pinMode(LEDGND,OUTPUT);
  pinMode(SLAVESELECTP,OUTPUT);
  pinMode(cl, OUTPUT);
  digitalWrite(SLAVESELECTD,HIGH); //disable device
  digitalWrite(SLAVESELECTP,HIGH); //disable device
  digitalWrite(cl, LOW);
  delay(1000);
  digitalWrite(cl,HIGH);
  //SPCR is 01010000.  write_pot turns off the SPI interface,
  // which means SPCR becomes 00010000 temporarily
  //SPCR = (1<<SPE)|(1<<MSTR);
  SPCR = B00010000;
  clr=SPSR;
  clr=SPDR;
  delay(10);
  // power on reset
  pot=144;
  resistance1=0;
  res=0;
  write_pot(pot,resistance1,res);
  // wakeup
  pot=B00010000;
  write_pot(pot,resistance1,res);
  // set resistance to High
  pot=B01000000;
  resistance1=B00000000;
  res=255;
  write_pot(pot,resistance1,res);
  for (int i=1;i<11;i++) lastData[i]=0;
}

void loop()
{

  //read the serial port and create a string out of what you read
  readSerialString(serInString);
  if( isStringEmpty(serInString) == false) { //this check is optional

    //delay(500);
    holdString[0] = serInString[0];
    holdString[1] = serInString[1];
    holdString[2] = serInString[2];
    holdString[3] = serInString[3];
    holdString[4] = serInString[4];

    //try to print out collected information. it will do it only if there actually is some info.
    if (serInString[0] == 43 || serInString[0] == 45 || serInString[0] == 114 || serInString[0] == 103 || serInString[0] == 112|| serInString[0] == 80 ||  serInString[0] == 82 || serInString[0] == 99 || serInString[0] == 100 || serInString[0] == 88)
    {
      if (serInString[0] == 43) positive = true; //"+"
      else if (serInString[0] == 45) positive = false; //"-"
      pstat = false;
      if (serInString[0] != 114) gstat = false;
      dactest = false;
      rtest = false;
      ocv = false;
      sign = 1;
      for (int i = 0; i < 98; i++)
      {
        sendString [i] = serInString[i+1];
      }
      int out = stringToNumber(sendString,4);
      if (serInString[0] != 112) //"p"
      {
        pMode = 0;
      }
      
      if (serInString[0] == 43) //"+"
      {
        outvolt = out;
        send_dac(0,outvolt);
        digitalWrite(RELAYPIN,HIGH);
      }
      
      if (serInString[0] == 100) //"d"
      {
        outvolt = out;
        send_dac(1,outvolt);
        digitalWrite(RELAYPIN,HIGH);
      }
      
      if (serInString[0] == 45) //"-"
      {
        ocv = true;
        digitalWrite(RELAYPIN,LOW);
      }

      if (serInString[0] == 80) //"P"
      {
        dactest = true;
        testcounter = 0;
        testlimit = 1023;
      }

      if (serInString[0] == 82) //"R"
      {
        rtest = true;
        testcounter = 0;
        testlimit = 255;
      }

      if (serInString[0] == 114) //"r"
      {
        res = out;
        write_pot(pot,resistance1,res);
      }

      if (serInString[0] == 103) //"g"
      {
        dacon();
        gstat = true;

        outvolt = analogRead(0);
        send_dac(0,outvolt);
        if (out >= 2000)
        {
          out = out - 2000;
          sign = -1;
        }
        else if (out < 2000)
        {
          out = out;
          sign = 1;
        }

        setting = out;
        outvolt = analogRead(0)+(sign*out);
        send_dac(0,outvolt);

        digitalWrite(RELAYPIN,HIGH);

      }
      
      if (serInString[0] == 112) //"p"
      {
        if (pMode == 0)
        {
          dacon();
        }
        pstat = true;
        pMode = 1;
        setting = out;
        digitalWrite(RELAYPIN,HIGH);
        send_dac(0,setting);
      }

      if (serInString[0] == 99) //"c"
      {
        pstat = true;
        setting = out;
        dacon();
        digitalWrite(RELAYPIN,HIGH);
      }
      //New command: If X0000-X1023, set DAC 0, if X2000-X3023, set DAC 1
      if (serInString[0] == 88) //"X"
      {
        if (out >= 2000)
        {
          out = out - 2000;
          dactoset = 1;
          send_dac(0,0);
        }
        else if (out < 2000)
        {
          out = out;
          dactoset = 0;
          send_dac(1,0);
        }
        outvolt = out;
        send_dac(dactoset,outvolt);
        digitalWrite(RELAYPIN,HIGH);
      }
    }

    else if (serInString[0] == 32) //Space
    {
      digitalWrite(LED,HIGH);
      digitalWrite(LEDGND,LOW);
      delay(100);
      digitalWrite(LED,LOW);
      digitalWrite(LEDGND,LOW);

    }
    
    else if (serInString[0] == 115) //"s"
    {
      sendout();
    }


    flushSerialString(serInString);
  }



  //Work Section
  if (pstat) potentiostat();
  if (gstat) galvanostat();
  //if (cv)
  if (dactest) testdac();
  if (rtest) testr();
  delay(speed);
  counter++;
  adcrun = adc + adcrun;
  dacrun = dac + dacrun;
  if (counter > countto)
  {

    dac = dacrun/counter;

    adc = adcrun/counter;

    counter = 0;
    adcrun =0;
    dacrun = 0;

  } 

}


char spi_transfer(volatile char data)
{
  SPDR = data;                    // Start the transmission
  while (!(SPSR & (1<<SPIF)))     // Wait the end of the transmission
  {
  };
  return SPDR;                    // return the received byte
}

byte send_dac(int address, int value)
{
  if (value > 1023)
  {
    value = 1023;
  }
  byte val2 = (value >> 8) & 0x03;
  byte val1 = (value >> 2)& 255;

  digitalWrite(SLAVESELECTP, HIGH);
  digitalWrite(SLAVESELECTD, LOW);
  delayMicroseconds(10);
  if (address==0){
    for (int i=0;i<2;i++){
      sendBit(false);
    }
         
    for (int i=0;i<2;i++){
      sendBit(true);
    }
  }
  else if(address==1){
          
    sendBit(LOW);
    sendBit(HIGH);
      
    for (int i=0;i<2;i++){
      sendBit(true);
    }  
  }
  //2 byte opcode
  //spi_transfer(firstdac);
  sendBit(HIGH && (val1 & B10000000));
  sendBit(HIGH && (val1 & B01000000));
  sendBit(HIGH && (val1 & B00100000));
  sendBit(HIGH && (val1 & B00010000));
  sendBit(HIGH && (val1 & B00001000));
  sendBit(HIGH && (val1 & B00000100));
  sendBit(HIGH && (val1 & B00000010));
  sendBit(HIGH && (val1 & B00000001));
  //spi_transfer(seconddac);
  sendBit(HIGH && (val2 & B00000010));
  sendBit(HIGH && (val2 & B00000001));
      
  for (int i=0;i<2;i++){
    sendBit(false);
  }
  digitalWrite(SLAVESELECTD,HIGH); //release chip, signal end transfer
}

byte dacoff()
{
  SPCR = B01010000;
  firstdac = (3 << 6) ;
  seconddac = 0;
  digitalWrite(SLAVESELECTD,LOW);
  //2 byte opcode
  spi_transfer(firstdac);
  spi_transfer(seconddac);
  digitalWrite(SLAVESELECTD,HIGH); //release chip, signal end transfer
  //delay(3000);*/
  SPCR = B00010000;
}

byte dacon()
{
  SPCR = B01010000;
  firstdac = (1 << 6) ;
  seconddac = 0;
  digitalWrite(SLAVESELECTD,LOW);
  //2 byte opcode
  spi_transfer(firstdac);
  spi_transfer(seconddac);
  digitalWrite(SLAVESELECTD,HIGH); //release chip, signal end transfer
  //delay(3000);*/
  SPCR = B00010000;
}

byte write_pot(int address, int value1, int value2)
{
  /*digitalWrite(SLAVESELECTP,LOW);
  //3 byte opcode
  spi_transfer(address);
  spi_transfer(value1);
  spi_transfer(value2);
  digitalWrite(SLAVESELECTP,HIGH);*/ //release chip, signal end transfer
  sendValue(0,255-value2);
}



//Below Here is Serial Comm Shizzle (for rizzle)

//utility function to know wither an array is empty or not
boolean isStringEmpty(char *strArray) {
  if (strArray[0] == 0) {
    return true;
  }
  else {
    return false;
  }
}

//Flush String
void flushSerialString(char *strArray) {
  int i=0;
  if (strArray[i] != 0) {
    while(strArray[i] != 0) {
      strArray[i] = 0;                  // optional: flush the content
      i++;
    }
  }
}

//Read String In
void readSerialString (char *strArray) {
  int i = 0;
  if(Serial.available()) {
    //Serial.println("    ");  //optional: for confirmation
    while (Serial.available()){
      strArray[i] = Serial.read();
      i++;

    }
  }
}

int stringToNumber(char thisString[], int length) {
  int thisChar = 0;
  int value = 0;

  for (thisChar = length-1; thisChar >=0; thisChar--) {
    char thisByte = thisString[thisChar] - 48;
    value = value + powerOfTen(thisByte, (length-1)-thisChar);
  }
  return value;
}

/*
 This method takes a number between 0 and 9,
 and multiplies it by ten raised to a second number.
 */

long powerOfTen(char digit, int power) {
  long val = 1;
  if (power == 0) {
    return digit;
  }
  else {
    for (int i = power; i >=1 ; i--) {
      val = 10 * val;
    }
    return digit * val;
  }
}

int resgainer(int whatitis, int whatitshouldbe)
{
      //int move = 0;
      int move = 1;
      //int diff = abs(whatitis-whatitshouldbe); 
      //if (diff > 20) move = 20;
      //else move = 1;
      //move = constrain(move,1,100);
      return move;
} 

void potentiostat()
{
  //read in values
  adc = analogRead(0);
  dac = analogRead(1);
  int refelectrode = analogRead(3);
  int diff_adc_ref = adc - refelectrode;
  float err = setting - diff_adc_ref;  
  int move = 0;
  for (int i=2;i<=11;i++) lastData[i-1]=lastData[i];
  lastData[10] = err;
  //PID
  float p = 1*err;
  float i = 0;
  float d = 0;
  move = int(p+i+d);
  outvolt = outvolt + move;

  if (outvolt>1023)
  {
    res = res - (outvolt-1023)/1024.*255./2;
    outvolt = 1023;
    //res = res-res/6;
    if (res<0) res=0;
  }else if (outvolt<0){
    res = res+(outvolt+(lastData[10]-lastData[9]))/1024.*255.;
    outvolt = 20;
    //res = res - res/6;
    if (res<0) res=0;
  }
  if (abs(outvolt-diff_adc_ref)<100){
    res = res + abs(outvolt-diff_adc_ref)/10.;
    if (res>255) res = 255;
  }
  write_pot(0,resistance1,res);
  send_dac(0,outvolt);

  /* //if potential is too high
  if ((diff_adc_ref > setting) && (outvolt > 0))
  {
    move = gainer(diff_adc_ref,setting);
    outvolt=outvolt-move;
    write_dac(0,outvolt);

  }

  //if potential is too low
  else if ((diff_adc_ref < setting) && (outvolt < 1023))
  {
    move = gainer(diff_adc_ref,setting);
    outvolt=outvolt+move;
    write_dac(0,outvolt);
  }

  // if range is limited decrease R
  if ((outvolt > 1022) && (res > 0))
  {
    outvolt = 1000;
    write_dac(0,outvolt);
    resmove = resgainer(adc,setting);
    res = res - resmove;
    write_pot(pot,resistance1,res);

  }
  else if ((outvolt < 1) && (res > 0))
  {
    outvolt = 23;
    write_dac(0,outvolt);
    resmove = resgainer(adc,setting);
    res = res - resmove;
    write_pot(pot,resistance1,res);
    delay(waiter);
  }

  //if range is truncated increase R
  int dude = abs(dac-adc);
  if ((dude < 100) && (res < 255))
  {
    res = res+1;
    write_pot(pot,resistance1,res);
    delay(waiter);
  }*/

}

void galvanostat()
{
  //get values
  adc = analogRead(0);
  dac = analogRead(1);

  int move = 1;
  int diff = 0;


  //if charging current
  if (sign > 0)
  {
    diff = dac - adc;
    //if over current step dac down
    if( ((diff) > (setting)) && (outvolt > 0))
    {
     
      move = gainer(diff,setting);
      outvolt = outvolt-move;
      send_dac(0,outvolt);
    }

    //if under current step dac up
    if (((diff) <(setting)) && (outvolt < 1023))
    {
      move = gainer(diff,setting);
      outvolt = outvolt+move;
      send_dac(0,outvolt);

    }
  }

  //if discharge current
  if (sign < 0)
  {
    diff = adc - dac;
    //if over current step dac up
    if( (diff) > (setting) && (outvolt < 1023))
    {
      move = gainer(diff,setting);
      outvolt =outvolt+move;
      send_dac(0,outvolt);
    }

    //if under current step dac down
    if ((diff) < (setting) && (outvolt > 0))
    {
      move = gainer(diff,setting);
      outvolt = outvolt-move;
      send_dac(0,outvolt);

    }
  }
  
  if (outvolt < 0)
  {
    outvolt = 0;
    send_dac(0,outvolt);
  }
  if (outvolt > 1023)
  {
    outvolt = 1023;
    send_dac(0,outvolt);
  }
}

void sendout()
{
  adc = analogRead(0);
  dac = analogRead(1);
  adcgnd = analogRead(2);
  adcref = analogRead(3);
  refvolt = analogRead(5);
  if (pstat) mode = 2;
  else if (gstat) mode = 3;
  else if (ocv) mode = 1;
  else if (dactest) mode = 4;
  else mode = 0;
  int setout = sign*setting;
  Serial.print("GO,");
  Serial.print(outvolt,DEC);
  Serial.print(",");
  Serial.print(adc);
  Serial.print(",");
  Serial.print(dac);
  Serial.print(",");
  Serial.print(res);
  Serial.print(",");
  Serial.print(setout);
  Serial.print(",");
  Serial.print(mode);
  Serial.print(",");
  Serial.print(holdString[0]);
  Serial.print(holdString[1]);
  Serial.print(holdString[2]);
  Serial.print(holdString[3]);
  Serial.print(holdString[4]);
  Serial.print(",");
  Serial.print(adcgnd);
  Serial.print(",");
  Serial.print(adcref);
  Serial.print(",");
  Serial.print(refvolt);
  Serial.println(",ST");
}

void testdac ()
{
  digitalWrite(RELAYPIN,LOW);
  send_dac(0,testcounter);
  outvolt = testcounter;
  testcounter = testcounter + 1;
  if (testcounter > testlimit) testcounter = 0;
}

void testr ()
{
  digitalWrite(RELAYPIN,HIGH);
  send_dac(0,1023);
  outvolt = 1023;
  res = testcounter;
  write_pot(pot,resistance1,res);
  testcounter = testcounter + 1;
  if (testcounter > testlimit) testcounter = 0;

}

int gainer(int whatitis, int whatitshouldbe)
{
      int move = abs(whatitis-whatitshouldbe);
      move = constrain(move,1,100);
      return move;
}

//Barry's hacky functions

byte value;

byte sendBit(boolean state)
{
  digitalWrite(SPICLOCK,LOW);
  delayMicroseconds(10);
  digitalWrite(DATAOUT,state);
  digitalWrite(SPICLOCK,HIGH);
  delayMicroseconds(10);
}

byte sendValue(int wiper, int val)
//tested cycle time for this function is ~565 microseconds.
{
  value =  byte(val);
  //digitalWrite(SPICLOCK,LOW);
  //digitalWrite(DATAOUT,LOW);
  digitalWrite(SLAVESELECTP,LOW);
  delayMicroseconds(10);
  
  //Select wiper
  for(int i=0;i<3;i++){
    sendBit(false);
  }
  sendBit(wiper);
  
  //write command
  for(int i=0;i<4;i++){
    sendBit(false);
  }
  //data
  sendBit(HIGH && (value & B10000000));
  sendBit(HIGH && (value & B01000000));
  sendBit(HIGH && (value & B00100000));
  sendBit(HIGH && (value & B00010000));
  sendBit(HIGH && (value & B00001000));
  sendBit(HIGH && (value & B00000100));
  sendBit(HIGH && (value & B00000010));
  sendBit(HIGH && (value & B00000001));
  //sendBit(true);  //fudge
  digitalWrite(SLAVESELECTP,HIGH);
  //Serial.println(in);
  delayMicroseconds(10);
}

byte readWiper()
{
  //send read command
  digitalWrite(SLAVESELECTP,LOW);
  delayMicroseconds(10);
  sendBit(false);
  sendBit(false);
  sendBit(false);
  sendBit(false);
  sendBit(true);
  sendBit(true);
  
  //get data
  int data[9];
  Serial.print("  ");
  for(int i=0;i<9;i++)
  {
    digitalWrite(SPICLOCK,LOW);
    delayMicroseconds(10);
    digitalWrite(DATAOUT,LOW);
    delayMicroseconds(10);
    data[i] = digitalRead(DATAIN);
    digitalWrite(SPICLOCK,HIGH);
    delayMicroseconds(10);
    Serial.print(data[i]);
  }
  digitalWrite(SLAVESELECTP,HIGH);
}
