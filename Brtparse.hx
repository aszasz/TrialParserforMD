import haxe.io.Eof;
import haxe.Serializer;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.FileSystem;

using StringTools;

@:enum abstract TextStyle(Int){
    var Normal = 0;
    var SubScript = 1;
    var SuperScript = 2;
    var URL = 5;
    var Head1 = 10;
    var Head2 = 20;
    var Head3 = 30;
    var Head4 = 40;
    var Head5 = 50;
    var Head6 = 60;
    var UnderScore = 100;
    var Italic = 200;
    var Bold = 400;
    var Emphasized = 1000;
}

typedef SourcePosition = {
    filename:String,
    line:Int,
    startPos:Int
}
typedef textStream={
    style: TextStyle,
    sourcepos:SourcePosition,
    content:String
}
typedef BookParagraph = Array<textStream>
typedef BookAST = Array<BookParagraph>;

class Brtparse
{
    static function main() {

        haxe.Log.trace = function (msg:String, ?pos:haxe.PosInfos) Sys.stderr().writeString('${pos.fileName}:${pos.lineNumber}: $msg\n');
        
        if (Sys.args().length!=2) {
            trace( 'wrong number of args: need two files');
            failedExit();
        } 
        if (!FileSystem.exists(Sys.args()[0])){
            trace ('file not found:' + Sys.args()[0]);
            failedExit();
        }
        trace('reading from  ${Sys.args()[0]} and writting to ${Sys.args()[1]}');
        var fullstr = File.getContent(Sys.args()[0]);
        var ast = ParseIntoParagraphs (Sys.args()[1],fullstr);
        trace ("AST has  " + ast.length + " paragraphs. \n Enter paragraph to display (0 for exit)" );
        var input = Std.parseInt(Sys.stdin().readLine());
        while (input!=0){
            trace ( ast[input-1].content + 
                    "\n source=" 
                    ast[input-1].source file 
                    "\n \n Enter a new paragraph to display (0 for exit)"  );
            input = Std.parseInt(Sys.stdin().readLine());
        }

        File.saveContent(Sys.args()[1],Serializer.run(ast));
    }

    static function ParseIntoParagraphs(fileName:String,fileContent:String):BookAST {
        var noCr = fileContent.replace("\r", "");
        var lines = noCr.split("\n");
        
//        var slashedRlines = fileContent.split("\n");
//        trace ("file has " + lines.length + " lines!");
//        for (li in lines) {
//            trace ("line: " + li + " \n len: " + li.length);
//            trace ("lastcharcode: " + li.charCodeAt(li.length-1) );
//            if (li.charAt(li.length-1) == "\r") {
//                li = li.substring(0,li.length-1);
//                trace (" became: " + li + " \n len: " + li.length);
//                trace ("lastcharcode: " + li.charCodeAt(li.length-1) );
//            }
//        }
        
        var ast:BookAST = [];
        var count = 0;
        var firstParagraphLine = 0;
        var parContent = "";
        for (li in lines){
            count = count + 1;
//           trace ("evaluating line: " + count + "="  + li + " \n len: " + li.length);
            if (looksBlank(li)){ 
//                trace ("it looks blank!");
                if (parContent!=""){
//                    trace ("and parContent is to be placed in ast:" + parContent);
                    ast.push ({sourcepos:{filename:fileName,line:firstParagraphLine+1},content:parContent});
                    firstParagraphLine=0; 
                    parContent="";
                }
            } else {
//                trace ("it does not look blank!");
                if (firstParagraphLine==0) {
                    firstParagraphLine = count;
                    parContent = parContent +  li;
                } else {
                    parContent = parContent + " " + li;
 //               trace ("parContent now is:" + parContent);
                }
            }
        }    
        return ast;
    }
    static function looksBlank(line:String):Bool{
        for (charpos in 0...line.length) 
            if (!line.isSpace(charpos)) return false;
        return true;
    }
    static function failedExit(?exitStatus = 1){
        trace(' Use: neko brtparse.n inputfilename outputfilename');
        Sys.exit(exitStatus);
    }

}
