class TestCharpos {
    
    static function main() {
        var name = "\\pipein{1234567890}";
        var name1 = "\\pipein{12345678}ooops";
        var name2 = "\\pipein {1234567890}";
       
        var matchPattern = ~/\\pipein\{(.+)\}$/i;

        if (matchPattern.match(name)) trace ("match, parameter=" + matchPattern.matched(1));
        if (matchPattern.match(name1)) trace ("match, parameter=" +  matchPattern.matched(1));
        if (matchPattern.match(name2)) trace ("match, parameter=" +  matchPattern.matched(1));

    }



}
