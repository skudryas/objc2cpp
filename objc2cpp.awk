#!/usr/bin/awk -f
BEGIN {
    if (ARGV[1]~".*\\."OLDOBJCHEXT"$") {
        print "#pragma once"
    }
    IN_CLASS=0
    IN_DECL_BODY=0
    IN_IMPLEMENTATION=0
    IN_FUNCSIGN=0
    FUNCSIGN_BODY=""
    IMPLEMENTATION_NAME=""
    LAST_TABSTOP="        "
    FPAT="[0-9a-zA-Z@_<>,]+"
}

# TODO
function move_oneline_comments(str) {
    if (match(str, /(\".*\")*\/\//, ret)!=0) {
        print substr(str, RSTART+RLENGTH-2)
        return substr(str, 0, RSTART+RLENGTH-2)
    } else {
        return str
    }
}

#TODO
function move_multiline_comments(str) {
    if (match(str, /(\".*\")*\/\//, ret)!=0) {
        print substr(str, RSTART+RLENGTH-2)
        return substr(str, 0, RSTART+RLENGTH-2)
    } else {
        return str
    }
}


function extract_type(funcsign_body, ret) {
    if (match(funcsign_body, /\([0-9a-zA-Z_\* ]+\)/)!=0) {
        TYPE=substr(funcsign_body, RSTART, RLENGTH)
        STOP_POS=RSTART+RLENGTH
        match(TYPE, /[0-9a-zA-Z_\* ]+/)
        TYPE=substr(TYPE, RSTART, RLENGTH)
        funcsign_body=substr(funcsign_body, STOP_POS)
        ret[1]=funcsign_body
        return TYPE
    } else {
        ret[1]=""
        return ""
    }
}

function extract_somename(funcsign_body, ret) {
    if (match(funcsign_body, /[0-9a-zA-Z_]+/)!=0) {
        NAME=substr(funcsign_body, RSTART, RLENGTH)
        funcsign_body=substr(funcsign_body, RSTART+RLENGTH)
        ret[1]=funcsign_body
        return NAME
    } else {
        ret[1]=""
        return ""
    }
}

function func_sign_rewrite(funcsign_body, class_name) {
    gsub(function_body, "[ \n\t]+", " ")
    STATIC=""
    if (funcsign_body~/^\+/) {
        STATIC="static "
    }
    CLASS_NAME=""
    if (length(class_name)!=0) {
        CLASS_NAME=class_name"::"
    }
    RET_TYPE="void"
    if (match(funcsign_body, /^[\+-][ ]*\([0-9a-zA-Z_\* ]+\)/)!=0) {
        RET_TYPE=extract_type(funcsign_body, ret)
        funcsign_body=ret[1]
    }

    FUNC_NAME=""
    DO_SCAN=1
    PARAMS_INDEX=1
    FUNC_NAME_DELIM=""
    while (DO_SCAN==1) {
        FUNC_NAME_PART=extract_somename(funcsign_body, ret)
        funcsign_body=ret[1]
        if (length(FUNC_NAME_PART)!=0) {
            FUNC_NAME=FUNC_NAME""FUNC_NAME_DELIM""FUNC_NAME_PART
            if (funcsign_body~/^:/) {
                ARG_TYPE=extract_type(funcsign_body, ret)
                funcsign_body=ret[1]
                ARG_NAME=extract_somename(funcsign_body, ret)
                funcsign_body=ret[1]
                if (length(ARG_TYPE)!=0 && length(ARG_NAME)!=0) {
                    PARAMS[PARAMS_INDEX]=ARG_TYPE" "ARG_NAME
                    PARAMS_INDEX++
                } else {
                    DO_SCAN=0
                }
            } else {
                DO_SCAN=0
            }
        } else {
            DO_SCAN=0
        }
        FUNC_NAME_DELIM="_"
    }
    RESULT_SIGN=STATIC""RET_TYPE" "CLASS_NAME""FUNC_NAME"("
    PARAMS_DELIM=""
    for (I in PARAMS) {
        RESULT_SIGN=RESULT_SIGN""PARAMS_DELIM""PARAMS[I]
        PARAMS_DELIM=", "
        delete PARAMS[I]
    }
    RESULT_SIGN=RESULT_SIGN")"
    if (length(class_name)==0) {
        RESULT_SIGN=RESULT_SIGN";"
    }

    return RESULT_SIGN
}

{
    DO_PRINT=1

    gsub("^#import", "#include", $0)
    gsub("^@public", "public:", $0)
    gsub("^@private", "private:", $0)

    if ($0~/^@(interface|protocol)/) {
        IN_CLASS=1
        DO_PRINT=0
        if ($0!~/.*([:,])+([ \t])*$/) {
            IN_DECL_BODY=1
            gsub("{", "", $0)
        }
        if ($0~/^@(interface|protocol)(.+):(.+)/) {
            CLASS_NAME=$2
            OFS="" # A little hack
            $1=$2=""
            OFS=" "
            print "class "CLASS_NAME": public "$0
        } else {
            print "class "$2
        }
        if (IN_DECL_BODY==1) {
            print "{"
        }
    }

    if ($0~/^@implementation/) {
        IN_IMPLEMENTATION=1
        IMPLEMENTATION_NAME=$2
        DO_PRINT=0
    }

    if ($0~/^@end/) {
        if (IN_CLASS==1) {
            print "};"
        }
        IN_CLASS=0
        IN_IMPLEMENTATION=0
        IN_DECL_BODY=0
        IMPLEMENTATION_NAME=""
        DO_PRINT=0
    }

    if (IN_CLASS==1 || IN_IMPLEMENTATION==1) {
        if (IN_CLASS==1 && DO_PRINT==1 && IN_DECL_BODY==0) {
            if ($0!~/.*([:,])+([ \t])*/) {
                IN_DECL_BODY=1
                gsub("{", "", $0)
                print $0
                print "{"
                DO_PRINT=0
            }
        }

        if (IN_CLASS==1 && $0~/^[{}]/) {
            DO_PRINT=0
        }

        if (DO_PRINT==1) {
            if ($0~/^([+-])/) {
                IN_FUNCSIGN=1
                DO_PRINT=0
                if ($0~/[\{|;]/) {
                    CUT_TILL=match($0, /[\{|;]/)
                    FUNCSIGN_BODY=FUNCSIGN_BODY""substr($0, 0, CUT_TILL)
                    IN_FUNCSIGN=0
                    CUR_TABSTOP=""
                    if (IN_CLASS) {
                        CUR_TABSTOP=LAST_TABSTOP
                    }
                    print CUR_TABSTOP""func_sign_rewrite(FUNCSIGN_BODY, IMPLEMENTATION_NAME)
                    if (IN_IMPLEMENTATION==1) {
                        print "{"
                    }
                    FUNCSIGN_BODY=""
                } else {
                    FUNCSIGN_BODY=$0
                }
            } else if (IN_FUNCSIGN) {
                DO_PRINT=0
                if ($0~/[\{|;]/) {
                    CUT_TILL=match($0, /[\{|;]/)
                    FUNCSIGN_BODY=FUNCSIGN_BODY""substr($0, 0, CUT_TILL)
                    IN_FUNCSIGN=0
                    CUR_TABSTOP=""
                    if (IN_CLASS) {
                        CUR_TABSTOP=LAST_TABSTOP
                    }
                    print CUR_TABSTOP""func_sign_rewrite(FUNCSIGN_BODY, IMPLEMENTATION_NAME)
                    if (IN_IMPLEMENTATION==1) {
                        print "{"
                    }
                    FUNCSIGN_BODY=""
                } else {
                    FUNCSIGN_BODY=FUNCSIGN_BODY""$0
                }
            } else if (length(LAST_TABSTOP)==0) {
                TABSTOP_LEN=match($0, /[^ ]/)
                LAST_TABSTOP=substr($0, 0, TABSTOP_LEN)
            }
        }
    }

    if (DO_PRINT==1) {
        print $0
    }
}

END {
}
