#import <Cocoa/Cocoa.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/callback.h>

#include <string.h>
#include <alloca.h>

#define CAML_VALUE_IVAR "_caml_value"

value
  ARG_Void,
  ARG_Bool,
  ARG_Char,
  ARG_Int,
  ARG_Nativeint,
  ARG_Int64,
  ARG_Float,
  ARG_Id,
  ARG_Sel,
  ARG_NSPoint,
  ARG_NSRect,
  ARG_NSRange;

#undef alloc

static inline id
_unwrap_id(value wrapped_obj)
{
  return *((id*)Data_custom_val(wrapped_obj));
}

static void
_wrap_id_finalize(value wrapped_obj)
{
  [_unwrap_id(wrapped_obj) release];
}

static int
_wrap_id_compare(value wo1, value wo2)
{
  id o1 = _unwrap_id(wo1), o2 = _unwrap_id(wo2);

  if([o1 isEqual: o2])
    return 0;
  else if([o1 respondsToSelector: @selector(compare:)])
    return [o1 compare: o2];
  else
    return (o1 < o2)? -1 : ((o1 > o2)? 1 : 0);
}

static long
_wrap_id_hash(value wrapped_obj)
{
  return (long)[_unwrap_id(wrapped_obj) hash];
}

static struct custom_operations _wrap_id_ops = {
  "name.jcg.objc.id",
  _wrap_id_finalize,
  _wrap_id_compare,
  _wrap_id_hash,
  custom_serialize_default, // FIXME: serialize using NSCoding protocol
  custom_deserialize_default,
};

static struct custom_operations _wrap_struct_ops = {
  "name.jcg.objc.struct",
  custom_finalize_default,
  custom_compare_default, // FIXME: comparison & serialization for structs
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
};

static NSAutoreleasePool *ocaml_objc_pool;

static value
_wrap_id(id obj)
{
  CAMLparam0();
  CAMLlocal1(wrapped_obj);

  wrapped_obj = caml_alloc_custom(&_wrap_id_ops, sizeof(id), 1, 1024); // FIXME: last two values are BS
  *((id*)Data_custom_val(wrapped_obj)) = [obj retain];

  CAMLreturn(wrapped_obj);
}

static value
_wrap_struct_f(const void *obj, size_t size)
{
  CAMLparam0();
  CAMLlocal1(wrapped_obj);
  wrapped_obj = caml_alloc_custom(&_wrap_struct_ops, size, 1, 1024);
  memcpy(Data_custom_val(wrapped_obj), obj, size);

  CAMLreturn(wrapped_obj);
}

#define _wrap_struct(obj, type) (_wrap_struct_f(&obj, sizeof(type)))
#define _unwrap_struct(wrapped_obj, type) (*(type*)Data_custom_val(wrapped_obj))

#define _wrap_nspoint(obj) _wrap_struct(obj, NSPoint)
#define _wrap_nsrect(obj)  _wrap_struct(obj, NSRect)
#define _wrap_nsrange(obj) _wrap_struct(obj, NSRange)

#define _wrap_sel(sel) ((value)sel)
#define _unwrap_sel(obj) ((SEL)obj)

CAMLprim value
ocaml_objc_nspoint_make(value x, value y)
{
  CAMLparam2(x, y);
  
  NSPoint p = NSMakePoint(Double_val(x), Double_val(y));

  CAMLreturn(_wrap_struct(p, NSPoint));
}

CAMLprim value
ocaml_objc_nspoint_x(value wrapped_nspoint)
{
  CAMLparam1(wrapped_nspoint);
  CAMLreturn( caml_copy_double( _unwrap_struct(wrapped_nspoint, NSPoint).x ) );
}

CAMLprim value
ocaml_objc_nspoint_y(value wrapped_nspoint)
{
  CAMLparam1(wrapped_nspoint);
  CAMLreturn( caml_copy_double( _unwrap_struct(wrapped_nspoint, NSPoint).y ) );
}

CAMLprim value
ocaml_objc_nsrect_make(value x, value y, value w, value h)
{
  CAMLparam4(x, y, w, h);

  NSRect r = NSMakeRect(Double_val(x), Double_val(y),
                         Double_val(w), Double_val(h));

  CAMLreturn(_wrap_struct(r, NSRect));
}

CAMLprim value
ocaml_objc_nsrect_origin(value wrapped_nsrect)
{
  CAMLparam1(wrapped_nsrect);
  CAMLreturn( _wrap_struct( _unwrap_struct(wrapped_nsrect, NSRect).origin, NSPoint ) );
}

CAMLprim value
ocaml_objc_nsrect_size(value wrapped_nsrect)
{
  CAMLparam1(wrapped_nsrect);
  CAMLreturn( _wrap_struct( _unwrap_struct(wrapped_nsrect, NSRect).size, NSPoint ) );
}

CAMLprim value
ocaml_objc_nsrange_make(value location, value length)
{
  CAMLparam2(location, length);

  NSRange r = NSMakeRange(Nativeint_val(location), Nativeint_val(length));

  CAMLreturn( _wrap_struct(r, NSRange) );
}

CAMLprim value
ocaml_objc_nsrange_location(value wrapped_nsrange)
{
  CAMLparam1(wrapped_nsrange);
  CAMLreturn( caml_copy_nativeint( _unwrap_struct(wrapped_nsrange, NSRange).location ) );
}

CAMLprim value
ocaml_objc_nsrange_length(value wrapped_nsrange)
{
  CAMLparam1(wrapped_nsrange);
  CAMLreturn( caml_copy_nativeint( _unwrap_struct(wrapped_nsrange, NSRange).length ) );
}

CAMLprim value
ocaml_objc_initialize(value unit)
{
  CAMLparam1(unit);

  ARG_Void      = hash_variant("Void");
  ARG_Bool      = hash_variant("Bool");
  ARG_Char      = hash_variant("Char");
  ARG_Int       = hash_variant("Int");
  ARG_Nativeint = hash_variant("Nativeint");
  ARG_Int64     = hash_variant("Int64");
  ARG_Float     = hash_variant("Float");
  ARG_Id        = hash_variant("Id");
  ARG_Sel       = hash_variant("Sel");
  ARG_NSPoint   = hash_variant("NSPoint");
  ARG_NSRect    = hash_variant("NSRect");
  ARG_NSRange   = hash_variant("NSRange");

  ocaml_objc_pool = [[NSAutoreleasePool alloc] init];

  CAMLreturn(Val_unit);
}

CAMLprim value
ocaml_objc_finalize(value unit)
{
  CAMLparam1(unit);

  [ocaml_objc_pool release];

  CAMLreturn(Val_unit);
}

CAMLprim value
ocaml_objc_nil(value unit)
{
  CAMLparam1(unit);

  CAMLreturn( _wrap_id(nil) );
}

CAMLprim value
ocaml_objc_sel(value selName)
{
  CAMLparam1(selName);

  CAMLreturn( _wrap_sel( sel_registerName( String_val(selName) ) ) );
}

CAMLprim value
ocaml_objc_clas(value clasName)
{
  CAMLparam1(clasName);

  CAMLreturn( _wrap_id( objc_getClass( String_val(clasName) ) ) );
}

#define _THROW_TYPE_MISMATCH(type)                                      \
  @throw [NSException exceptionWithName: NSInvalidArgumentException     \
                      reason: [NSString stringWithFormat:               \
                                          @"[ocaml-objc] Expected arg %d to be type '%s' but got type '%s'", \
                                        _n_, _arg_type_, @encode(type) ] \
                      userInfo: [NSDictionary dictionary]];

#define _SET_INVOCATION_ARG_IF_TYPE(argv, type)         \
  if( strcmp(_arg_type_, @encode(type)) == 0 )          \
    ({                                                  \
      type _v_ = (argv);                                \
      [invocation setArgument: &_v_ atIndex: _n_];      \
    })

#define SET_INVOCATION_ARG(argn, argv, type)                            \
  ({                                                                    \
    unsigned _n_ = (argn);                                              \
    const char *_arg_type_ = [sig getArgumentTypeAtIndex: _n_];         \
    _SET_INVOCATION_ARG_IF_TYPE(argv, type);                            \
    else _THROW_TYPE_MISMATCH(type);                                    \
  })

#define SET_INVOCATION_NSPOINT_ARG(argn, argv)                  \
  ({                                                            \
    unsigned _n_ = (argn);                                      \
    const char *_arg_type_ = [sig getArgumentTypeAtIndex: _n_]; \
    _SET_INVOCATION_ARG_IF_TYPE(_unwrap_struct(argv, NSPoint), NSPoint);    \
    else _SET_INVOCATION_ARG_IF_TYPE(_unwrap_struct(argv, NSSize), NSSize); \
    else _THROW_TYPE_MISMATCH(NSPoint);                         \
  })

#define SET_INVOCATION_INT_ARG(argn, argv)                      \
  ({                                                            \
    unsigned _n_ = (argn);                                      \
    const char *_arg_type_ = [sig getArgumentTypeAtIndex: _n_]; \
    _SET_INVOCATION_ARG_IF_TYPE(argv, long long);               \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, unsigned long long); \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, long);               \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, unsigned long);      \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, int);                \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, unsigned);           \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, short);              \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, unsigned short);     \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, char);               \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, unsigned char);      \
    else _THROW_TYPE_MISMATCH(int);                             \
  })

#define SET_INVOCATION_FLOAT_ARG(argn, argv)                    \
  ({                                                            \
    unsigned _n_ = (argn);                                      \
    const char *_arg_type_ = [sig getArgumentTypeAtIndex: _n_]; \
    _SET_INVOCATION_ARG_IF_TYPE(argv, double);                  \
    else _SET_INVOCATION_ARG_IF_TYPE(argv, float);              \
    else _THROW_TYPE_MISMATCH(float);                           \
  })

#define GET_INVOCATION_RET_IF_TYPE(type, tag, convert)  \
  if( strcmp(returnType, @encode(type)) == 0 ) ({       \
    type r = *(type*)returnBuf;                         \
    retTag = (tag);                                     \
    retParam = convert(r);                              \
  })

#define MAX_NATIVE_LONG ((long)(((unsigned long)-1L) >> 1))
#define MIN_NATIVE_LONG ((long)(~MAX_NATIVE_LONG))

#define GET_INVOCATION_RET_INT_IF_TYPE(type)            \
  if( strcmp(returnType, @encode(type)) == 0 )          \
    ({                                                  \
      type r = *(type*)returnBuf;                       \
      if(r > MAX_NATIVE_LONG || r < MIN_NATIVE_LONG) {  \
        retTag = ARG_Int64;                             \
        retParam = caml_copy_int64(r);                  \
      }                                                 \
      else if(r > Max_long || r < Min_long) {           \
        retTag = ARG_Nativeint;                         \
        retParam = caml_copy_nativeint(r);              \
      }                                                 \
      else {                                            \
        retTag = ARG_Int;                               \
        retParam = Val_int(r);                          \
      }                                                 \
    })

#define GET_INVOCATION_RET_UINT_IF_TYPE(type)           \
  if( strcmp(returnType, @encode(type)) == 0 )          \
    ({                                                  \
      type r = *(type*)returnBuf;                       \
      if(r > MAX_NATIVE_LONG) {                         \
        retTag = ARG_Int64;                             \
        retParam = caml_copy_int64(r);                  \
      }                                                 \
      else if(r > Max_long) {                           \
        retTag = ARG_Nativeint;                         \
        retParam = caml_copy_nativeint(r);              \
      }                                                 \
      else {                                            \
        retTag = ARG_Int;                               \
        retParam = Val_int(r);                          \
      }                                                 \
    })

value *
_find_caml_value_ivar(Class class)
{
  for(int i = 0; i < class->ivars->ivar_count; ++i) {
    struct objc_ivar *ivar = &class->ivars->ivar_list[i];
    if( strcmp(ivar->ivar_name, CAML_VALUE_IVAR) == 0 ) {
      return (value*)((char*)obj + ivar->ivar_offset);
    }
  }
  
  return nil;
}

CAMLprim value
ocaml_objc_caml_set_value(value wrapped_obj, value new_value)
{
  CAMLparam1(wrapped_obj);
  
  value *val = _find_caml_value_ivar( _unwrap_id(wrapped_obj)->isa );
  if(val)
    *val = new_value;
  else
    caml_failwith("set_caml_value called on object without _caml_value ivar");
    
  CAMLreturn(Val_unit);
}

CAMLprim value
ocaml_objc_caml_value(value wrapped_obj)
{
  CAMLparam1(wrapped_obj);

  value *val = _find_caml_value_ivar( _unwrap_id(wrapped_obj)->isa );
  if(!val)
    caml_failwith("caml_value called on object without _caml_value ivar");

  CAMLreturn( *var );
}

CAMLprim value
ocaml_objc_def_clas(value wrapped_superclass, value class_methods, value instance_methods, value wrapped_classname)
{
  CAMLparam3(wrapped_superclass, classname, method_list);
  CAMLlocal2(wrapped_class);
  
  Class superclass;
  if(wrapped_superclass == Val_int(0)) // None
    superclass = [NSObject class];
  else // Some class
    superclass = [_unwrap_id(Field(wrapped_superclass, 0)) class];
  
  char *classname = String_val(wrapped_classname);
  if(objc_lookUpClass(classname))
    caml_failwith("def_clas trying to define class that already exists");
  else {
    Class class, metaclass, rootclass;
    
    rootclass = superclass;
    while(rootclass->super_class)
      rootclass = rootclass->super_class;
    
    class = (Class)calloc(2, sizeof(struct objc_class));
    metaclass = class + 1;
    
    class->isa = metaclass;
    class->info = CLS_CLASS;
    class->name = strdup(classname);
    class->super_class = superclass;
    class->instance_size = superclass->instance_size + sizeof(value);
    class->methodLists = _methods_from_list(instance_methods);
    
    if(!_find_caml_value_ivar(superclass)) {
      class->ivars = (struct objc_ivar_list*)malloc(sizeof(obj_ivar_list));
      class->ivars->ivar_count = 1;
      class->ivars->ivar_list[0]->ivar_name = CAML_VALUE_IVAR;
      class->ivars->ivar_list[0]->ivar_type = @encode(value);
      class->ivars->ivar_list[0]->ivar_offset = superclass->instance_size;
    }
    
    metaclass->isa = rootclass->isa;
    metaclass->info = CLS_META;
    metaclass->name = class->name;
    metaclass->super_class = superclass->isa;
    metaclass->instance_size = superclass->isa->instance_size;
    metaclass->methodLists = _methods_from_list(class_methods);
    
    objc_addClass(class);
  }
}

CAMLprim value
ocaml_objc_send(value wrapped_obj, value wrapped_sel, value args)
{
  CAMLparam3(wrapped_obj, wrapped_sel, args);
  CAMLlocal2(retVal, retParam);
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  id obj = _unwrap_id(wrapped_obj);
  SEL sel = _unwrap_sel(wrapped_sel);

  @try {
    NSMethodSignature *sig = obj
      ? [obj methodSignatureForSelector: sel]
      : [NSObject instanceMethodSignatureForSelector: sel];
    if(!sig)
      @throw [NSException exceptionWithName: NSInvalidArgumentException
                          reason: [NSString stringWithFormat: @"[ocaml-objc] Got nil method signature for object '%@', selector '%s'", obj, sel_getName(sel)]
                          userInfo: [NSDictionary dictionary]];

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: sig];
    [invocation setSelector: sel];
    [invocation setTarget: obj];

    value argCursor;
    unsigned i;
    for(argCursor = args, i = 2;
        argCursor != Val_int(0);
        argCursor = Field(argCursor, 1), ++i) {

      value arg = Field(argCursor, 0);
      value arg_tag = Field(arg, 0);
      value argv = Field(arg, 1);

      if(arg_tag == ARG_Bool) {
        SET_INVOCATION_ARG(i, Bool_val(argv)? YES : NO, BOOL);
      }
      else if(arg_tag == ARG_Char || arg_tag == ARG_Int) {
        SET_INVOCATION_INT_ARG(i, Int_val(argv));
      }
      else if(arg_tag == ARG_Nativeint) {
        SET_INVOCATION_INT_ARG(i, Nativeint_val(argv));
      }
      else if(arg_tag == ARG_Int64) {
        SET_INVOCATION_INT_ARG(i, Int64_val(argv));
      }
      else if(arg_tag == ARG_Float) {
        SET_INVOCATION_FLOAT_ARG(i, Double_val(argv));
      }
      else if(arg_tag == ARG_Id) {
        SET_INVOCATION_ARG(i, _unwrap_id(argv), id);
      }
      else if(arg_tag == ARG_Sel) {
        SET_INVOCATION_ARG(i, _unwrap_sel(argv), SEL);
      }
      else if(arg_tag == ARG_NSPoint) {
        SET_INVOCATION_NSPOINT_ARG(i, argv);
      }
      else if(arg_tag == ARG_NSRect) {
        SET_INVOCATION_ARG(i, _unwrap_struct(argv, NSRect), NSRect);
      }
      else if(arg_tag == ARG_NSRange) {
        SET_INVOCATION_ARG(i, _unwrap_struct(argv, NSRange), NSRange);
      }
    }
    if(i != [sig numberOfArguments])
      @throw [NSException exceptionWithName: NSInvalidArgumentException
                          reason: [NSString stringWithFormat: @"[ocaml-objc] Method '%s' takes %u arguments but was only given %u",
                                            sel_getName(sel), [sig numberOfArguments] - 2, i - 2]
                          userInfo: [NSDictionary dictionary]];

    [invocation invoke];
    
    if([sig methodReturnLength] == 0) {
      retVal = ARG_Void;
    }
    else {
      void *returnBuf = alloca([sig methodReturnLength]);
      int retTag;
      [invocation getReturnValue: returnBuf];
      const char *returnType = [sig methodReturnType];

      if( strcmp(returnType, @encode(char)) == 0
          || strcmp(returnType, @encode(unsigned char)) == 0 ) {
        char r = *(char*)returnBuf;
        if(r == YES || r == NO) {
          retTag = ARG_Bool;
          retParam = Val_bool(r);
        } else {
          retTag = ARG_Char;
          retParam = Val_int(r);
        }
      }
      else GET_INVOCATION_RET_INT_IF_TYPE(long long);
      else GET_INVOCATION_RET_UINT_IF_TYPE(unsigned long long);
      else GET_INVOCATION_RET_INT_IF_TYPE(long);
      else GET_INVOCATION_RET_UINT_IF_TYPE(unsigned long);
      else GET_INVOCATION_RET_INT_IF_TYPE(int);
      else GET_INVOCATION_RET_UINT_IF_TYPE(unsigned);
      else GET_INVOCATION_RET_IF_TYPE(short, ARG_Int, Val_int);
      else GET_INVOCATION_RET_IF_TYPE(unsigned short, ARG_Int, Val_int);
      else GET_INVOCATION_RET_IF_TYPE(float,  ARG_Float, caml_copy_double);
      else GET_INVOCATION_RET_IF_TYPE(double, ARG_Float, caml_copy_double);
      else GET_INVOCATION_RET_IF_TYPE(id, ARG_Id, _wrap_id);
      else GET_INVOCATION_RET_IF_TYPE(SEL, ARG_Sel, _wrap_sel);
      else GET_INVOCATION_RET_IF_TYPE(NSPoint, ARG_NSPoint, _wrap_nspoint);
      else GET_INVOCATION_RET_IF_TYPE(NSSize,  ARG_NSPoint, _wrap_nspoint);
      else GET_INVOCATION_RET_IF_TYPE(NSRect,  ARG_NSRect,  _wrap_nsrect);
      else GET_INVOCATION_RET_IF_TYPE(NSRange, ARG_NSRange, _wrap_nsrange);
      else
        @throw [NSException exceptionWithName: NSInvalidArgumentException
                            reason: [NSString stringWithFormat: @"[ocaml-objc] Unsupported return type '%s'",
                                              returnType]
                            userInfo: [NSDictionary dictionary]];
      retVal = caml_alloc(2, 0);
      Store_field(retVal, 0, retTag);
      Store_field(retVal, 1, retParam);
    }
  }
  @catch(id x) {
    caml_raise_with_arg(*(caml_named_value("NSException")), _wrap_id(x));
  }

  [pool release];

  CAMLreturn(retVal);
}

CAMLprim value
ocaml_objc_clas_of_id(value obj)
{
  CAMLparam1(obj);
  CAMLreturn( _wrap_id([_unwrap_id(obj) class]) );
}

CAMLprim value
ocaml_objc_nsstring(value str)
{
  CAMLparam1(str);
  CAMLreturn( _wrap_id([NSString stringWithUTF8String: String_val(str)]) );
}

static value
_string_value(const char *str)
{
  CAMLparam0();
  CAMLlocal1(v);

  if(str) {
    v = caml_alloc_string( strlen(str) );
    strcpy( String_val(v), str );
  }
  else {
    v = caml_alloc_string(5);
    strcpy( String_val(v), "(nil)" );
  }

  CAMLreturn(v);
}

CAMLprim value
ocaml_objc_string_of_nsstring(value obj)
{
  CAMLparam1(obj);

  CAMLreturn( _string_value([_unwrap_id(obj) UTF8String]) );
}

CAMLprim value
ocaml_objc_string_of_sel(value sel)
{
  CAMLparam1(sel);

  CAMLreturn( _string_value( sel_getName(_unwrap_sel(sel)) ) );
}
