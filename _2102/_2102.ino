#include <Wire.h>
#include "math.h"
#include <StandardCplusplus.h>
#include <vector>
#include <string>
#include <iterator>
#include "Adafruit_LEDBackpack.h"
#include "Adafruit_GFX.h"
using namespace std;

Adafruit_8x8matrix matrixLeft= Adafruit_8x8matrix();
Adafruit_8x8matrix matrixRight = Adafruit_8x8matrix();
const int MAX_WAITTIME = 1000;
const int led_red = 11;
const int led_blue = 10;
const int led_green= 9;
const int magnet_analog = 5;
const int magnet_digital = 8;
const int treshold_color = 20;
const int treshold_magnet = 5;
const int magnet_values = 5;
int magnetValue;
String textMessage = "Test";
vector<int> intens_magnet;
int intens_red, intens_blue, intens_green, sensorV;
unsigned long transmissionTime;
const  byte numOfIncomingBytes = 64;
const  byte matrixWidth = 8;
//char-Array needed, cause byte-array isn't accepted by the method readBytesUntil()
char drawingPixels [] = {
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 1, 
  };

boolean isFound = false;
char character;
//x and y-indices for the loops in writeBitmap()
byte yIndex, xIndex;
//x-Position for the horizontal run of text and image (used in writeBitmap AND writeText)
int8_t xPos;

void setup(){
  Serial.begin(9600);
  Serial.setTimeout(1000);
  initializeIO();
  initializeMatrix();
}

void initializeIO(){
  pinMode(led_red, OUTPUT);
  pinMode(led_blue, OUTPUT);
  pinMode(led_green, OUTPUT);
  pinMode(magnet_digital, INPUT);
}

void initializeMatrix(){
  matrixLeft.begin(0x70);  
  matrixRight.begin(0x71); 
  matrixLeft.setTextWrap(false);
  matrixRight.setTextWrap(false);
  matrixLeft.setRotation(2);
  matrixRight.setRotation(2);
}

void loop(){
  delay(100);
  if(isMagnetDetected()){
    if(isFound){
      checkSerial();
      notifyProcessing();
      computeOutput();
    }else {
    blinkLamps();
    computeIntensity();
    }
  }
  /*
  checkSerial();
  computeOutput();
  */
}

boolean isMagnetDetected(){
  magnetValue = analogRead(magnet_analog);
  manageMagnetValues(magnetValue);
  magnetValue = getAvgMagnetValue();
  Serial.print("Avg. value: ");
  Serial.println(magnetValue);
  if(magnetValue < treshold_magnet){
    return true;
  }
  setStatus(false);
  return false;
}

void manageMagnetValues(int value){
  intens_magnet.insert(intens_magnet.begin(), value);
  if(intens_magnet.size() > magnet_values){
    intens_magnet.pop_back();
  }
}

int getAvgMagnetValue(){
  float value = 0.0;
  int vecSize = intens_magnet.size();
  for(int i = 0; i < vecSize; i++){
    value += intens_magnet.at(i);
  }
  value = value / vecSize;
  value = roundValue(value);
  return int(value);
}

float roundValue(float value){
  return value<0 ? value - 0.5: value + 0.5;
}

void checkSerial(){
  
  if(Serial.available() > 0)
  {
    Serial.readBytesUntil('~', drawingPixels, numOfIncomingBytes);
        
    character = '\0';
    textMessage = "";
    delay(100);
    while(Serial.available() > 0) {    
      character = Serial.read();
      if(character != '~')
      {
        textMessage.concat(character);
      }
     } 
  }  
}

void notifyProcessing(){
  Serial.println("found");
}

void computeOutput(){
  writeText();
  writeBitmap();
}
  
void writeBitmap(){
  
  //for-loop #1: Iterates the horizontal Position of the whole Bitmap. At beginning at the right outer of the two Matrices.
  for(xPos = 7; xPos >= -36; xPos--){
    matrixLeft.clear();
    matrixRight.clear(); 
    //for-loop #2: yIndex of the char-Array "drawingPixels"
    for(yIndex = 0; yIndex < 8; yIndex++)
    {
        //for-loop #3: xIndex of the char-Array "drawingPixels"
        for(xIndex = 0; xIndex < 8; xIndex++)
        { 
          if(drawingPixels[yIndex * 8 + xIndex] == 1)
          {
              matrixLeft.drawPixel(xIndex + xPos + 8, yIndex, LED_ON); 
              matrixRight.drawPixel(xIndex + xPos, yIndex, LED_ON);
          }
       }
    }
    
    matrixLeft.writeDisplay(); 
    matrixRight.writeDisplay();  
    delay(100);
  }
}

//Write (display) the current Text to the 2 Matrix-Displays
void writeText(){
  if(textMessage.length() > 1){
    matrixLeft.setRotation(2);
    matrixRight.setRotation(2);
    int numOfPoints = (textMessage.length() * 8) + 8;
    
    //Iterates the horizontal Position of the whole Text. At beginning at the right outer of the two Matrices.
    for (xPos = 7; xPos >= -numOfPoints; xPos--) 
    {    
      matrixLeft.clear();
      matrixRight.clear();
      matrixLeft.setCursor(xPos+8,0);
      matrixRight.setCursor(xPos+0,0);
      matrixLeft.print(textMessage);
      matrixRight.print(textMessage);
      matrixLeft.writeDisplay();
      matrixRight.writeDisplay();    
      delay(100);
    }
  }
}

void blinkLamps(){ 
  turnOnLight(led_red);
  delay(500);
  checkSensor(led_red);
  delay(1000);
  turnOffLight(led_red);
  delay(1000);
  turnOnLight(led_blue);
  delay(500);
  checkSensor(led_blue);
  delay(1000);
  turnOffLight(led_blue);
  delay(1000);
  turnOnLight(led_green);
  delay(500);
  checkSensor(led_green);
  delay(1000);
  turnOffLight(led_green);
  delay(1000);
}

void turnOnLight(int which){
  digitalWrite(which, HIGH);
}

void turnOffLight(int which){
  digitalWrite(which, LOW);
}

void checkSensor(int which){
  sensorV = analogRead(0);
  switch(which){
    case led_red:
      intens_red = sensorV;
      Serial.print("R: ");    
      break;
    case led_blue:
      intens_blue = sensorV;
      Serial.print("B: ");
      break;
    case led_green:
      intens_green = sensorV;
      Serial.print("G: ");
      break;  
  }
  Serial.println(sensorV); 
}

void computeIntensity(){
    scale();
    defineColor();
}

void scale(){
    // Serial.println("Scaled Values");
    intens_red = map(intens_red, 0, 1023, 255 , 0);
    // Serial.println(intens_red);
    intens_green = map(intens_green, 0, 1023, 255, 0);
    // Serial.println(intens_green);
    intens_blue = map(intens_blue, 0, 1023, 255, 0);
    // Serial.println(intens_blue);
}

void defineColor(){
    if(intens_red > intens_green && intens_red > intens_blue){
      int r_g_diff = intens_red - intens_green;
      int r_b_diff = intens_red - intens_blue;
      if(r_g_diff > treshold_color && r_b_diff > treshold_color){
        setStatus(true);
        Serial.println("found");
        return;
      }
    }
     setStatus(false);
    Serial.println("no ball");
}

void setStatus(boolean ballStatus){
  isFound = ballStatus;
}
