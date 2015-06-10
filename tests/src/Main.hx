@:build(Serializator.build())
@:autoBuild(Serializator.build())
class BaseClass
{
    var a : Int;
	var b : String;
}

class TestClass extends BaseClass
{
	var c : String;
	
	@:noSerialize
	var d : String;
}

class Main
{
	static function main()
	{
	}
}

