import controlP5.*;
import processing.serial.*;
import ddf.minim.*;

PApplet app = this;
Serial arduino; // Connection to Arduino
ControlP5 cp5; // Text input field
Minim minim; // Audio library for Processing
AudioPlayer noBall, backgroundSound, sendSound, clickSound, ballShot; // AudioPlayer
// Buttons and images for different states (hover, pressed)
PImage textinput_plane;
PImage drawing_plane;
Button send;
PImage button_send;
PImage button_send_hover;
PImage button_send_press;
Button delete;
PImage button_delete;
PImage button_delete_hover;
PImage button_delete_press;
Button sendDrawing;
PImage button_sendDrawing;
PImage button_sendDrawing_hover;
PImage button_sendDrawing_press;
Button deleteDrawing;
PImage button_deleteDrawing;
PImage button_deleteDrawing_hover;
PImage button_deleteDrawing_press;
Button receiveMessage;
PImage button_receiveMessage;
PImage button_receiveMessage_hover;
PImage button_receiveMessage_press;
PImage message_send;
PImage message_empty;
PImage message_feedback;
PImage message_deleted;
PImage error;
PImage background;
PImage ballShotImg;
Dot [] drawingDots; // Sketch field
String arduinoMessage = "";
String arduinoMessageSound = "";
String textValue = "";
final int id_sendMessageButton = 0;
final int id_deleteMessageButton = 1;
final int id_sendDrawingButton = 2;
final int id_receiveMessage = 3;
final int id_deleteDrawingButton = 4;
int transTimer = 0;
int shotTimer = 0;
boolean connected = true;
boolean isFeedbackVisible = false;
boolean isMessageSend = false;
boolean isShot = false;
MessagesHandler inst_messagesHandler;

void setup(){
  size(600, 450);  
  loadImages();
  initializeUI();
  initializeSketchfield();
  initializeSound();
  initializeArduino();
  initializeHandler();   
}

// Load all images (button, feedback) 
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
  button_receiveMessage = loadImage("receive_message.png");
  button_receiveMessage_hover = loadImage("receive_message_hover.png");
  button_receiveMessage_press = loadImage("receive_message_pressed.png");
  message_send = loadImage("complete.png");
  message_deleted = loadImage("deleted.png");
  message_empty = loadImage("incomplete.png");
  error = loadImage("no_ball.png");
  background = loadImage("background_dirt.png");
  ballShotImg = loadImage("ball_shot.png");
}

// Initialize the buttons and the text field
void initializeUI(){
  send = new Button(430, 160, 112, 49, button_send, button_send_hover, button_send_press, id_sendMessageButton);
  delete = new Button(300, 161, 112, 49, button_delete, button_delete_hover, button_delete_press, 
                        id_deleteMessageButton);
  sendDrawing = new Button(190, 310, 220, 46, button_sendDrawing, button_sendDrawing_hover,
                         button_sendDrawing_press, id_sendDrawingButton); 
  deleteDrawing = new Button(191, 260, 112, 49, button_delete, button_delete_hover, button_delete_press, 
                        id_deleteDrawingButton);
  receiveMessage = new Button(10, 400, 240, 43, button_receiveMessage, button_receiveMessage_hover, 
    button_receiveMessage_press, id_receiveMessage);
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

// Initialize each dot object in the array and give them an id
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

// Initialize the audio players by loading the audiofiles
void initializeSound(){
 minim = new Minim(this);
 noBall = minim.loadFile("sounds/Messenger_NoBall.mp3");
 noBall.setVolume(0.5);
 backgroundSound = minim.loadFile("sounds/Messenger_Background.mp3"); 
 clickSound = minim.loadFile("sounds/Messenger_Click.mp3");
 sendSound = minim.loadFile("sounds/Messenger_SendPaper.mp3");
 ballShot = minim.loadFile("sounds/Messenger_Firing.mp3");
}

// Initialize the arduino connection and configure the 'read' process;
// All incoming data is fetched until a line break which is send in the ardunio
void initializeArduino(){
  if(Serial.list().length > 0){
   arduino = new Serial(this, Serial.list()[0], 9600);
   arduino.bufferUntil('\n');
  }
}

// Initialize the message handler object which writes data in a JSON object
void initializeHandler(){
  inst_messagesHandler = new MessagesHandler();
}

void draw(){
  drawBackground();
  playBackgroundSound();
  if(isBallFound()){
    setButtons(true);
    setTextfield(true);
    setSketchfield(true);
    computeFeedback();
    controlTextInput();
  }else{
    setButtons(false);
    setTextfield(false);
    setSketchfield(false);
    displayNoConnection();
    checkForFire();
    updateMessage();
  }    
}

// Set the state of each button to visible/ non-visible
void setButtons(boolean visible){
  send.setState(visible);
  sendDrawing.setState(visible);
  delete.setState(visible);
  receiveMessage.setState(visible);
  deleteDrawing.setState(visible);
}

// Set the state of the text field to visible/ non-visible
void setTextfield(boolean visible){
  cp5.get(Textfield.class, "").setVisible(visible);
}

// Set the state of the sketch field to visible/ non-visible
void setSketchfield(boolean visible){
 for(int i = 0; i < drawingDots.length; i++){
  drawingDots[i].setState(visible); 
 }
}

// Show and then fade out the feedback
void computeFeedback(){
  if(isFeedbackVisible){
      tint(255, 255 - transTimer);
      image(message_feedback, 460, 230);
      updateTimer();
      tint(255, 255); 
    }
}

void controlTextInput(){
 String inputText = getText();
 if(inputText.length() > 15){
  inputText = inputText.substring(0, 16);
  cp5.get(Textfield.class, "").setText(inputText);
 } 
}

// If no connection is available, a certain image is displayed
void displayNoConnection(){
  image(error, 0, 0);
}

// Calls the a method of the message handler object which sends the input to the arduino device
void showDisplayMessage()
{
  inst_messagesHandler.displayMessage(arduino);
}

// Draws the background images
void drawBackground(){
  background(187, 187, 187);
  smooth(8);
  image(background, 0, 0);
  image(textinput_plane, 10, 40);
  image(drawing_plane, 10, 225);
}

// Checks if the ball is found/ right position
// The arduino sends a text message ('found') if the ball is found and the method checks if this string
// is received
boolean isBallFound(){
  //return false;
  
  try{
    if(matchAll(arduinoMessage, "found") != null){
      return true;
    }
  }
  catch(Exception e){
    println("Garbage in here");
  }
  return false; 
}

void checkForFire(){
  try{
    if(matchAll(arduinoMessageSound, "sound") != null){
      arduinoMessageSound = "";
      isShot = true;
      playOneShotSound(ballShot);
    }
  }
  catch(Exception e){
    println("Garbage in here");
  }
}

void updateMessage(){
  if(isShot){
    image(ballShotImg, 0, 0);
    updateTimerShotBall();
  }
}

void updateTimerShotBall(){
  shotTimer++;
  if(shotTimer > 100){
    isShot = false;
    shotTimer = 0;
  }
}

// This EventHandler catches the event when data is sent from the arduino device
void serialEvent(Serial myPort) {
  arduinoMessage = myPort.readString();
  if(matchAll(arduinoMessage, "sound") != null){
    arduinoMessageSound = "sound";
  }
  println(arduinoMessage);
}

// Used to manage the fade out effect on the feedback images
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

// Checks if the text in the input field is empty
boolean isTextEmpty(){
  String input = cp5.get(Textfield.class, "").getText();
  return input.length() > 0? false: true;
}

// Checks if the drawing in the sketch field is empty
boolean isDrawingEmpty(){
  boolean isEmpty = true;
  for(int i = 0; i < drawingDots.length; i++){
    if(drawingDots[i].isMarked()){
     isEmpty = false; 
    }
  }
  return isEmpty;
}

// Returns the text in the input field
String getText(){
  String input = cp5.get(Textfield.class, "").getText();
  return input;
}

// Plays a certain sound (only sounds that should are not looped)
void playOneShotSound(AudioPlayer player){
 if(player == null){
  return; 
 }
 player.rewind();
 if (player.isPlaying ()) {
    player.pause ();
  }
 player.play ();
}

// Plays the background sound according to the current state of the ball
void playBackgroundSound(){
  if(noBall == null || backgroundSound == null){
   return; 
  }
  if(isBallFound()){
    noBall.pause();
    noBall.rewind();
    if(backgroundSound.isPlaying() == false){
      backgroundSound.loop();
    }
  }else{
    backgroundSound.pause();
    backgroundSound.rewind();
    if(noBall.isPlaying() == false){
      // noBall.loop();
    }
  }
}

public class Button{
  boolean isHovered, isPressed, isReleased, active;
  int x, y, w, h;
  int id;
  PImage shape, hover, press;
  
  Button(int x, int y, int w, int h, PImage shape, PImage hover,
      PImage press, int id){
    isHovered = isPressed = isReleased = active = false;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.id = id;
    this.shape = shape;
    this.hover = hover;
    this.press = press;
    // Register each button for the draw method and mouse events
    app.registerDraw(this);
    app.registerMethod("mouseEvent", this);
  }  
  
  void draw(){
    if(!active){
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
  
  void setState(boolean active){
   this.active = active;
   if(this.active){
     
   }else{
     
   }
}
  
  // Checks if the cursor's x- and y-positions are within the buttons
  boolean isOverButton(int xPos, int yPos){
    if(xPos > (this.x + 2) && xPos < (this.x + w - 2)){
      if(yPos > (this.y + 2) && yPos < (this.y + h - 2)){
        return true;
      }  
    }
    return false;
  }
  
  // Handles different mouse events 
  void mouseEvent(MouseEvent event){
    if(!active){
     return; 
    }
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
              inst_messagesHandler.sendText(getText());
            }
          }else if(this.id == id_deleteMessageButton){
            cp5.get(Textfield.class, "").clear();
            inst_messagesHandler.sendText("");
            resetTimer();
            isFeedbackVisible = true;
            message_feedback = message_deleted;  
          }else if(this.id == id_sendDrawingButton){
            resetTimer();
            isFeedbackVisible = true;
            if(isDrawingEmpty()){
              message_feedback = message_empty;  
            }else{
              message_feedback = message_send;
              computeDrawing();
              inst_messagesHandler.sendDrawing();
            }
          }else if(this.id == id_receiveMessage){
            showDisplayMessage();
          }else if(this.id == id_deleteDrawingButton){
            resetTimer();
            isFeedbackVisible = true;
            message_feedback = message_deleted; 
            deleteDrawing();
            computeDrawing();
            inst_messagesHandler.sendDrawing();
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

// Sends the current drawing to the message handler which is then written in a JSON file
void computeDrawing(){
  for(int i = 0; i < drawingDots.length; i++){
    inst_messagesHandler.setImagePoint(drawingDots[i].getID() - 1, 
                                                                  drawingDots[i].isMarked());
  }
}

void deleteDrawing(){
  for(int i = 0; i < drawingDots.length; i++){
    drawingDots[i].setVisibility(false);
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
     fill(255, 0, 0);
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
 
void setVisibility(boolean isVisible){
 visible = isVisible; 
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

