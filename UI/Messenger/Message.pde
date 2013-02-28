import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.IOException;
import java.io.File;
import org.json.*;

class Message
{
  //Message-default.json contains the basic Syntax for the message. This default file is used every time a message shall be saved.
  private String string_defaultFileName = "message-default.json";
  private String string_fileName = ""; 
  private String string_path = "";  
  
  private JSONObject json_message = new JSONObject();  
  private String string_text = "";  
  private JSONArray arr_image = new JSONArray();
  
  private String string_textKey = "text";
  private String string_imageKey = "image";
  
  public Message(String pfileName)
  {        
    string_fileName = pfileName;
    string_path = dataPath("") + "\\" + string_fileName;   
    
    //createDefaultFile();
    
    read();
  }
  
  //Get text. First read the file so that the value is refreshed
  public String getCurrentText()
  {
    read();
    return string_text;
  }
  
  //Returns the byte-Array for the image
  public byte[] getImage()
  {    
    First read the file so that the value is refreshed
    read();    
    byte byteArray[] = new byte[Constants.int_matrixSize];
    for(int i = 0; i < Constants.int_matrixSize; i++)
    {
      try
      {
        //Convert boolean to byte, cause the Arduino needs byte-values
        byteArray[i] = (byte) (arr_image.getBoolean(i) ? 1 : 0);
      } 
      catch(Exception e)
      {
        handleException(e);
      }  
  }
    
    return byteArray;    
  }
  
  //Set the boolean value for a point in the image-matix.
  public void setImagePoint(int pIndex, Boolean pBool)
  {
    arr_image.put(pIndex, pBool);
  }
  
  //Get the boolean value for a point in the image-matix. In case of Exception return false
  public Boolean getImagePoint(int pIndex)
  {
    try
    {
      return arr_image.getBoolean(pIndex);
    }
    catch(Exception e)
    {
      handleException(e);  
      return false;
    }
  }
  
  //Read the content of the current message-file and update the content variable
  private void read()
  {  
    load();
    parse();
  }
  
  //Parse the Message: save the
  private void parse()
  {    
    string_text = json_message.getString(string_textKey);
    arr_image = json_message.getJSONArray(string_imageKey);    
  }   
  
  private void load()
  {
    String[] lines = loadStrings(string_fileName);
    json_message = new JSONObject(join(lines, " ")); 
  }
  
  public void setText(String pText)
  {
    string_text = pText;
  }
  
  //Send Message
  public void sendMessage(){    
    json_message.put(string_textKey, string_text);
    String lines[] = split(json_message.toString(), " ");
    saveStrings("data\\" + string_fileName, lines);   
  }
  
  //Put the json-array of the image into the json-object for the message and save the json file
  public void sendDrawing(){
    json_message.put(string_imageKey, arr_image);
    String lines[] = split(json_message.toString(), " ");
    saveStrings("data\\" + string_fileName, lines);    
  }

  //Default handling for exceptions
  private void handleException(Exception pException)
  {
    println(pException);
  }  
  
  //Create default JSON file, if it's needed. Just saving time for wrting.
  private void createDefaultFile()
  {
    JSONObject json_defaultMessage = new JSONObject();  
    String string_defaultText = "Default-Nachricht";  
    JSONArray arr_defaultImage = new JSONArray();
    
    for(int i = 0; i < Constants.int_matrixSize; i++)
    {
      arr_defaultImage.put(false);
    }
    
    json_defaultMessage.put("image", arr_defaultImage);
    json_defaultMessage.put("text", string_defaultText);
    
    String lines[] = split(json_defaultMessage.toString(), " ");
    saveStrings("data\\" + string_defaultFileName, lines);    
  }


}
