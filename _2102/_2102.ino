const int led_red = 2;
const int led_blue = 4;
const int led_green= 6;
int intens_red, intens_blue, intens_green;
int sensorV;

void setup(){
  Serial.begin(9600);
  pinMode(led_red, OUTPUT);
  pinMode(led_blue, OUTPUT);
  pinMode(led_green, OUTPUT);
}

void loop(){
  blinkLamps();
  computeIntensity();
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
  sensorV = analogRead(A0);
  switch(which){
    case led_red:
      Serial.print("Rot: ");    
      break;
    case led_blue:
      Serial.print("Blau: ");
      break;
    case led_green:
      Serial.print("Gruen: ");
      break;  
  }
  Serial.println(sensorV); 
}

void checkSensor(){
  sensorV = analogRead(A0);
  Serial.println(sensorV);
}

void computeIntensity(){
    
}
