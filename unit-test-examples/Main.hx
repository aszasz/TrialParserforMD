enum Ast {
	EText(text:String);
	EParagraph(contents:Array<Ast>);
	ERoot(contents:Array<Ast>);
}

class Main {
	// create an ast where, for each name (separated by newlines), there is a paragraph with 'Hello, $name!'
	public static function doSomething(fileContents:String)
	{
		var names = fileContents.split("\n");
		var validNames = Lambda.filter(names, function (x) return x != "");
		return ERoot([ for (n in validNames) EParagraph([EText("Hello, "), EText(n), EText("!")]) ]);
	}

	// pretty print the ast
	static function toString(gen:Ast)
	{
		return switch (gen) {
		case ERoot(vs):
			var buf = new StringBuf();
			for (v in vs)
				buf.add(toString(v));
			buf.toString();
		case EParagraph(vs):
			var buf = new StringBuf();
			for (v in vs)
				buf.add(toString(v));
			buf.add("\n\n");
			buf.toString();
		case EText(t):
			t;
		}
	}

	static function main()
	{
		var args = Sys.args();
		for (a in args) {
			var fileContents = sys.io.File.getContent(a);
			var gen = doSomething(fileContents);
			trace(gen);
			trace(toString(gen));
		}
	}
}

