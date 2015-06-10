# serializator #

A build macro to exclude specified class fields from serialization.
Generate hxSerialize() and hxUnserialize() methods for class fields not marked with `@:noSerialize`.

Usage
```
#!haxe
@:build(Serializator.build()) 
@:autoBuild(Serializator.build()) 
class Car
{
	var speed = 100;
	
	@:noSerialize
	var cache : String;
	
	// ====== Generate: ======
	//function hxSerialize(s:haxe.Serializer)
	//{
	//    s.serialize(speed);
	//}
	//function hxUnserialize(s:haxe.Unserializer)
	//{
	//    speed = s.unserialize();
	//}
}

class ColoredCar extends Car
{
	var color = "red";
	
	// ====== Generate: ======
	//function hxSerialize(s:haxe.Serializer)
	//{
	//    super.hxSerialize(s);
	//    s.serialize(color);
	//}
	//function hxUnserialize(s:haxe.Unserializer)
	//{
	//    super.hxUnserialize(s);
	//    color = s.unserialize();
	//}
}
```
