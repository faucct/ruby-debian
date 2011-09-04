#include "ruby.h"

#include <apt-pkg/debversion.h>
using namespace std;

extern "C" {

    static VALUE cmp_version(VALUE self, VALUE anObject, VALUE cmpType, VALUE anOtherObject) {
        int res = debVS.CmpVersion(StringValuePtr(anObject),StringValuePtr(anOtherObject));
        char * cmp = StringValuePtr(cmpType);
        if(!strcmp(cmp, "lt") || !strcmp(cmp, "<") || !strcmp(cmp, "<<")) {
            if(res < 0)
                return Qtrue;
        } else if(!strcmp(cmp, "le") || !strcmp(cmp, "<=")) {
            if(res <= 0)
                return Qtrue;
        } else if(!strcmp(cmp, "eq") || !strcmp(cmp, "=")) {
            if(res == 0)
                return Qtrue;
        } else if(!strcmp(cmp, "ne")) {
            if(res != 0)
                return Qtrue;
        } else if(!strcmp(cmp, "ge") || !strcmp(cmp, ">=")) {
            if(res >= 0)
                return Qtrue;
        } else if(!strcmp(cmp, "gt") || !strcmp(cmp, ">>") || !strcmp(cmp, ">")) {
            if (res > 0)
                return Qtrue;
        } else {
            rb_raise(rb_eArgError, "cmpType must be one of lt, le, eq, ne, ge, gt, <, <<, <=, =, >=, >>, or >");
        }
        return Qfalse;
    }

    void Init_debian_version() {
        VALUE rb_mDebian = rb_define_module("Debian");
        VALUE rb_mDebianVersion = rb_define_module_under(rb_mDebian, "Version");
        rb_define_singleton_method(rb_mDebianVersion, "cmp_version", (VALUE (*)(...))cmp_version, 3);
    }

};


