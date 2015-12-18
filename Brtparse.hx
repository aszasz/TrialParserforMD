import haxe.io.Eof;
import haxe.Serializer;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.FileSystem;

using StringTools;


typedef CommandDef = {
    name: String,
    description:String,
    nArgs:Int,
    matchPattern:EReg
}


typedef SourceText = {
    filename: String,
    line:Int,
    textContent:String
}

enum TextChunkType {
    InLineMath;
    InLineCode;
    AlphaNumeric;
    ReplacementCommand;//(name:String, arg:String)
}

enum TextChunkEmphasis {
    None;
    FirstLevel;
    SecondLevel;
}

typedef TextChunk = {
    type:TextChunkType,
    emph:TextChunkEmphasis,
    hili:Bool, // short for highlighted
    text:String
}

typedef DisplayedText = Array<TextChunk>

typedef VBlock = Array <SourceText> //for Vertical Block

enum ImageSize {
    ImgSzSmall;
    ImgSzMedium;
    ImgSzLarge;
    ImgSzHuge;
}

typedef FigureContents = {
    path:String,
    size:ImageSize,
    caption:Null<String>
}

typedef TableCell = Array<String>
typedef TableLine = Array<TableColumn>

typedef BECA = {  //standing for BookElementsCommonAttributes
    name: Null<String>,
    label: Null<String>,
    source: Null<VBlock>,
    hasNum: Bool
}

enum VBlockType {
    DivHeader(level:Int);
    BoxHeader;
    BoxClosing;
    IgnoreBlockHeader;
    CommentBlockHeader;
    CodeBlockHeader;
    Figure;
    Table;
    Equation;
    List;
    ParTitle;
    VSpace;

}

enum BookElement {
    Div(beca:BECA,  content:Array<BookElement>);
    Box(beca:BECA, content:Array<BookElement>);
    Figure(beca:BECA, content:FigureContents);
//    Table(beca:BECA, content:Array<TableLine>);
//    Equation(beca:BECA, content:Array<SourceText>);
    Text(beca:BECA, content:DisplayedText);
//    List(beca:BECA, content:DisplayedText)
//    CodeBlock(beca:BECA);
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
            trace('file not found:' + Sys.args()[0]);
            displayUsageAndExit();
        }
        trace('reading from  ${Sys.args()[0]} and writting to ${Sys.args()[1]}');
        var vBlocks = ParseIntoVBlocks (Sys.args()[0]);
        trace ('Done spliting file in vertical blocks. It has ${vBlocks.length} vBlocks.');
//        promptTestParsedParagraphs(vBlocks,Sys.args()[1]);
        var book = createBookDiv ({"BRTPG","brtpg", 0, false, vBlocks);
   }

    public static function createBookDiv (beca: BECA, level:Int, isBox:Bool, vBlocks:Array<VBlock>):BookElement
    {
        if (label==null) label=Label
        var content:Array<BookElements>=[];
        while (vBlocks.length>0) {
            vBlock =  vBlocks.shift();
            switch getVBlockType(vBlock) {
                case DivHeader(lv):
                    if (isBox) error ('create division inside box ${beca.name} is not allowed. \n ${displayBlockInfo(vBlock)}');
                    if (lv<=level) {
                        vBlocks.unshift(vBlock);
                        if (content.length == 0) error('div ${beca.name} has no content.  ${displayBlockInfo(beca.source)}');
                        return Div(beca,content)
                    } 
                    if (lv==level+1) {
                        createBookDiv (parseDivHeader(vBlock), lv, false, vBlocks);
                    }
                    if (lv>level+1) error ('creating div level $lv direct bellow div level $level - ${beca.name}
                                            is not allowed. \n ${displayBlockInfo(vBlock)}');
                case BoxHeader:
                    if (isBox) error ('creating box inside box ${beca.name} is not allowed.  ${displayBlockInfo(vBlock)}');
                case BoxClosing:
                    if (content.length == 0) error('box ${beca.name} has no content. ${displayBlockInfo(beca.source)}');
                    return Box(beca,content)
                case IgnoreBlockHeader:
                    getCodeBlockEnd(vBlock, vBlocks);
                case CommentBlockHeader:
                    getCommentBlockEnd(vBlock, vBlocks);
                case CodeBlockHeader:
                    content.push getCodeBlockEnd(vBlock, vBlocks);
                default:
                    content.push parseElement(vBlock);
            }
            if (content.length == 0) error('div ${beca.name} has no content.  ${displayBlockInfo(beca.source)}');
            return Div(beca,content);
        }
    }

    public static function getVBlockType(vBlock:VBlock):VBlockType 
    {
        
    }


            if (vBlock[0].textContent.startsWith() == "#" ){
                if (isBox) {
                    trace ('try to add div inside block $name \n $displayBlockInfo(vBlock)' );
                    Sys.exit(1);
                }
                var divinfo = getDivInfo(vBlock);
                divlevel=0;
                while 
            
            } 
            if (!vBlock[0].textContent.startsWith() == "[[[" ) {
            switch
            
            }    
                if (!eltoDiv(myself, {null,vBlock} )) {
                    trace ('failed to add vBlock argument to div \n $displayBlockInfo(vBlock)' );
                    Sys.exit(2);
                }
                continue;
            }
            var div = parseDivHeader(vblock)
            if (divLevel>=level){
                vBlocks.unshift(vBlock);
                if (isBox)
                    return Box(name,isNumbered, content);
                else
                    return Div(name, isNumbered, content);

            } else {
            if (!isDivHeader(vBlock))
                if (!eltoDiv(myself, createBookDiv(div.name,div.level,div.isNumbered,vBlocks)) {
                    trace ('failed to add vBlock argument to div \n $displayBlockInfo(vBlock)' );
                    Sys.exit(2);
            }
       
    static function getDivInfo(vBlock:VBlock):{name:String, level:Int, isNumbered:Bool}
    {
        
        var notnumberedCommand = {description:"In a div header to inform that the div shall not be counted in the numbering tree", nArgs:0, matchPattern:~/()\\notnumbered ()/i};
        for (sourceText in vBlock){
            if (notnumberedCommand.matchPattern.match(sourceText.textContent)){
                
                sourceText.textContent = notnumberedCommand.matchPattern.matched(1)  ;
            }
        } 

    }

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
        while (true){
            trace ('\n Enter new paragraph to display (0 for saveContent)' );
            var input = Std.parseInt(Sys.stdin().readLine());
            if (input==0) break;
            trace (displayVBlockInfo(bookBlocks[input-1]);
        }
        File.saveContent(filePath,Serializer.run(bookBlocks));
    }

    static function displayVBlockInfo (vBlock:VBlock, ?):Null<String>
    {
        if (vBlock.length == 0) return null
        var vBContent = "" 
        var firstline = Math.POSITIVE_INFINITY;
        var lastline = Math.NEGATIVE_INFINITY;
        var fileName = vBlock[0].fileName;
        for (sourceText in vBlock) {
            vBcontent = vBcontent + sourceText.textContent;
            firstline = Math.min(firstline, sourceText.line);
            lastline = Math.max(lastline, sourceText.line);
        }
        return ('\n from $fileName lines: $firstline - $lastline --> $vbContent');
    }

}
