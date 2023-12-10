package exceptions;

public class FontNotFoundException extends Exception{
    public FontNotFoundException(){
        super("The font is not found!");
    }
}
