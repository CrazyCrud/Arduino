import processing.serial.*;

class MessagesHandler
{
  Message inst_redMessage;

  public MessagesHandler()
  {
    inst_redMessage = new Message("message-red.json");
  }
  
  //Central method to overwrite the old/default message. Controlling the reading, parsing, editing and saving.
  public void sendText(String pCurrentText)
  {     
    //Speichere die neue Datei unter dem festgelegten Namen. Ersetze den alten Text durch die neue Nachricht.
    inst_redMessage.setText(pCurrentText);
    inst_redMessage.sendMessage();
  }
  
  //
  public void sendDrawing(){
    inst_redMessage.sendDrawing();
  }
  
  //Set a point in the boolean array
  public void setImagePoint(int id, boolean isMarked){
    inst_redMessage.setImagePoint(id, isMarked);
  }
  
  //Display the current Message. Get the image saved in the Message-Object
  public void displayMessage(Serial arduino)
  {
    byte[] currentImage = inst_redMessage.getImage();
    arduino.write(currentImage);   
    arduino.write('~');   
    String currentMessage = inst_redMessage.getCurrentText();
    println("Write Message " + currentMessage);
    arduino.write(currentMessage);         
  } 
  
}


