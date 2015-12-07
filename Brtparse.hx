import haxe.io.Eof;
import haxe.Serializer;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.FileSystem;

using StringTools;

typedef SourcePosition = {
    filename:String,
    line:Int
}
typedef BookParagraph = {
    sourcepos:SourcePosition,
    content:String
}

typedef BookAST = Array<BookParagraph>;

class Brtparse
{
    static function main() {

        haxe.Log.trace = function (msg:String, ?pos:haxe.PosInfos) Sys.stderr().writeString('${pos.fileName}:${pos.lineNumber}: $msg\n');
        
        if (Sys.args().length!=2) {
            trace( 'wrong number of args: need two files');
            displayUsageAndExit();
        } 
        if (!FileSystem.exists(Sys.args()[0])){
            trace ('file not found:' + Sys.args()[0]);
            displayUsageAndExit();
        }
        trace('reading from  ${Sys.args()[0]} and writting to ${Sys.args()[1]}');
        var fullstr = File.getContent(Sys.args()[0]);
        var ast = ParseIntoParagraphs (Sys.args()[1],fullstr);
        trace ("AST has  " + ast.length + " paragraphs. \n Enter paragraph to display (0 for exit)" );
        var input = Std.parseInt(Sys.stdin().readLine());
        while (input!=0){
            trace ( ast[input-1].content + "\n \n Enter a new paragraph to display (0 for exit)"  );
            input = Std.parseInt(Sys.stdin().readLine());
        }
        File.saveContent(Sys.args()[1],Serializer.run(ast));
    }

    static function ParseIntoParagraphs(fileName:String,fileContent:String):BookAST {
        var noCrlines = fileContent.replace( "\r", "");
        var lines = noCrlines.split("\n");
        var ast:BookAST = [];
        var count = 0;
        var firstParagraphLine = 0;
        var parContent = "";
        for (li in lines){
            count = count+1;
            if (looksBlank(li)){ 
                if (parContent!=""){
                    ast.push ({sourcepos:{filename:fileName,line:firstParagraphLine+1},content:parContent});
                    firstParagraphLine=0; 
                    parContent="";
                }
            } else {
                if (firstParagraphLine==0) {
                    firstParagraphLine = count;
                    parContent = li;
                } else
                    parContent = parContent + " " + li;
            }
        }    
        return ast;
    }
    static function looksBlank(line:String):Bool{
        for (charpos in 0...line.length) 
            if (!line.isSpace(charpos)) return false;
        return true;
    }
    static function displayUsageAndExit(?exitStatus=1){
        trace(' Use: neko brtparse.n inputfilename outputfilename');
        Sys.exit(exitStatus);
    }

}
