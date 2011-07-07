/*
 * shadow.c
 *
 * Ruby extention module for using Linux shadow password.
 *
 * Copyright (C) 1998-1999 by Takaaki.Tateishi(ttate@jaist.ac.jp)
 * License: Free for any use with your own risk!
 * Modified at: <1999/8/19 06:48:18 by ttate>
 */

#include <shadow.h>
#include "ruby.h"
#include "rubyio.h"

static VALUE rb_mShadow;
static VALUE rb_mPasswd;
static VALUE rb_sPasswdEntry;
static VALUE rb_mGroup;
static VALUE rb_sGroupEntry;
static VALUE rb_eFileLock;


static VALUE
rb_shadow_setspent(VALUE self)
{
  setspent();
  return Qnil;
};


static VALUE
rb_shadow_endspent(VALUE self)
{
  endspent();
  return Qnil;
};


static VALUE
rb_shadow_sgetspent(VALUE self, VALUE str)
{
  struct spwd *entry;
  VALUE result;

  if( TYPE(str) != T_STRING )
    rb_raise(rb_eException,"argument must be a string.");

  entry = sgetspent(STR2CSTR(str));

  if( entry == NULL )
    return Qnil;

  result = rb_struct_new(rb_sPasswdEntry,
		      rb_tainted_str_new2(entry->sp_namp),
		      rb_tainted_str_new2(entry->sp_pwdp),
		      INT2FIX(entry->sp_lstchg),
		      INT2FIX(entry->sp_min),
		      INT2FIX(entry->sp_max),
		      INT2FIX(entry->sp_warn),
		      INT2FIX(entry->sp_inact),
		      INT2FIX(entry->sp_expire),
		      INT2FIX(entry->sp_flag),
		      0);
  free(entry);
  return result;
};

static VALUE
rb_shadow_fgetspent(VALUE self, VALUE file)
{
  struct spwd *entry;
  VALUE result;

  if( TYPE(file) != T_FILE )
    rb_raise(rb_eTypeError,"argument must be a File.");

  entry = fgetspent((RFILE(file)->fptr)->f);

  if( entry == NULL )
    return Qnil;

  result = rb_struct_new(rb_sPasswdEntry,
		      rb_tainted_str_new2(entry->sp_namp),
		      rb_tainted_str_new2(entry->sp_pwdp),
		      INT2FIX(entry->sp_lstchg),
		      INT2FIX(entry->sp_min),
		      INT2FIX(entry->sp_max),
		      INT2FIX(entry->sp_warn),
		      INT2FIX(entry->sp_inact),
		      INT2FIX(entry->sp_expire),
		      INT2FIX(entry->sp_flag),
		      0);
  return result;
};

static VALUE
rb_shadow_getspent(VALUE self)
{
  struct spwd *entry;
  VALUE result;

  entry = getspent();

  if( entry == NULL )
    return Qnil;

  result = rb_struct_new(rb_sPasswdEntry,
		      rb_tainted_str_new2(entry->sp_namp),
		      rb_tainted_str_new2(entry->sp_pwdp),
		      INT2FIX(entry->sp_lstchg),
		      INT2FIX(entry->sp_min),
		      INT2FIX(entry->sp_max),
		      INT2FIX(entry->sp_warn),
		      INT2FIX(entry->sp_inact),
		      INT2FIX(entry->sp_expire),
		      INT2FIX(entry->sp_flag),
		      0);
  return result;
};

static VALUE
rb_shadow_getspnam(VALUE self, VALUE name)
{
  struct spwd *entry;
  VALUE result;

  if( TYPE(name) != T_STRING )
    rb_raise(rb_eException,"argument must be a string.");

  entry = getspnam(STR2CSTR(name));

  if( entry == NULL )
    return Qnil;

  result = rb_struct_new(rb_sPasswdEntry,
		      rb_tainted_str_new2(entry->sp_namp),
		      rb_tainted_str_new2(entry->sp_pwdp),
		      INT2FIX(entry->sp_lstchg),
		      INT2FIX(entry->sp_min),
		      INT2FIX(entry->sp_max),
		      INT2FIX(entry->sp_warn),
		      INT2FIX(entry->sp_inact),
		      INT2FIX(entry->sp_expire),
		      INT2FIX(entry->sp_flag),
		      0);
  return result;
};


static VALUE
rb_shadow_putspent(VALUE self, VALUE entry, VALUE file)
{
  struct spwd centry;
  FILE* cfile;
  VALUE val[9];
  int i;
  int result;

  for(i=0; i<=8; i++)
    val[i] = RSTRUCT(entry)->ptr[i];
  cfile = RFILE(file)->fptr->f;

  centry.sp_namp = STR2CSTR(val[0]);
  centry.sp_pwdp = STR2CSTR(val[1]);
  centry.sp_lstchg = FIX2INT(val[2]);
  centry.sp_min = FIX2INT(val[3]);
  centry.sp_max = FIX2INT(val[4]);
  centry.sp_warn = FIX2INT(val[5]);
  centry.sp_inact = FIX2INT(val[6]);
  centry.sp_expire = FIX2INT(val[7]);
  centry.sp_flag = FIX2INT(val[8]);

  result = putspent(&centry,cfile);

  if( result == -1 )
    rb_raise(rb_eStandardError,"can't change password");

  return Qtrue;
};


static VALUE
rb_shadow_lckpwdf(VALUE self)
{
  int result;
  result = lckpwdf();
  if( result == -1 )
    rb_raise(rb_eFileLock,"password file was locked");
  else
    return Qtrue;
};

static int in_lock;

static VALUE
rb_shadow_lock(VALUE self)
{
  int result;

  if( rb_iterator_p() ){
    result = lckpwdf();
    if( result == -1 ){
      rb_raise(rb_eFileLock,"password file was locked");
    }
    else{
      in_lock++;
      rb_yield(Qnil);
      in_lock--;
      ulckpwdf();
    };
    return Qtrue;
  }
  else{
    return rb_shadow_lckpwdf(self);
  };
};


static VALUE
rb_shadow_ulckpwdf(VALUE self)
{
  if( in_lock ){
    rb_raise(rb_eFileLock,"you call unlock method in lock iterator.");
  };
  ulckpwdf();
  return Qtrue;
};

static VALUE
rb_shadow_unlock(VALUE self)
{
  return rb_shadow_ulckpwdf(self);
};

static VALUE
rb_shadow_lock_p(VALUE self)
{
  int result;

  result = lckpwdf();
  if( result == -1 ){
    return Qtrue;
  }
  else{
    ulckpwdf();
    return Qfalse;
  };
};


void
Init_shadow()
{
  rb_sPasswdEntry = rb_struct_define("PasswdEntry",
				     "sp_namp","sp_pwdp","sp_lstchg",
				     "sp_min","sp_max","sp_warn",
				     "sp_inact","sp_expire","sp_flag",0);
  rb_sGroupEntry = rb_struct_define("GroupEntry",
				    "sg_name","sg_passwd",
				    "sg_adm","sg_mem",0);

  rb_mShadow = rb_define_module("Shadow");
  rb_eFileLock = rb_define_class_under(rb_mShadow,"FileLock",rb_eException);
  rb_mPasswd = rb_define_module_under(rb_mShadow,"Passwd");
  rb_define_const(rb_mPasswd,"Entry",rb_sPasswdEntry);
  rb_mGroup = rb_define_module_under(rb_mShadow,"Group");
  rb_define_const(rb_mGroup,"Entry",rb_sGroupEntry);

  rb_define_module_function(rb_mPasswd,"setspent",rb_shadow_setspent,0);
  rb_define_module_function(rb_mPasswd,"endspent",rb_shadow_endspent,0);
  rb_define_module_function(rb_mPasswd,"sgetspent",rb_shadow_sgetspent,1);
  rb_define_module_function(rb_mPasswd,"fgetspent",rb_shadow_fgetspent,1);
  rb_define_module_function(rb_mPasswd,"getspent",rb_shadow_getspent,0);
  rb_define_module_function(rb_mPasswd,"getspnam",rb_shadow_getspnam,1);
  rb_define_module_function(rb_mPasswd,"putspent",rb_shadow_putspent,2);
  rb_define_module_function(rb_mPasswd,"lckpwdf",rb_shadow_lckpwdf,0);
  rb_define_module_function(rb_mPasswd,"lock",rb_shadow_lock,0);
  rb_define_module_function(rb_mPasswd,"ulckpwdf",rb_shadow_ulckpwdf,0);
  rb_define_module_function(rb_mPasswd,"unlock",rb_shadow_unlock,0);
  rb_define_module_function(rb_mPasswd,"lock?",rb_shadow_lock_p,0);
};
