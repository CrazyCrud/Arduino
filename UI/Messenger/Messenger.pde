import controlP5.*;
import processing.serial.*;
import ddf.minim.*;

PApplet app = this;
Serial arduino;
ControlP5 cp5;
Minim minim;
AudioPlayer noBall, backgroundSound, sendSound, clickSound;
PImage textinput_plane;
PImage drawing_plane;
PImage button_send;
PImage button_send_hover;
PImage button_send_press;
PImage button_delete;
PImage button_delete_hover;
PImage button_delete_press;
PImage button_sendDrawing;
PImage button_sendDrawing_hover;
PImage button_sendDrawing_press;
PImage message_send;
PImage message_empty;
PImage message_feedback;
PImage error;
PImage background;
Dot [] drawingDots;
String arduinoMessage = "";
String textValue = "";
final int id_sendMessageButton = 0;
final int id_deleteMessageButton = 1;
final int id_sendDrawingButton = 2;
int transTimer = 0;
boolean connected = true;
boolean isFeedbackVisible = false;
boolean isMessageSend = false;
MessagesHandler inst_messagesHandler;

void setup(){
  size(600, 400);  
  loadImages();
  initializeUI();
  initializeSketchfield();
  initializeSound();
  initializeArduino();
  initializeHandler();   
}

void loadImages(){
  textinput_plane = loadImage("text.png");
  drawing_plane = loadImage("drawing.png");
  button_send = loadImage("send.png");
  button_send_hover = loadImage("send_hover.png");
  button_send_press = loadImage("send_pressed.png");
  button_delete = loadImage("delete.png");
  button_delete_hover = loadImage("delete_hover.png");
  button_delete_press = loadImage("delete_press.png");
  button_sendDrawing = loadImage("send_drawing.png");
  button_sendDrawing_hover = loadImage("send_drawing_hover.png");
  button_sendDrawing_press = loadImage("send_drawing_pressed.png");
  message_send = loadImage("complete.png");
  message_empty = loadImage("incomplete.png");
  error = loadImage("no_ball.png");
  background = loadImage("background_dirt.png");
}

void initializeUI(){
  new Button(430, 160, 112, 49, button_send, button_send_hover, button_send_press, id_sendMessageButton);
  new Button(300, 161, 112, 49, button_delete, button_delete_hover, button_delete_press, id_deleteMessageButton);
  new Button(190, 310, 220, 46, button_sendDrawing, button_sendDrawing_hover,
                         button_sendDrawing_press, id_sendDrawingButton); 
  cp5 = new ControlP5(this);
  cp5.addTextfield("")
       .setPosition(50, 110)
       .setSize(450, 30)
       .setFont(createFont("arial",20))
       .setFocus(true)
       .setColorCursor(color(255, 255, 255))
       .setColorBackground(0)
       .setColorForeground(50)
       .setColorActive(100)
       .setColor(color(255, 255, 255));
}

void initializeSketchfield(){
  drawingDots = new Dot[64];
  int y = 250;
  int x;
  int id = 0;
  for(int j = 1; j < 9; j++){
    x = 40;
    for(int i = 1; i < 9; i++){
      drawingDots[(id + i) - 1] = new Dot(x, y, id + i);
      x += 15;
    }
    id += 8;
    y += 15;
  }
  
}

void initializeSound(){
 minim = new Minim(this);
 noBall = minim.loadFile("sounds/Messenger_NoBall.mp3");
 backgroundSound = minim.loadFile("sounds/Messenger_Background.mp3"); 
 clickSound = minim.loadFile("sounds/Messenger_Click.mp3");
 sendSound = minim.loadFile("sounds/Messenger_SendPaper.mp3");
}

void initializeArduino(){
  if(Serial.list().length > 0){
   arduino = new Serial(this, Serial.list()[0], 9600);
   arduino.bufferUntil('\n');
  }
}

void initializeHandler(){
  inst_messagesHandler = new MessagesHandler();
}

void draw(){
  drawBackground();
  playBackgroundSound();
  if(isBallFound()){
    setTextfield(true);
    setSketchfield(true);
    computeFeedback();
  }else{
    setTextfield(false);
    setSketchfield(false);
    displayNoConnection();
  }    
}

void setTextfield(boolean visible){
  cp5.get(Textfield.class, "").setVisible(visible);
}

void setSketchfield(boolean visible){
 for(int i = 0; i < drawingDots.length; i++){
  drawingDots[i].setState(visible); 
 }
}

void computeFeedback(){
  if(isFeedbackVisible){
      tint(255, 255 - transTimer);
      image(message_feedback, 460, 230);
      updateTimer();
      tint(255, 255); 
    }
}

void displayNoConnection(){
  image(error, 0, 0);
}

void showDisplayMessage()
{
  inst_messagesHandler.displayMessage(arduino);
}

void drawBackground(){
  background(187, 187, 187);
  smooth(8);
  image(background, 0, 0);
  image(textinput_plane, 10, 40);
  image(drawing_plane, 10, 225);
}

boolean isBallFound(){
  return true;
  /*
  try{
    if(matchAll(arduinoMessage, "found") != null){
      return true;
    }
  }
  catch(Exception e){
    println("Garbage in here");
  }
  return false; 
  */
}

void serialEvent(Serial myPort) {
  arduinoMessage = myPort.readString();
  println(arduinoMessage);
}

void updateTimer(){
  transTimer += 3;  
  if(transTimer > 255){
    isFeedbackVisible = false;
    resetTimer();  
  }
}

void resetTimer(){
 transTimer = 0; 
}

boolean isTextEmpty(){
  String input = cp5.get(Textfield.class, "").getText();
  return input.length() > 0? false: true;
}

String getText(){
  String input = cp5.get(Textfield.class, "").getText();
  return input;
}

void playOneShotSound(AudioPlayer player){
 player.rewind();
 if (player.isPlaying ()) {
    player.pause ();
  }
 player.play ();
}

void playBackgroundSound(){
  if(isBallFound()){
    noBall.pause();
    noBall.rewind();
    if(backgroundSound.isPlaying() == false){
      backgroundSound.loop();
    }
  }else{
    backgroundSound.pause();
    backgroundSound.rewind();
    noBall.loop();
  }
}

public class Button{
  boolean isHovered, isPressed, isReleased;
  int x, y, w, h;
  int id;
  PImage shape, hover, press;
  
  Button(int x, int y, int w, int h, PImage shape, PImage hover,
      PImage press, int id){
    isHovered = isPressed = isReleased = false;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.id = id;
    this.shape = shape;
    this.hover = hover;
    this.press = press;
    app.registerDraw(this);
    app.registerMethod("mouseEvent", this);
  }  
  
  void draw(){
    if(isBallFound() == false){
     return; 
    }
    if(isHovered){
      if(isPressed){
        image(press, x, y);
      }else{
        image(hover, x, y);
      }
    }else{
      image(shape, x, y); 
    }
  }
  
  boolean isOverButton(int xPos, int yPos){
    if(xPos > (this.x + 2) && xPos < (this.x + w - 2)){
      if(yPos > (this.y + 2) && yPos < (this.y + h - 2)){
        return true;
      }  
    }
    return false;
  }
  
  void mouseEvent(MouseEvent event){
    switch(event.getAction()){
      case processing.event.MouseEvent.CLICK:
        if(isOverButton(event.getX(), event.getY())){
          if(this.id == id_sendMessageButton){
            resetTimer();
            isFeedbackVisible = true;
            if(isTextEmpty()){
              message_feedback = message_empty;  
            }else{
              message_feedback = message_send;
              playOneShotSound(sendSound);
              inst_messagesHandler.sendText(getText());
              // showDisplayMessage();
            }
          }else if(this.id == id_deleteMessageButton){
            cp5.get(Textfield.class, "").clear();
          }else if(this.id == id_sendDrawingButton){
            resetTimer();
            isFeedbackVisible = true;
            message_feedback = message_send;
            computeDrawing();
          }
        playOneShotSound(clickSound);  
        }
        isPressed = false;
        break;
      case processing.event.MouseEvent.MOVE:
        if(isOverButton(event.getX(), event.getY())){
          isHovered = true; 
        }else{
          isHovered = false;  
        }
        break;
      case processing.event.MouseEvent.PRESS:
        if(isOverButton(event.getX(), event.getY())){
          isPressed = true; 
        }else{
          isPressed = false;  
        }
        break;
      case processing.event.MouseEvent.RELEASE:
        if(isPressed){
          isPressed = false; 
        }
        break;
    }
  }
}

void computeDrawing(){
  println("Length " + drawingDots.length);
  for(int i = 0; i < drawingDots.length; i++){
    inst_messagesHandler.setImagePoint(drawingDots[i].getID(), 
                                                                  drawingDots[i].isMarked());
  }
}


public class Dot{
 int x, y;
 int diameter;
 int id;
 boolean visible, active;


 public Dot(int x, int y, int id){
   this. x = x;
   this.y = y;
   this.id = id;
   diameter = 7;
   visible = false;
   active = false;
   app.registerDraw(this);
   app.registerMethod("mouseEvent", this);
 }
 
 void draw(){
   if(!active){
    return; 
   }
   if(!visible){
     fill(255);
   }else{
     fill(0);
   }
   ellipse(x, y, diameter, diameter);
 }
 
 void mouseEvent(MouseEvent event){
  if(!active){
   return; 
  }
  switch(event.getAction()){
    case processing.event.MouseEvent.CLICK:
      if(event.getX() > (x - diameter) && event.getX() < (x + diameter)){
        if(event.getY() > (y - diameter) && event.getY() < (y + diameter)){
          visible = !visible;
        } 
      }
      
      break;
  }
 }
 
void setState(boolean active){
 this.active = active;
 if(this.active){
   
 }else{
   
 }
} 

boolean isMarked(){
  return visible; 
} 

int getID(){
 return id; 
}
 
}

