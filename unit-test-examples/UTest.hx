import Main.Ast;
import utest.Assert;

/**
	Unit tests using 'utest'.

	Better reports, better progress estimates (count assertions, not test
	methods), and better handling of objects with `Assert.same`.
**/
class UTest {
	function testFiles()
	{
		trace('running file based tests:');
		for (f in sys.FileSystem.readDirectory(".")) {
			if (!sys.FileSystem.isDirectory(f) && StringTools.endsWith(f, ".inp")) {
				trace('running test $f');
				var inp = sys.io.File.getContent(f);
				var exp = StringTools.trim(sys.io.File.getContent(StringTools.replace(f, ".inp", ".out")));
				var got = StringTools.trim(Std.string(Main.doSomething(inp)));
				Assert.equals(exp, got);
			}
		}
	}

	function testManual()
	{
		Assert.same(ERoot([]),Main.doSomething(""));
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

