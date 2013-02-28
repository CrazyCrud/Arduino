#include <Wire.h>
#include "math.h"
#include <StandardCplusplus.h>
#include <vector>
#include <string>
#include <iterator>
#include "Adafruit_LEDBackpack.h"
#include "Adafruit_GFX.h"
using namespace std;

/* -----------------------------------
  Variables for LED Matrix and displaying
*/ 
Adafruit_8x8matrix matrixLeft= Adafruit_8x8matrix();
Adafruit_8x8matrix matrixRight = Adafruit_8x8matrix();
const  byte matrixWidth = 8;
//char-Array needed, cause byte-array isn't accepted by the method readBytesUntil()
char drawingPixels [] = {
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 
  };
const  byte numOfIncomingBytes = 64;
//x and y-indices for the loops in writeBitmap()
byte yIndex, xIndex;
//x-Position for the horizontal run of text and image (used in writeBitmap AND writeText)
int8_t xPos;
char character;
String textMessage = "Test";

/* -----------------------------------
  Variables for Color Detection
*/   
const int led_red = 11;
const int led_blue = 10;
const int led_green= 9;
const int led_status = 5;
const int treshold_color = 20;
int intens_red, intens_blue, intens_green, val_lightSensor;

/* -----------------------------------
  Variables for Magnet Detection
*/  
const int accelX_analog = 3;
const int accelY_analog = 2;
const int accelZ_analog = 4;
const int accel_treshold = 70;
const int magnet_analog = 5;
const int magnet_digital = 8;
const int magnet_values = 5;
int magnetValue;
int accelValue = 0;
int accelValue_old = 0;
const int treshold_magnet = 20;
vector<int> intens_magnet;
int vecSize;
boolean showStatusLed = false;
/* -----------------------------------
  Common Variables
*/  
boolean colorFound = false;


void setup(){
  Serial.begin(9600);
  
  //setTimeout to prevent problems with sending/receiving data. Sets a maximum time for communication over serial.
  Serial.setTimeout(1000);
  
  initializeIO();
  initializeMatrix();
}

//Initialize the leds for color detection and the magnet sensor
void initializeIO(){
  pinMode(led_red, OUTPUT);
  pinMode(led_blue, OUTPUT);
  pinMode(led_green, OUTPUT);
  pinMode(led_status, OUTPUT);
  pinMode(magnet_digital, INPUT);
}

void initializeMatrix(){
  //Assigning the different adresses to the 8x8 matrices
  matrixLeft.begin(0x70);  
  matrixRight.begin(0x71); 
  
  //Set TextWrap so that the text won't be wiped out too early
  matrixLeft.setTextWrap(false);
  matrixRight.setTextWrap(false);
  
  //Rotate the orientation of the matrix so that the text runs from the right to the left
  matrixLeft.setRotation(2);
  matrixRight.setRotation(2);
}

//loop-Method is called over and over again (standard method)
void loop(){
  delay(100);
  //check if magnet is detected. If not do nothing.
  if(isMagnetDetected()){
    //check if the correct color is detected
    if(colorFound){
      catchMagnetValues();
      signalBallFound(true);
      checkSerial();
      catchMagnetValues();
      notifyProcessing(true);
      computeOutput();
      catchMagnetValues();
    }else {
      //check the color and set variable color found      
      catchMagnetValues();
      blinkLamps();
      catchMagnetValues();
      computeIntensity();
    }
  }else{
    signalBallFound(false);
    notifyProcessing(false);
  }
  checkAccelaration();
}

//check if the magnetsensor is detecting a magnet
boolean isMagnetDetected(){
  magnetValue = analogRead(magnet_analog);
  Serial.println(magnetValue);
  manageMagnetValues(magnetValue);
  magnetValue = getAvgMagnetValue();
  // Serial.print("Magnet Avg. Value: ");
  // Serial.println(magnetValue);
  if(magnetValue < treshold_magnet){
    return true;
  }
  setColorFoundStatus(false);
  return false;
}

//Save a specific number of values to a vector
void manageMagnetValues(int value){
  intens_magnet.insert(intens_magnet.begin(), value);
  if(intens_magnet.size() > magnet_values){
    intens_magnet.pop_back();
  }
}

void catchMagnetValues(){
  manageMagnetValues(analogRead(magnet_analog));
}

//Compute the average value for the intensity of the magnet sensor
int getAvgMagnetValue(){
  float value = 0.0;
  vecSize = intens_magnet.size();
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

void signalBallFound(boolean isFound){
  if(isFound){
    turnOnLight(led_status);
  }else{
    turnOffLight(led_status);
  }
}

void signalComputingBall(){
  if(showStatusLed){
    turnOnLight(led_status);
    showStatusLed = false;
  }else{
    turnOffLight(led_status);
    showStatusLed = true;
  }
}

//check if there's incoming data (a message) and save the image and text
//There's always sent the image first and then the text
void checkSerial(){
  
  if(Serial.available() > 0)
  {
    //read the incoming bytes and save it to the char array for the image. 
    //when a maximum number of bytes (the size of the image-array) is reached, the method stops
    Serial.readBytesUntil('~', drawingPixels, numOfIncomingBytes);
    
    //the following chars get concatenated and saved to the string for the text
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

void checkAccelaration(){
  // Serial.print("X: ");
  // Serial.println(analogRead(accelX_analog));
  accelValue_old = analogRead(accelX_analog);
  if(accelValue == 0){
    accelValue = accelValue_old;
    return;
  }
  if((accelValue_old - accelValue) > accel_treshold){
    Serial.println("sound");
  }
  accelValue = accelValue_old;
}


void notifyProcessing(boolean ballFound){
  if(ballFound){
    Serial.println("found");
  }else{
    Serial.println("no ball");
  }
}

void computeOutput(){
  writeText();
  writeBitmap();
}
  
//Set the pixels of bitmap on the matrix
void writeBitmap(){
  
  //for-loop #1: Iterates the horizontal Position of the whole Bitmap. At beginning at the right outer of the two Matrices.
  for(xPos = 7; xPos >= -36; xPos--){
    //clear all pixels
    matrixLeft.clear();
    matrixRight.clear(); 

    //for-loop #2: yIndex of the char-Array "drawingPixels"
    for(yIndex = 0; yIndex < matrixWidth; yIndex++)
    {
        //for-loop #3: xIndex of the char-Array "drawingPixels"
        for(xIndex = 0; xIndex < matrixWidth; xIndex++)
        { 
          if(drawingPixels[yIndex * matrixWidth + xIndex] == 1)
          {
              //drawPixel() sets if a led shall be displayed or not
              matrixLeft.drawPixel(xIndex + xPos + matrixWidth, yIndex, LED_ON); 
              matrixRight.drawPixel(xIndex + xPos, yIndex, LED_ON);
          }
       }
    }
    //When all required pixels are set, then the calculated matrix can be displayed
    matrixLeft.writeDisplay(); 
    matrixRight.writeDisplay();  
    delay(100);
  }
}

//Write the current Text to the 2 Matrix-Displays
void writeText(){
  if(textMessage.length() > 1){
    
    //Rotate the orientation of the matrix so that the text runs from the right to the left
    matrixLeft.setRotation(2);
    matrixRight.setRotation(2);
    
    int numOfPoints = (textMessage.length() * matrixWidth) + matrixWidth;
    
    //Iterates the horizontal Position of the whole Text. At beginning at the right outer of the two Matrices.
    for (xPos = 7; xPos >= -numOfPoints; xPos--) 
    {    
      
      //clear all pixels
      matrixLeft.clear();
      matrixRight.clear();
      
      //set the position of text
      matrixLeft.setCursor(xPos+matrixWidth,0);
      matrixRight.setCursor(xPos+0,0);
      
      //set the text that shall be displayed
      matrixLeft.print(textMessage);
      matrixRight.print(textMessage);
      
      //When all required points are set, then the calculated matrix can be displayed
      matrixLeft.writeDisplay();
      matrixRight.writeDisplay();    
      delay(100);
    }
  }else{
    // matrixLeft.clear();
    // matrixRight.clear();
  }
}

//Turn the red, blue and green led one after another on/off and check the intensity of each color
void blinkLamps(){ 
  turnOnLight(led_red);
  delay(200);
  checkLightSensor(led_red);
  delay(100);
  turnOffLight(led_red);
  delay(100);
  turnOnLight(led_blue);
  delay(200);
  checkLightSensor(led_blue);
  delay(100);
  turnOffLight(led_blue);
  delay(100);
  turnOnLight(led_green);
  delay(200);
  checkLightSensor(led_green);
  delay(100);
  turnOffLight(led_green);
  delay(100);
}

//Just turn on a specific led
void turnOnLight(int which){
  digitalWrite(which, HIGH);
}

//Just turn off a specific led
void turnOffLight(int which){
  digitalWrite(which, LOW);
}

//check the value of the light sensor
void checkLightSensor(int which){
  val_lightSensor = analogRead(0);
  switch(which){
    case led_red:
      intens_red = val_lightSensor;
      Serial.print("R: ");    
      break;
    case led_blue:
      intens_blue = val_lightSensor;
      Serial.print("B: ");
      break;
    case led_green:
      intens_green = val_lightSensor;
      Serial.print("G: ");
      break;  
  }
  Serial.println(val_lightSensor); 
}

//Scale intensity values 
void computeIntensity(){
    scale();
    defineColor();
}

//Scale the intensity values of the light sensor
void scale(){
    // Serial.println("Scaled Values");
    intens_red = map(intens_red, 0, 1023, 255 , 0);
    // Serial.println(intens_red);
    intens_green = map(intens_green, 0, 1023, 255, 0);
    // Serial.println(intens_green);
    intens_blue = map(intens_blue, 0, 1023, 255, 0);
    // Serial.println(intens_blue);
}

//Check if the intensity of red is the highest, involving a treshold, saving the status of colorFound
void defineColor(){
    if(intens_red > intens_green && intens_red > intens_blue){
      int r_g_diff = intens_red - intens_green;
      int r_b_diff = intens_red - intens_blue;
      if(r_g_diff > treshold_color && r_b_diff > treshold_color){
        setColorFoundStatus(true);
        Serial.println("found");
        return;
      }
    }
    setColorFoundStatus(false);
    Serial.println("no ball");
}

//set the status of color found
void setColorFoundStatus(boolean ballStatus){
  colorFound = ballStatus;
}
