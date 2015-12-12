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

typedef SourceText = {
    filename: String,
    line:Int,
    textContent:String
}

typedef VBlock = Array <SourceText> //for Vertical Block

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

typedef TableColumn = Array<String>
typedef TableLine = Array<TableColumn>

enum BookElement {
    BookDiv(name:Null<String>, isNumbered:Bool, content:Array<BookElement>);
    BookFigure(name:Null<String>, isNumbered:Bool, content:FigureContents);
    BookTable(name:Null<String>, isNumbered:Bool, content:Array<TableLine>);
    BookEquation(name:Null<String>, isNumbered:Bool, content:Array<SourceText>);
    BookText(name:Null<String>,  content:Array<SourceText>);
}

class Brtparse
{
   static function main()
   {
        haxe.Log.trace = function (msg:String, ?pos:haxe.PosInfos)
                Sys.stderr().writeString('${pos.fileName}:${pos.lineNumber}: $msg\n');
        
        if (Sys.args().length!=2) {
            trace( 'wrong number of args: need two files');
            displayUsageAndExit();
        } 
        if (!FileSystem.exists(Sys.args()[0])){
            trace ('file not found:' + Sys.args()[0]);
            displayUsageAndExit();
        }
        trace('reading from  ${Sys.args()[0]} and writting to ${Sys.args()[1]}');
        var vBlocks = ParseIntoVBlocks (Sys.args()[0]);
        trace ('Done spliting file in vertical blocks. It has ${vBlocks.length} vBlocks.');
        promptTestParsedParagraphs(vBlocks,Sys.args()[1]);
//        var book = CreateBookDiv ("BRTPG", 0, false, ParseIntoDivs(parast));
   }

//    public static function CreateBookDiv (name:Null<String>, level:Int, isNumbered:Bool, parast:<Array<Array<TextChunk>>):BookElement
//    {
//        while (parast.length>0) {
//            par = parast.shift()
//            if IsDivOper(par)
//                var div=BookDiv(divName(par),ParseintoDivs(parast))
//            else {
//                EltoDiv(
//            }
//       for (par in prebook){
//
//
//           if (IsNewDiv (par)) curDiv = 
//       }
//
//   }
//
//    public static function EltoDiv(div:BookElement,bel:BookElement):Bool {
//        switch div{
//            case BookDiv(_,cont):
//                content.push(bel);
//                return true;
//            default:
//                return false;
//        }
//    }

    // A Vertical Block (VBlock) is text between aparently empty lines (only tabs spaces and CharCodes between 9 and 13)
    // Lines starting with % are ignored 
    public static function ParseIntoVBlocks(filePath:String):Array<VBlock>
    {
        var pipeinCommand = {description:"Change Input to given file", nArgs:1, matchPattern:~/^\\pipein\{(.+)\}$/i};
        var filePathSplit = filePath.split("/");
        var fileName = filePathSplit.pop();
        var fileDir = filePathSplit.join("/");
        trace ('Parsing file $filePath into VBlocks');
        var fullstr = File.getContent(filePath);
        var noCrlines = fullstr.replace( "\r", "");
        var lines = noCrlines.split("\n");
        var count = 0;
        var bookBlocks:Array<VBlock> = [];
        var curVBlock:VBlock = []; 
        for (li in lines){
            count = count+1;
            if (li.startsWith("%")) continue;
            if (looksBlank(li)){
                if (curVBlock.length>0){
                    bookBlocks.push (curVBlock);
                    curVBlock = [];
                }
            } else {
                if (curVBlock.length>0) {
                    curVBlock[curVBlock.length-1].textContent =  curVBlock[curVBlock.length-1].textContent + " ";
                }
                if (!li.startsWith("\\pipein")) {
                    curVBlock.push({filename:fileName, line:count, textContent:li});
                } else {
                    var pipeInFileName:String = "";
                    if (pipeinCommand.matchPattern.match(li.trim())) 
                        pipeInFileName = pipeinCommand.matchPattern.matched(1);
                    else {
                        trace ('argument to \\pipein do not match in line $count of file $fileName\n -->$li' );
                        Sys.exit(1);
                    }
                    var prevWorkDir = Sys.getCwd();
                    if (fileDir != "") Sys.setCwd(fileDir);
                    if (!FileSystem.exists(pipeInFileName)){
                        trace ('file to \\pipein not found: $pipeInFileName (in line $count of file $fileName)' );
                        Sys.exit(1);
                    }
                    trace ('Piping: $pipeInFileName (from line $count of file $fileName)' );
                    var fileBlocks = ParseIntoVBlocks(pipeInFileName);
                    if (curVBlock.length>0 && fileBlocks.length>0) {
                        for (sText in curVBlock) fileBlocks[0].unshift(sText);
                    }
                    curVBlock = fileBlocks.pop();
                    for (subVBlock in fileBlocks) bookBlocks.push(subVBlock);
                    Sys.setCwd(prevWorkDir);
                    trace ('DONE piping: $pipeInFileName' );
                }
            }
        }  
        trace ('DONE parsing file = $filePath into Paragraphs');
        return bookBlocks;
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

    //Just saving intitial manual intitial testing code (not for frinedly use)
    static function promptTestParsedParagraphs(bookBlocks:Array<VBlock>,?filePath:Null<String>)
    {
        trace('\n Enter paragraph to display (0 for exit)' );
        var input = Std.parseInt(Sys.stdin().readLine());
        while (input!=0){
            var parcontent = "" ;
            var firstline = Math.POSITIVE_INFINITY;
            var lastline = Math.NEGATIVE_INFINITY;
            for (sourceText in bookBlocks[input-1]) {
                parcontent = parcontent + sourceText.textContent;
                firstline = Math.min(firstline, sourceText.line);
                lastline = Math.max(lastline, sourceText.line);
            }
            trace ("\n " + parcontent
                    + "\n lines:" + firstline + "-" + lastline
                    + "\n Enter new paragraph to display (0 for saveContent)" );
            input = Std.parseInt(Sys.stdin().readLine());
        }
        File.saveContent(filePath,Serializer.run(bookBlocks));
    }
}
