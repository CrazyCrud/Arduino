import processing.serial.*;

class MessagesHandler
{
  Message inst_redMessage;

  public MessagesHandler()
  {
    inst_redMessage = new Message("message-red.json");
    //displayMessage();
  }
  
  //Central method to overwrite the old/default message. Controlling the reading, parsing, editing and saving.
  public void sendText(String pCurrentText)
  {     
    //Speichere die neue Datei unter dem festgelegten Namen. Ersetze den alten Text durch die neue Nachricht.
    inst_redMessage.setText(pCurrentText);
    inst_redMessage.send();
    
    //Noch entfernen und woanders einfügen
    //displayMessage();
  }
  
  //Display the current Message
  public void displayMessage(Serial arduino)
  {
    println("Write Message");
    String currentMessage = inst_redMessage.getCurrentText();
    //String currentImage = inst_redMessage.getImage();
    arduino.write(currentMessage);    
  } 
  
  public void setImagePoint(int id, boolean isMarked){
    inst_redMessage.setImagePoint(id, isMarked);
  }
  
}

