import Brtparse;
import utest.Assert;

/**
	Unit tests using 'utest'. Basic Example applied 
    The methods that teststuff should be named testXXXX
    if function named setup exits will be executed before each test
    if function named teardown exits will be executed after each test

**/
class UTest {
	function testParseIntoParagraphArraySerializedFiles()
	{
		trace('running ParseIntoParagraphs file based tests:');
		for (f in sys.FileSystem.readDirectory(".")) {
			if (!sys.FileSystem.isDirectory(f) && StringTools.endsWith(f, ".inp") && sys.FileSystem.exists(StringTools.replace(f, ".inp", ".out"))) {
				trace('running test $f');
				var exp = sys.io.File.getContent(StringTools.replace(f, ".inp", ".out"));
				var got = haxe.Serializer.run(Brtparse.ParseIntoParagraphs(f));
				Assert.equals(exp, got);
			}
		}
	}


	function new() {}

	static function main()
	{
		var runner = new utest.Runner();
		runner.addCase(new UTest());
		utest.ui.Report.create(runner);
		runner.run();
	}
}

