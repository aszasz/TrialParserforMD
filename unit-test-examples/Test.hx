import Main.Ast;

/**
	Basic unit tests with 'haxe.unit'.

	Works ok for simple things, but I strongly recomend 'utest' unless you
	can't handle the extra dependency.
**/
class Test extends haxe.unit.TestCase {
	function testFiles()
	{
		trace('running file based tests:');
		for (f in sys.FileSystem.readDirectory(".")) {
			if (!sys.FileSystem.isDirectory(f) && StringTools.endsWith(f, ".inp")) {
				trace('running test $f');
				var inp = sys.io.File.getContent(f);
				var exp = StringTools.trim(sys.io.File.getContent(StringTools.replace(f, ".inp", ".out")));
				var got = StringTools.trim(Std.string(Main.doSomething(inp)));
				this.assertEquals(exp, got);
			}
		}
	}

	function testManual()
	{
		this.assertEquals(Std.string(ERoot([])), Std.string(Main.doSomething("")));
		// the Std.string hack is necessary to avoid
		// expected 'ERoot([])' but was 'ERoot([])'
		// with the more straighforward method bellow
		this.assertEquals(ERoot([]), Main.doSomething(""));
	}

	static function main()
	{
		var runner = new haxe.unit.TestRunner();
		runner.add(new Test());
		runner.run();
	}
}

