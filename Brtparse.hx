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
typedef TextStream={
    style: TextStyle,
    sourcepos:SourcePosition,
    content:String
}
typedef BookParagraph = Array<TextStream>
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

        //testing
        var input = Std.parseInt(Sys.stdin().readLine());
        while (input!=0){
            var parcontent = "" ;
            var firstline = Math.POSITIVE_INFINITY;
            var lastline = Math.NEGATIVE_INFINITY;
            for (par in ast[input-1]) {
                parcontent = parcontent + par.content;
                firstline = Math.min(firstline,par.sourcepos.line);
                lastline = Math.max(lastline,par.sourcepos.line);
            }
            trace ("\n " + parcontent
                 + "\n lines:" + firstline + "-" + lastline
                 + "\n Enter new paragraph to display (0 for exit)" );
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
        var curPar:BookParagraph = [];
        for (li in lines){
            count = count+1;
            if (looksBlank(li)){
                if (curPar.length>0){
                    ast.push (curPar);
                    curPar = [];
                }
            } else {
                if (curPar.length>0) curPar[curPar.length-1].content =  curPar[curPar.length-1].content + " ";
                curPar.push({style:Normal,sourcepos:{filename:fileName,line:count,startPos:1},content:li});
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
