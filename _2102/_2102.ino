#include "math.h"

const int led_red = 2;
const int led_blue = 4;
const int led_green= 6;
const int magnet_analog = 5;
const int treshold = 100;
int intens_red, intens_blue, intens_green;
int sensorV;

void setup(){
  Serial.begin(9600);
  pinMode(led_red, OUTPUT);
  pinMode(led_blue, OUTPUT);
  pinMode(led_green, OUTPUT);
}

void loop(){
  if(isMagnetDetected()){
    blinkLamps();
    computeIntensity();
  }
  blinkLamps();
  computeIntensity();
}

boolean isMagnetDetected(){
  int magnetValue = analogRead(magnet_analog);
  // Serial.println(magnetValue);
  if(analogRead(magnet_analog) > 0){
    return false;
  }
  return true;
}

void blinkLamps(){
  turnOnLight(led_red);
  delay(1000);
  checkSensor(led_red);
  delay(2000);
  turnOffLight(led_red);
  delay(2000);
  turnOnLight(led_blue);
  delay(1000);
  checkSensor(led_blue);
  delay(2000);
  turnOffLight(led_blue);
  delay(2000);
  turnOnLight(led_green);
  delay(1000);
  checkSensor(led_green);
  delay(2000);
  turnOffLight(led_green);
  delay(2000);
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
      // Serial.print("R: ");    
      break;
    case led_blue:
      intens_blue = sensorV;
      // Serial.print("B: ");
      break;
    case led_green:
      intens_green = sensorV;
      // Serial.print("G: ");
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
      if(r_g_diff > treshold && r_b_diff > treshold){
        Serial.println("red");
        return;
      }
    }
    Serial.println("not color");
}
