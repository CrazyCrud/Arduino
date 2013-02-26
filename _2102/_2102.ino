#include "math.h"
#include <StandardCplusplus.h>
#include <vector>
#include <string>
#include <iterator>
using namespace std;

const int led_red = 11;
const int led_blue = 10;
const int led_green= 9;
const int magnet_analog = 5;
const int magnet_digital = 8;
const int treshold_color = 20;
const int treshold_magnet = 30;
const int magnet_values = 5;
int intens_red, intens_blue, intens_green;
vector<int> intens_magnet;
int sensorV;

void setup(){
  Serial.begin(9600);
  pinMode(led_red, OUTPUT);
  pinMode(led_blue, OUTPUT);
  pinMode(led_green, OUTPUT);
  pinMode(magnet_digital, INPUT);
}

void loop(){
  delay(250);
  //if(isMagnetDetected()){
    blinkLamps();
    computeIntensity();
  //}
}

boolean isMagnetDetected(){
  int magnetValue = analogRead(magnet_analog);
  manageMagnetValues(magnetValue);
  magnetValue = getAvgMagnetValue();
  Serial.print("Avg. value: ");
  Serial.println(magnetValue);
  if(magnetValue < treshold_magnet){
    return true;
  }
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
    Serial.println("Scaled Values");
    intens_red = map(intens_red, 0, 1023, 255 , 0);
    Serial.println(intens_red);
    intens_green = map(intens_green, 0, 1023, 255, 0);
    Serial.println(intens_green);
    intens_blue = map(intens_blue, 0, 1023, 255, 0);
    Serial.println(intens_blue);
}

void defineColor(){
    if(intens_red > intens_green && intens_red > intens_blue){
      int r_g_diff = intens_red - intens_green;
      int r_b_diff = intens_red - intens_blue;
      if(r_g_diff > treshold_color && r_b_diff > treshold_color){
        Serial.println("found");
        return;
      }
    }
    Serial.println("no ball");
}
