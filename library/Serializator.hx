import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
using Lambda;

private typedef SuperClass = Null<{ t:Ref<ClassType>, params:Array<Type> }>;

class Serializator
{
	public static macro function build() : Array<Field>
	{
		var klass = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		
		var activeFields = [];
		for (field in fields)
		{
			if (field.name == "hxSerialize" || field.name == "hxUnserialize")
			{
				Context.fatalError("Serializator: method " + field.name + "() must not exists.", field.pos);
				return null;
			}
			if (!hasMeta(field, ":noSerialize"))
			{
				switch (field.kind)
				{
					case FieldType.FVar(_): activeFields.push(field);
					case FieldType.FProp(get, set, _, _):
						if (get == "default" || set == "default") activeFields.push(field);
					case FieldType.FFun(_): // nothing to do
				}
			}
		}
		
		if (activeFields.length > 0)
		{
			Context.getType("haxe.Serializer");
			Context.getType("haxe.Unserializer");
			
			var serCodes = activeFields.map(function(f)
			{
				var name = f.name;
				return macro s.serialize(this.$name);
			});
			appendCode(createHxSerializeMethod(fields, klass.superClass), macro $b{serCodes});
			
			var unserCodes = activeFields.map(function(f)
			{
				var name = f.name;
				return macro this.$name = s.unserialize();
			});
			appendCode(createHxUnserializeMethod(fields, klass.superClass), macro $b{unserCodes});
			
			return fields;
		}
		
		return null;
	}
	
	static function appendCode(f:Function, code:Expr)
	{
		switch (f.expr.expr)
		{
			case EBlock(exprs):
				exprs.push({ expr:code.expr, pos:code.pos });
				
			case _:
				f.expr = macro { ${f.expr}; $code; };
		}
	}
	
	static function createHxSerializeMethod(fields:Array<Field>, superClass:SuperClass) : Function
	{
		var method : Field = null;
		
		var superField = getSuperClassField("hxSerialize", superClass);
		if (superField != null)
		{
			var superFuncArgs = getClassMethodArgs(superField);
			var superCall = ECall(macro super.hxSerialize, superFuncArgs.map(function(p) return macro $i{p.name}));
			method = createMethod(superField.isPublic, "hxSerialize", superFuncArgs, macro:Void, { expr:superCall, pos:Context.currentPos() });
			method.access.push(Access.AOverride);
		}
		else
		{
			method = createMethod(false, "hxSerialize", [ { name:"s", type:(macro:haxe.Serializer) } ], macro:Void, macro {});
		}
		fields.push(method);
		
		switch (method.kind)
		{
			case FieldType.FFun(f):
				return f;
				
			case _:
				Context.fatalError("Serializator: unexpected hxSerialize() method type '" + method.kind + "'.", method.pos);
				return null;
		}
	}
	
	static function createHxUnserializeMethod(fields:Array<Field>, superClass:SuperClass) : Function
	{
		var method : Field = null;
		
		var superField = getSuperClassField("hxUnserialize", superClass);
		if (superField != null)
		{
			var superFuncArgs = getClassMethodArgs(superField);
			var superCall = ECall(macro super.hxUnserialize, superFuncArgs.map(function(p) return macro $i{p.name}));
			method = createMethod(superField.isPublic, "hxUnserialize", superFuncArgs, macro:Void, { expr:superCall, pos:Context.currentPos() });
			method.access.push(Access.AOverride);
		}
		else
		{
			method = createMethod(false, "hxUnserialize", [ { name:"s", type:(macro:haxe.Unserializer) } ], macro:Void, macro {});
		}
		fields.push(method);
		
		switch (method.kind)
		{
			case FieldType.FFun(f):
				return f;
				
			case _:
				Context.fatalError("Serializator: unexpected hxUnserialize() method type '" + method.kind + "'.", method.pos);
				return null;
		}
	}
	
	static function hasMeta(f:{ meta:Metadata }, m:String) : Bool
	{
		if (f.meta == null) return false;
		for (mm in f.meta)
		{
			if (mm.name == m) return true;
		}
		return false;
	}
	
	static function createMethod(isPublic:Bool, name:String, args:Array<FunctionArg>, ret:Null<ComplexType>, expr:Expr) : Field
	{
		return
		{
			  name: name
			, access: [ isPublic ? Access.APublic : Access.APrivate ]
			, kind: FieldType.FFun({ args:args, ret:ret, expr:expr, params:[] })
			, pos: expr.pos
		};
	}
	
	
	
	static function getSuperClassField(name:String, superClass:SuperClass) : ClassField
	{
		while (superClass != null)
		{
			var c = superClass.t.get();
			if (name == "new" && c.constructor != null) return c.constructor.get();
			var fields = c.fields.get().filter(function(f) return f.name == name);
			if (fields.length > 0) return fields[0];
			superClass = c.superClass;
		}
		return null;
	}
	
	static function getClassMethodArgs(field:ClassField) : Array<FunctionArg>
	{
		switch (field.type)
		{
			case Type.TFun(args, ret): return args.map(toFunctionArg);
			case Type.TLazy(f):
				switch (f())
				{
					case Type.TFun(args, ret): return args.map(toFunctionArg);
					case _:
				}
			case _:
		}
		Context.fatalError("Expected TFun: " + field.type, field.pos);
		return null;
	}
	
	static function toFunctionArg(a:{ name:String, opt:Bool, t:Type }) : FunctionArg
	{
		return { name: a.name, opt: a.opt, type: a.t.toComplexType(), value: null };
	}
}
