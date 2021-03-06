module CIL.FFI

%default total

%access public export

||| The universe of foreign CIL types.
data CILTy =
  ||| a foreign reference type
  CILTyRef String String |
  ||| a foreign value type
  CILTyVal String String |
  ||| a foreign array type
  CILTyArr CILTy |
  ||| a foreign generic type
  CILTyGen CILTy (List CILTy) |
  ||| a foreign generic parameter of a generic type
  CILTyGenParam String |
  ||| a foreign generic parameter of a generic method
  CILTyGenMethodParam String

Eq CILTy where
  (CILTyGen def args) == (CILTyGen def' args') = def  == def' && assert_total (args == args')
  (CILTyRef as tn)    == (CILTyRef as' tn')    = as   == as'  && tn == tn'
  (CILTyVal as tn)    == (CILTyVal as' tn')    = as   == as'  && tn == tn'
  (CILTyArr elTy)     == (CILTyArr elTy')      = elTy == elTy'
  _                   == _                     = False

%inline
CILTyObj : CILTy
CILTyObj = CILTyRef "" "object"

%inline
CILTyStr : CILTy
CILTyStr = CILTyRef "" "string"

%inline
CILTyBool : CILTy
CILTyBool = CILTyVal "" "bool"

%inline
CILTyInt32 : CILTy
CILTyInt32 = CILTyVal "" "int"

%inline
CILTyChar : CILTy
CILTyChar = CILTyVal "" "char"

||| A foreign CIL type.
data CIL   : CILTy -> Type where
     MkCIL : (ty : CILTy) -> CIL ty

||| A foreign CIL array type.
data TypedArray   : CILTy -> Type -> Type where
     MkTypedArray : (ty : CILTy) -> (elemTy : Type) -> TypedArray ty elemTy

||| A foreign method calling convention.
data CILCallConv =
  ||| Static calling convention.
  CCCStatic |
  ||| Instance calling convention.
  CCCInstance

||| A foreign method descriptor.
data CILMethod =
  ||| A generic method given its calling convention, declaring type, name, type arguments, parameter types and return type.
  CILGenMethod CILCallConv CILTy String (List CILTy) (List CILTy) CILTy

||| A foreign descriptor.
data CILForeign =
  ||| Reference an external assembly by name, version and public key token.
  CILAssemblyRef String String String |
  ||| Call the given foreign method.
  CILCall CILMethod | -- TODO: replace all other method forms by this one and introduce helper functions instead
  ||| Call the named instance method.
  CILInstance String |
  ||| Call the named instance method with the given signature.
  CILInstanceCustom String (List CILTy) CILTy |
  ||| Read the value of the named instance field.
  CILInstanceField String |
  ||| Call the named static method of the given foreign type.
  CILStatic CILTy String |
  ||| Read the value of the named static field of the given foreign type.
  CILStaticField CILTy String |
  ||| Call a constructor to instantiate an object.
  CILConstructor |
  ||| Load the given runtime type.
  CILTypeOf CILTy |
  ||| Convert a function to a delegate of the given type.
  CILDelegate CILTy |
  ||| Export a function under the given name.
  CILExport String |
  ||| Export a function under its original name.
  CILDefault

||| A CIL enum type.
|||
||| @cilTy the external CIL type
||| @reprTy the native representation type (must be either Bits16 or Bits32)
data CILEnum : (cilTy : CILTy) -> (reprTy : Type) -> Type

mutual
  data CIL_IntTypes  : Type -> Type where
       CIL_IntChar   : CIL_IntTypes Char
       CIL_IntNative : CIL_IntTypes Int

  data CIL_Types : Type -> Type where
       CIL_Array : CIL_Types (TypedArray cilTy elTy)
       CIL_Str   : CIL_Types String
       CIL_Float : CIL_Types Double
       CIL_Ptr   : CIL_Types Ptr
       CIL_Bool  : CIL_Types Bool
       CIL_Unit  : CIL_Types ()
       CIL_IntT  : CIL_IntTypes i -> CIL_Types i
       CIL_CILT  : CIL_Types (CIL ty)
       CIL_FnT   : CIL_FnTypes fnT -> CIL_Types (CilFn delegateTy fnT)
       CIL_EnumT : CIL_Types (CILEnum cilTy reprTy)
       CIL_MaybeT : CIL_Types ty -> CIL_Types (Maybe ty)

  data CilFn   : CILTy -> Type -> Type where
       MkCilFn : (delegateTy : CILTy) -> (fn : fnT) -> CilFn delegateTy fnT

  data CIL_FnTypes : Type -> Type where
       CIL_Fn      : CIL_Types s -> CIL_FnTypes t -> CIL_FnTypes (s -> t)
       CIL_FnIO    : CIL_Types t -> CIL_FnTypes (IO' l t)
       CIL_FnBase  : CIL_Types t -> CIL_FnTypes t

%used MkCilFn fn

FFI_CIL : FFI
FFI_CIL = MkFFI CIL_Types CILForeign String

CIL_IO : Type -> Type
CIL_IO = IO' FFI_CIL

||| CIL FFI.
%inline
invoke : CILForeign -> (ty : Type) ->
         {auto fty : FTy FFI_CIL [] ty} -> ty
invoke ffi ty = foreign FFI_CIL ffi ty

%inline
new : (ty : Type) ->
      {auto fty : FTy FFI_CIL [] ty} -> ty
new ty = invoke CILConstructor ty

%inline
delegate : (ty : CILTy) -> (fnT : Type) -> fnT ->
           {auto fty : FTy FFI_CIL [] (CilFn ty fnT -> CIL_IO (CilFn ty fnT))} ->
           CIL_IO (CilFn ty fnT)
delegate ty fnT fn = invoke (CILDelegate ty)
                            (CilFn ty fnT -> CIL_IO (CilFn ty fnT))
                            (MkCilFn ty fn)
%inline
assemblyRef : String -> String -> String -> CIL_IO ()
assemblyRef assemblyName version pubKeyToken =
  invoke (CILAssemblyRef assemblyName version pubKeyToken) (CIL_IO ())

%inline
corlibTy : String -> CILTy
corlibTy = CILTyRef "mscorlib"

%inline
corlibTyVal : String -> CILTy
corlibTyVal = CILTyVal "mscorlib"

%inline
corlib : String -> Type
corlib = CIL . corlibTy

Object : Type
Object = CIL CILTyObj

%inline
RuntimeTypeTy : CILTy
RuntimeTypeTy = corlibTy "System.Type"

%inline
RuntimeType : Type
RuntimeType = CIL RuntimeTypeTy

%inline
typeOf : CILTy -> CIL_IO RuntimeType
typeOf t = invoke (CILTypeOf t) (CIL_IO RuntimeType)

-- inheritance can be encoded as class instances or implicit conversions
interface IsA a b where {}

IsA Object Object where {}
IsA Object String where {}
IsA Object Int where {}
IsA Object Integer where {}
IsA Object Bool where {}
IsA Object Double where {}
IsA Object RuntimeType where {}

%inline
asObject : IsA Object a => a -> Object
asObject a = believe_me a

ToString : IsA Object o => o -> CIL_IO String
ToString obj =
  invoke (CILInstance "ToString")
         (Object -> CIL_IO String)
         (asObject obj)

Equals : IsA Object a => a -> a -> CIL_IO Bool
Equals x y =
  invoke (CILInstance "Equals")
         (Object -> Object -> CIL_IO Bool)
         (asObject x) (asObject y)


namespace System.Array

  ArrayTy : CILTy
  ArrayTy = corlibTy "System.Array"

  Array : Type
  Array = CIL ArrayTy

  CreateInstance : RuntimeType -> Int -> CIL_IO Array
  CreateInstance =
    invoke (CILStatic ArrayTy "CreateInstance")
           (RuntimeType -> Int -> CIL_IO Array)

  SetValue : Array -> Object -> Int -> CIL_IO ()
  SetValue =
    invoke (CILInstance "SetValue")
           (Array -> Object -> Int -> CIL_IO ())


namespace System.Console

  ConsoleTy : CILTy
  ConsoleTy = corlibTy "System.Console"

  invokeConsole : String -> (ty: Type) -> {auto fty : FTy FFI_CIL [] ty} -> ty
  invokeConsole fn ty = invoke (CILStatic ConsoleTy fn) ty

  namespace Char

    Read : CIL_IO Int
    Read = invokeConsole "Read" (CIL_IO Int)

    Write : Char -> CIL_IO ()
    Write = invokeConsole "Write" (Char -> CIL_IO ())

  namespace String

    Write : String -> CIL_IO ()
    Write = invokeConsole "Write" (String -> CIL_IO ())

namespace System.Convert

  ToInt32 : IsA Object a => a -> CIL_IO Int
  ToInt32 o =
    invoke (CILStatic (corlibTy "System.Convert") "ToInt32")
           (Object -> CIL_IO Int)
           (asObject o)

namespace Enums

  export
  theEnum : reprTy -> CILEnum cilTy reprTy
  theEnum e = believe_me e

  export
  fromEnum : CILEnum cilTy reprTy -> reprTy
  fromEnum e = believe_me e

  export
  (+) : (Num reprTy) => CILEnum cilTy reprTy -> CILEnum cilTy reprTy -> CILEnum cilTy reprTy
  (+) lhs rhs = theEnum (fromEnum lhs + fromEnum rhs)

(Num reprTy) => Semigroup (CILEnum cilTy reprTy) where
  (<+>) = (+)

(Num reprTy) => Monoid (CILEnum cilTy reprTy) where
  neutral = theEnum 0

putStr : String -> CIL_IO ()
putStr = putStr'

putStrLn : String -> CIL_IO ()
putStrLn = putStrLn'

print : Show a => a -> CIL_IO ()
print = print'

printLn : Show a => a -> CIL_IO ()
printLn = printLn'
