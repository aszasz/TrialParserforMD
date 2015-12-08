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

typedef CommandDef = {
    description:String,
    nArgs:Int,
    matchPattern:EReg
}

typedef SourcePosition = {
    caller:String,
    filename:String,
    line:Int,
    startPos:Int
}
typedef TextChunk={
    style: TextStyle,
    sourcepos:SourcePosition,
    content:String
}
typedef BookParagraph = Array<TextChunk>
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
        var ast = ParseIntoParagraphs (Sys.args()[0],"BRTParser");
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

    // A paragraph is text between aparently empty lines (only tabs spaces and CharCodes between 9 and 13)
    // Lines starting with % are ignored 
    static function ParseIntoParagraphs(filePath:String, calledFrom:String,?curPar:BookParagraph):BookAST {
        var pipeinCommand = {description:"Change Input to given file", nArgs:1, matchPattern:~/^\\pipein\{(.+)\}$/i};
        var filePathSplit = filePath.split("/");
        var fileName = filePathSplit.pop();
        var fileDir = filePathSplit.join("/");
        var fullstr = File.getContent(filePath);
        var noCrlines = fullstr.replace( "\r", "");
        var lines = noCrlines.split("\n");
        var ast:BookAST = [];
        var count = 0;
        if (curPar == null) curPar = [];
        for (li in lines){
            count = count+1;
            if (li.startsWith("%")) continue;
            if (looksBlank(li)){
                if (curPar.length>0){
                    ast.push (curPar);
                    curPar = [];
                }
            } else {
                if (curPar.length>0) curPar[curPar.length-1].content =  curPar[curPar.length-1].content + " ";
                if (!li.startsWith("\\pipein")) {
                    curPar.push({style:Normal, sourcepos:{caller:calledFrom, filename:fileName, line:count, startPos:1}, content:li});
                } else {
                    var pipeInFileName:String = "";
                    if (pipeinCommand.matchPattern.match(li.trim)) 
                        pipeInFileName = pipeinCommand.matchPattern.matched(1);
                    else {
                        trace ('argument to \\pipein do not match in line $count of file $fileName called from: $calledFrom \n -->$li' );
                        Sys.exit(1);
                    }
                    trace ('fileName = $fileName');
                    trace ('fileDir = $fileDir');
                    var prevWorkDir = Sys.getCwd();
                    if (fileDir != "") Sys.setCwd(fileDir);
                    if (!FileSystem.exists(pipeInFileName)){
                        trace ('file to \\pipein not found: $pipeInFileName (in line $count of file $fileName called from: $calledFrom)' );
                        Sys.exit(1);
                    }
                    
                    var astsub = ParseIntoParagraphs (pipeInFileName,'$calledFrom ==> $fileName: line $count', curPar);
                    curPar = astsub.pop();
                    for (subpar in astsub) ast.push (subpar);
                    Sys.setCwd(prevWorkDir);
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
    
    static function displayUsageAndExit(?exitStatus=1){
        trace(' Use: neko brtparse.n inputfilename outputfilename');
        Sys.exit(exitStatus);
    }

}
