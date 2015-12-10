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

typedef ParseSource = {
    caller: String,
    filename: String,
    line:Null<Int>,
}

typedef TextChunk = {
    textStyle:TextStyle,
    textContent:String,
//    parseStartPos:Int,
//    parseEndPos:Int
}

enum BookDivisionType {
   Book;
   Volume;
   Chapter;
   Section;
   SubSection;
   SubSubSection;
   SubSubSectionItem;
   SubSubSectionSubItem;
}

enum BookComponentType {
    Paragraph;
    Figure;
    Table;
    Equation;
}

enum BookElementType {
    DivType(name:BookDivisionType, numberedAfter:BookDivisionType);
    CompType(name:BookComponentType, numberedAfter:BookDivisionType);
}

typedef BookElementsCommon = {
//   level is implicit   
    type: BookElementType,
    name: Null<String>,
    isNumbered: Bool,
    number:Null<Int>,
    source: ParseSource
}

enum ImageSize {
    ImgSzSmall;
    ImgSzMedium;
    ImgSzLarge;
    ImgSzHuge;
}

typedef FigureContents = {
    path:String,
    aternateText:String,
    size:ImageSize,
    caption:Null<String>
}

typedef TableColumn = Array<TextChunk>
typedef TableLine = Array<TableColumn>

enum BookElement {
    BookDiv(base:BookElementsCommon, content:Array<BookElement>);
    BookFigure(base:BookElementsCommon, content:FigureContents);
    BookTable(base:BookElementsCommon, content:Array<TableLine>);
    BookEquation(base:BookElementsCommon, content:Array<TextChunk>);
    BookParagraph(base:BookElementsCommon, content:Array<TextChunk>);
}

class Brtparse
{
    static var theBRTPGBookType  = DivType(Book, Book);
    static var BRTPGStardardParagraphType = CompType(Paragraph, Book);

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
            for (par in ast.content[input-1]) {
                parcontent = parcontent + par.textContent;
                line =  par.base.source.line;
//                firstline = Math.min(firstline, par.base.source.line);
//                lastline = Math.max(lastline, par.base.source.line);
            }
            trace ("\n " + parcontent
                 + "\n startline:" + line 
//                 + "\n lines:" + firstline + "-" + lastline
                 + "\n Enter new paragraph to display (0 for exit)" );
            input = Std.parseInt(Sys.stdin().readLine());
        }
        
        File.saveContent(Sys.args()[1],Serializer.run(ast));
    }

    // A paragraph is text between aparently empty lines (only tabs spaces and CharCodes between 9 and 13)
    // Lines starting with % are ignored 
    static function ParseIntoParagraphs(filePath:String, calledFrom:String, ?curPar:BookElement):BookElement 
    {
        var pipeinCommand = {description:"Change Input to given file", nArgs:1, matchPattern:~/^\\pipein\{(.+)\}$/i};
        var filePathSplit = filePath.split("/");
        var fileName = filePathSplit.pop();
        var fileDir = filePathSplit.join("/");
        var fullstr = File.getContent(filePath);
        var noCrlines = fullstr.replace( "\r", "");
        var lines = noCrlines.split("\n");
        var count = 0;
        var ast:BookElement = BookDiv(  {type:DivType(Book, Book),
                                         name:"BRTPG", isNumbered:false, number:null,
                                         source:{caller:calledFrom, filename:fileName, line:count}}
                                         , []  );
        if (curPar == null) curPar = BookParagraph( {type:CompType(Paragraph, Book),
                                                    name:null, isNumbered:false, number:null,
                                                    source:{caller:calledFrom, filename:fileName, line:count}},
                                                    []  );
        for (li in lines){
            count = count+1;
            if (li.startsWith("%")) continue;
            if (looksBlank(li)){
                if (curPar.content.length>0){
                    ast.content.push (curPar);
                    curPar.content = [];
                }
            } else {
                if (curPar.content.length>0) {
                        curPar[curPar.content.length-1].textContent =  curPar[curPar.length-1].content.textContent + " ";
//                        curPar[curPar.content.length-1].parseEndPos =  curPar[curPar.length-1].content.parseEndPos + 1;
                }
                if (!li.startsWith("\\pipein")) {
                    curPar.content.push({textStyle:Normal, textContent:li});//,parseStartPos:1, parseEndPos:li.length)} ;
//                    curPar.base    :{caller:calledFrom, filename:fileName, line:count, startPos:1}, content:li});
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
                    curPar = astsub.content.pop();
                    for (subpar in astsub) ast.content.push (subpar);
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
